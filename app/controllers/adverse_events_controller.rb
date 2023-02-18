class AdverseEventsController < ApplicationController
  before_action :authorize
  before_action :patient, only: [:new, :edit, :create, :update, :show]
  before_action :all_user, only: [:new, :edit, :show, :create]
  before_action :adverse_event, only: [:edit, :show, :update, :create]
  before_action :set_adverse_events_options
  before_action :set_specialities, only: [:new, :edit, :show, :create]

  def new
    @adverse_event = AdverseEvent.new
    @current_facility_speciliaties = Specialty.where(:id.in => current_facility.specialty_ids).map(&:name)
  end

  def create
    @adverse_event = AdverseEvent.new(adverse_event_params)
    if @adverse_event.save
      render 'show'
      AdverseEventJobs::SendMailAdverseEventJob.perform_now(@adverse_event.id.to_s, @current_user)
    else
      render 'new'
    end
  end

  def edit; end

  def show; end

  def update
    @adverse_event.update!(adverse_event_params)

    render 'show'

    AdverseEventJobs::SendMailAdverseEventJob.perform_now(@adverse_event.id.to_s, @current_user)
  end

  def outcome_report
    respond_to do |format|
      format.js { render 'adverse_events/outcome_report.js.erb', layout: false }
    end
  end

  private

  def patient
    @patient = Patient.find_by(id: params[:patient_id] || params[:adverse_event][:patient_id])
  end

  def all_user
    @all_user = User.where(facility_ids: current_facility.id, is_active: true).pluck(:fullname, :id)
  end

  def adverse_event
    @adverse_event = AdverseEvent.find_by(id: params[:id])
  end

  def set_specialities
    @current_facility_speciliaties = Specialty.where(:id.in => current_facility.specialty_ids).map(&:name)
    @sub_specialities = ['General']
    @sub_specialities += @opthomology_sub_specialitis if current_facility.specialty_ids.include?('309988001') #for Opthomology
    @user_roles = @current_facility_speciliaties.map{ |specialty| "General #{specialty.downcase}".titleize }
    @sub_specialities += @user_roles
  end

  def set_adverse_events_options
    data = YAML.load(File.read("config/global/adverse_events.yml"))
    @opthomology_sub_specialitis = data['default']['opthomology_sub_specialitis']
    @critical_events = data['default']['critical_options'].with_indifferent_access
    @major_events = data['default']['major_options'].with_indifferent_access
    @minor_events = data['default']['minor_options'].with_indifferent_access
  end

  def adverse_event_params
    params.require(:adverse_event).permit(
      :organisation_id, :facility_id, :user_id, :patient_id, :concerned_person, :type, :reported_by, :reported_date,
      :reported_time, :occured_date, :occured_time, :occured_date_time, :patient_name, :concerned_doctor,
      :concerned_doctor_comment, :patient_exact_age, :patient_age, :patient_gender, :method_management,
      :final_outcome, :concerned_person_name, :patient_mrn, :patient_mobilenumber, :event_description, :sub_speciality,
      #critical
      :globe_perforation, :globe_perforation_comment, :expulsive_hemorrhage,:expulsive_hemorrhage_comment,
      :death_inside_hospital_premises, :death_inside_hospital_premises_comment,
      :death_on_table_examination_during_surgeries, :death_on_table_examination_during_surgeries_comment,
      :hospital_staff_or_doctor_testing_COVID_positive, :hospital_staff_or_doctor_testing_COVID_positive_comment,
      :mlc_notifications_hospital, :mlc_notifications_hospital_comment, :end_ophthlmitis, :end_ophthlmitis_comment,
      :shifting_to_emergency, :shifting_to_emergency_comment, :wrong_eye_patient_procedure,
      :wrong_eye_patient_procedure_comment, :customer_complaint_public, :customer_complaint_public_comment,
      :anaphylaxis_drug_allergy, :anaphylaxis_drug_allergy_comment, :doctor_security_issues,
      :doctor_security_issues_comment, :patient_harassment_issues, :patient_harassment_issues_comment, :code_red,
      :code_red_comment, :code_pink, :code_pink_comment, :critical_others, :critical_others_comment,
      :expulsive_hemorrhage, :expulsive_hemorrhage_comment, :endophthalmitis_post_ppv, :endophthalmitis_post_ppv_comment,
      :hemorrhage_post_surgery, :hemorrhage_post_surgery_comment, :pl_after_procedure, :pl_after_procedure_comment,
      :pl_negative_vision, :pl_negative_vision_comment, :expulsive_suprachoroidal_hemorrhage, :expulsive_suprachoroidal_hemorrhage_comment, 
      :beld_surgery_endophthalmitis, :beld_surgery_endophthalmitis_comment,:endophthalmitis, :endophthalmitis_comment,
      :critical_suprachoroidal_hemorrhage, :critical_suprachoroidal_hemorrhage_comment,:general_ophthalmology_endophthalmitis,
      :general_ophthalmology_endophthalmitis_comment,:retina_endophthalmitis,:retina_endophthalmitis_comment,
      :glaucoma_endophthalmitis,:glaucoma_endophthalmitis_comment,:cornea_and_refractive_endophthalmitis,
      :cornea_and_refractive_endophthalmitis_comment,:cataract_endophthalmitis,:cataract_endophthalmitis_comment,
      :retina_expulsive_suprachoroidal_hemorrhage,:retina_expulsive_suprachoroidal_hemorrhage_comment,
      :glaucoma_expulsive_suprachoroidal_hemorrhage,:glaucoma_expulsive_suprachoroidal_hemorrhage_comment,
      :cataract_expulsive_suprachoroidal_hemorrhage,:cataract_expulsive_suprachoroidal_hemorrhage_comment,
      :retina_globe_perforation,:retina_globe_perforation_comment,:glaucoma_globe_perforation,:glaucoma_globe_perforation_comment,
      :cornea_and_refractive_globe_perforation,:cornea_and_refractive_globe_perforation_comment,:cataract_globe_perforation,
      :cataract_globe_perforation_comment,:retina_pl_negative_vision,:retina_pl_negative_vision_comment,:glaucoma_pl_negative_vision,
      :glaucoma_pl_negative_vision_comment,:cornea_and_refractive_pl_negative_vision,:cornea_and_refractive_pl_negative_vision_comment,
      :cataract_pl_negative_vision,:cataract_pl_negative_vision_comment, :cornea_and_refractive_pl_after_procedure, :cornea_and_refractive_pl_after_procedure_comment,
      :cornea_and_refractive_expulsive_suprachoroidal_hemorrhage, :cornea_and_refractive_expulsive_suprachoroidal_hemorrhage_comment,
      #major
      :patient_distress, :patient_distress_comment, :patient_distress_one, :postop_inflammation,
      :postop_inflammation_comment, :postop_inflammation_one, :aqueous_meets_vitreous, :aqueous_meets_vitreous_comment,
      :aqueous_meets_vitreous_one, :surgical_complications_repeat_surgeries,
      :surgical_complications_repeat_surgeries_comment, :surgical_complications_repeat_surgeries_one,
      :major_cornea, :major_cataract, :major_refractive, :major_retina, :major_squint, :major_glaucoma,
      :wrong_iol_power, :wrong_iol_power_comment, :wrong_iol_power_one, :culture_postivity_ot_electrical,
      :culture_postivity_ot_electrical_comment, :abandoning_surgery, :abandoning_surgery_comment,
      :customer_complaint_staff, :customer_complaint_staff_comment, :pbk_surgery, :pbk_surgery_comment,
      :rescheduling_cancelling_surgery, :rescheduling_cancelling_surgery_comment, :rescheduling_cancelling_surgery_one,
      :optical_related, :optical_related_comment, :optical_related_one, :stoppage_of_OT, :stoppage_of_OT_comment,
      :customer_complaint_department, :customer_complaint_department_comment, :wrong_drugs, :wrong_drugs_comment, :consent_not_taken,
      :consent_not_taken_comment, :major_others, :major_others_comment, :ga_related_complications,
      :ga_related_complications_comment, :code_blue, :code_blue_comment, :iol_later_rd_surgery,
      :iol_later_rd_surgery_comment, :major_intra_op_complication, :major_intra_op_complication_comment,
      :previously_attached_retina, :previously_attached_retina_comment,:resurgery_sclerotomy_closure, 
      :resurgery_sclerotomy_closure_comment,:post_operative_bcva, :post_operative_bcva_comment, :secondary_glaucoma, 
      :secondary_glaucoma_comment, :infection_after_procedure, :infection_after_procedure_comment, 
      :maglignant_glaucoma_post_surgery, :maglignant_glaucoma_post_surgery_comment, :persistent_choroidal_effusion, 
      :persistent_choroidal_effusion_comment, :failed_bleb, :failed_bleb_comment, :resurgery_bleb_version, 
      :resurgery_bleb_version_comment, :encapsulated_bleb, :encapsulated_bleb_comment, :corneal_endothelial, 
      :corneal_endothelial_comment, :persistent_ptosis, :persistent_ptosis_comment, :retrobulbar_hemorrhage, 
      :retrobulbar_hemorrhage_comment, :diplopia_or_strabismus, :diplopia_or_strabismus_comment, :severe_hyphema, 
      :severe_hyphema_comment, :lasik, :lasik_comment, :opaque_bubble_layer, :opaque_bubble_layer_comment, :macrostriae_dlk, 
      :macrostriae_dlk_comment, :infection, :infection_comment, :graft_failure, :graft_failure_comment, :lenticule_detachment, 
      :lenticule_detachment_comment, :corneal_haze, :corneal_haze_comment, :epithelial_ingrowth, :epithelial_ingrowth_comment, 
      :cataract_icl, :cataract_icl_comment, :cornea_melt, :cornea_melt_comment,
      #minor
      :post_operative_CME_within_3_months, :post_operative_CME_within_3_months_comment, :bio_medical_instrument,
      :bio_medical_instrument_comment, :minor_drug_allergy, :minor_drug_allergy_comment, :simple_re_surgeries,
      :simple_re_surgeries_comment, :conjunctivitis_in_COVID_times, :conjunctivitis_in_COVID_times_comment,
      :mis_diagnosis_management, :mis_diagnosis_management_comment, :minor_others, :minor_others_comment,
      :minor_suprachoroidal_hemorrhage, :minor_suprachoroidal_hemorrhage_comment, :bleb_surgery_related_endophthalmitis, 
      :bleb_surgery_related_endophthalmitis_comment, :wound_suturing_reformation, :wound_suturing_reformation_comment,
      :minor_post_operative, :minor_post_operative_comment, :minor_general_ophth_iris_prolapse, :minor_general_ophth_iris_prolapse_comment,
      :minor_cornea_and_refractive_iris_prolapse, :minor_cornea_and_refractive_iris_prolapse_comment,
      :minor_cataract_iris_prolapse, :minor_cataract_iris_prolapse_comment
    )
  end
end
