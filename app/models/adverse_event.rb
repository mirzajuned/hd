class AdverseEvent
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :patient_name, type: String
  field :patient_gender, type: String
  field :patient_exact_age, type: String
  field :patient_age, type: Integer
  field :patient_mrn, type: String
  field :patient_identifier_id, type: String
  field :patient_mobilenumber, type: String

  field :type, type: String
  field :reported_by, type: String
  field :reported_date, type: Date, default: Date.current
  field :reported_time, type: Time, default: Time.current
  field :occured_date, type: Date #, default: Date.current
  field :occured_time, type: Time #, default: Time.current
  field :occured_date_time, type: DateTime
  field :concerned_person, type: BSON::ObjectId
  field :concerned_person_name, type: String
  field :method_management, type: String
  field :final_outcome, type: String
  field :event_description, type: String
  field :sub_speciality, type: String

  # critical fields
  field :globe_perforation, type: Boolean, default: false
  field :globe_perforation_comment, type: String
  field :expulsive_hemorrhage, type: Boolean, default: false
  field :expulsive_hemorrhage_comment, type: String
  field :death_inside_hospital_premises, type: Boolean, default: false
  field :death_inside_hospital_premises_comment, type: String
  field :death_on_table_examination_during_surgeries, type: Boolean, default: false
  field :death_on_table_examination_during_surgeries_comment, type: String
  field :hospital_staff_or_doctor_testing_COVID_positive, type: Boolean, default: false
  field :hospital_staff_or_doctor_testing_COVID_positive_comment, type: String
  field :mlc_notifications_hospital, type: Boolean, default: false
  field :mlc_notifications_hospital_comment, type: String
  field :end_ophthlmitis, type: Boolean, default: false
  field :end_ophthlmitis_comment, type: String
  field :shifting_to_emergency, type: Boolean, default: false
  field :shifting_to_emergency_comment, type: String
  field :wrong_eye_patient_procedure, type: Boolean, default: false
  field :wrong_eye_patient_procedure_comment, type: String
  field :customer_complaint_public, type: Boolean, default: false
  field :customer_complaint_public_comment, type: String
  field :anaphylaxis_drug_allergy, type: Boolean, default: false
  field :anaphylaxis_drug_allergy_comment, type: String
  field :doctor_security_issues, type: Boolean, default: false
  field :doctor_security_issues_comment, type: String
  field :patient_harassment_issues, type: Boolean, default: false
  field :patient_harassment_issues_comment, type: String
  field :code_red, type: Boolean, default: false
  field :code_red_comment, type: String
  field :code_pink, type: Boolean, default: false
  field :code_pink_comment, type: String
  field :critical_others, type: Boolean, default: false
  field :critical_others_comment, type: String
  field :critical_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :critical_suprachoroidal_hemorrhage_comment, type: String
  field :expulsive_hemorrhage, type: Boolean, default: false
  field :expulsive_hemorrhage_comment, type: String
  field :general_ophthalmology_endophthalmitis, type: Boolean, default: false
  field :general_ophthalmology_endophthalmitis_comment, type: String
  field :retina_endophthalmitis, type: Boolean, default: false
  field :retina_endophthalmitis_comment, type: String
  field :glaucoma_endophthalmitis, type: Boolean, default: false
  field :glaucoma_endophthalmitis_comment, type: String
  field :cornea_and_refractive_endophthalmitis, type: Boolean, default: false
  field :cornea_and_refractive_endophthalmitis_comment, type: String
  field :cataract_endophthalmitis, type: Boolean, default: false
  field :cataract_endophthalmitis_comment, type: String
  field :retina_expulsive_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :retina_expulsive_suprachoroidal_hemorrhage_comment, type: String
  field :glaucoma_expulsive_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :glaucoma_expulsive_suprachoroidal_hemorrhage_comment, type: String
  field :cataract_expulsive_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :cataract_expulsive_suprachoroidal_hemorrhage_comment, type: String
  field :retina_globe_perforation, type: Boolean, default: false
  field :retina_globe_perforation_comment, type: String
  field :glaucoma_globe_perforation, type: Boolean, default: false
  field :glaucoma_globe_perforation_comment, type: String
  field :cornea_and_refractive_globe_perforation, type: Boolean, default: false
  field :cornea_and_refractive_globe_perforation_comment, type: String
  field :cataract_globe_perforation, type: Boolean, default: false
  field :cataract_globe_perforation_comment, type: String
  field :retina_pl_negative_vision, type: Boolean, default: false
  field :retina_pl_negative_vision_comment, type: String
  field :glaucoma_pl_negative_vision, type: Boolean, default: false
  field :glaucoma_pl_negative_vision_comment, type: String
  field :cornea_and_refractive_pl_negative_vision, type: Boolean, default: false
  field :cornea_and_refractive_pl_negative_vision_comment, type: String
  field :cataract_pl_negative_vision, type: Boolean, default: false
  field :cataract_pl_negative_vision_comment, type: String
  field :cornea_and_refractive_pl_after_procedure, type: Boolean, default: false
  field :cornea_and_refractive_pl_after_procedure_comment, type: String
  field :cornea_and_refractive_expulsive_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :cornea_and_refractive_expulsive_suprachoroidal_hemorrhage_comment, type: String

  field :endophthalmitis_post_ppv, type: Boolean, default: false
  field :endophthalmitis_post_ppv_comment, type: String
  field :hemorrhage_post_surgery, type: Boolean, default: false
  field :hemorrhage_post_surgery_comment, type: String
  field :pl_after_procedure, type: Boolean, default: false
  field :pl_after_procedure_comment, type: String
  field :pl_negative_vision, type: Boolean, default: false
  field :pl_negative_vision_comment, type: String
  field :expulsive_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :expulsive_suprachoroidal_hemorrhage_comment, type: String
  field :beld_surgery_endophthalmitis, type: Boolean, default: false
  field :beld_surgery_endophthalmitis_comment, type: String
  field :endophthalmitis, type: Boolean, default: false
  field :endophthalmitis_comment, type: String


  # major fields
  field :patient_distress, type: Boolean, default: false
  field :patient_distress_comment, type: String
  field :patient_distress_one, type: String
  field :postop_inflammation, type: Boolean, default: false
  field :postop_inflammation_comment, type: String
  field :postop_inflammation_one, type: String
  field :aqueous_meets_vitreous, type: Boolean, default: false
  field :aqueous_meets_vitreous_comment, type: String
  field :aqueous_meets_vitreous_one, type: String
  field :surgical_complications_repeat_surgeries, type: Boolean, default: false
  field :surgical_complications_repeat_surgeries_comment, type: String
  field :surgical_complications_repeat_surgeries_one, type: String
  field :major_cornea, type: String
  field :major_cataract, type: String
  field :major_refractive, type: String
  field :major_retina, type: String
  field :major_squint, type: String
  field :major_glaucoma, type: String
  field :wrong_iol_power, type: Boolean, default: false
  field :wrong_iol_power_comment, type: String
  field :wrong_iol_power_one, type: String
  field :culture_postivity_ot_electrical, type: Boolean, default: false
  field :culture_postivity_ot_electrical_comment, type: String
  field :abandoning_surgery, type: Boolean, default: false
  field :abandoning_surgery_comment, type: String
  field :customer_complaint_staff, type: Boolean, default: false
  field :customer_complaint_staff_comment, type: String
  field :pbk_surgery, type: Boolean, default: false
  field :pbk_surgery_comment, type: String
  field :rescheduling_cancelling_surgery, type: Boolean, default: false
  field :rescheduling_cancelling_surgery_comment, type: String
  field :rescheduling_cancelling_surgery_one, type: String
  field :optical_related, type: Boolean, default: false
  field :optical_related_comment, type: String
  field :optical_related_one, type: String
  field :stoppage_of_OT, type: Boolean, default: false
  field :stoppage_of_OT_comment, type: String
  field :customer_complaint_department, type: Boolean, default: false
  field :customer_complaint_department_comment, type: String
  field :wrong_drugs, type: Boolean, default: false
  field :wrong_drugs_comment, type: String
  field :consent_not_taken, type: Boolean, default: false
  field :consent_not_taken_comment, type: String
  field :major_others, type: Boolean, default: false
  field :major_others_comment, type: String
  field :ga_related_complications, type: Boolean, default: false
  field :ga_related_complications_comment, type: String
  field :code_blue, type: Boolean, default: false
  field :code_blue_comment, type: String
  field :iol_later_rd_surgery, type: Boolean, default: false
  field :iol_later_rd_surgery_comment, type: String
  field :major_intra_op_complication, type: Boolean, default: false
  field :major_intra_op_complication_comment, type: String
  field :previously_attached_retina, type: Boolean, default: false
  field :previously_attached_retina_comment
  field :resurgery_sclerotomy_closure, type: Boolean, default: false
  field :resurgery_sclerotomy_closure_comment
  field :post_operative_bcva, type: Boolean, default: false
  field :post_operative_bcva_comment, type: String
  field :secondary_glaucoma, type: Boolean, default: false
  field :secondary_glaucoma_comment, type: String
  field :infection_after_procedure, type: Boolean, default: false
  field :infection_after_procedure_comment, type: String
  field :maglignant_glaucoma_post_surgery, type: Boolean, default: false
  field :maglignant_glaucoma_post_surgery_comment, type: String
  field :persistent_choroidal_effusion, type: Boolean, default: false
  field :persistent_choroidal_effusion_comment, type: String
  field :failed_bleb, type: Boolean, default: false
  field :failed_bleb_comment, type: String
  field :resurgery_bleb_version, type: Boolean, default: false
  field :resurgery_bleb_version_comment, type: String
  field :encapsulated_bleb, type: Boolean, default: false
  field :encapsulated_bleb_comment, type: String
  field :corneal_endothelial, type: Boolean, default: false
  field :corneal_endothelial_comment, type: String
  field :persistent_ptosis, type: Boolean, default: false
  field :persistent_ptosis_comment, type: String
  field :retrobulbar_hemorrhage, type: Boolean, default: false
  field :retrobulbar_hemorrhage_comment, type: String
  field :diplopia_or_strabismus, type: Boolean, default: false
  field :diplopia_or_strabismus_comment, type: String
  field :severe_hyphema, type: Boolean, default: false
  field :severe_hyphema_comment, type: String
  field :lasik, type: Boolean, default: false
  field :lasik_comment, type: String
  field :opaque_bubble_layer, type: Boolean, default: false
  field :opaque_bubble_layer_comment, type: String
  field :macrostriae_dlk, type: Boolean, default: false
  field :macrostriae_dlk_comment, type: String
  field :infection, type: Boolean, default: false
  field :infection_comment, type: String
  field :graft_failure, type: Boolean, default: false
  field :graft_failure_comment, type: String
  field :lenticule_detachment, type: Boolean, default: false
  field :lenticule_detachment_comment, type: String
  field :corneal_haze, type: Boolean, default: false
  field :corneal_haze_comment, type: String
  field :epithelial_ingrowth, type: Boolean, default: false
  field :epithelial_ingrowth_comment, type: String
  field :cataract_icl, type: Boolean, default: false
  field :cataract_icl_comment, type: String
  field :cornea_melt, type: Boolean, default: false
  field :cornea_melt_comment, type: String

  # minor fields
  field :post_operative_CME_within_3_months, type: Boolean, default: false
  field :post_operative_CME_within_3_months_comment, type: String
  field :bio_medical_instrument, type: Boolean, default: false
  field :bio_medical_instrument_comment, type: String
  field :minor_drug_allergy, type: Boolean, default: false
  field :minor_drug_allergy_comment, type: String
  field :simple_re_surgeries, type: Boolean, default: false
  field :simple_re_surgeries_comment, type: String
  field :conjunctivitis_in_COVID_times, type: Boolean, default: false
  field :conjunctivitis_in_COVID_times_comment, type: String
  field :mis_diagnosis_management, type: Boolean, default: false
  field :mis_diagnosis_management_comment, type: String
  field :minor_others, type: Boolean, default: false
  field :minor_others_comment, type: String
  field :minor_suprachoroidal_hemorrhage, type: Boolean, default: false
  field :minor_suprachoroidal_hemorrhage_comment, type: String
  field :bleb_surgery_related_endophthalmitis, type: Boolean, default: false
  field :bleb_surgery_related_endophthalmitis_comment, type: String
  field :wound_suturing_reformation, type: Boolean, default: false
  field :wound_suturing_reformation_comment, type: String
  field :minor_post_operative, type: Boolean, default: false
  field :minor_post_operative_comment, type: String
  field :minor_general_ophth_iris_prolapse, type: Boolean, default: false
  field :minor_general_ophth_iris_prolapse_comment, type: String
  field :minor_cornea_and_refractive_iris_prolapse, type: Boolean, default: false
  field :minor_cornea_and_refractive_iris_prolapse_comment, type: String
  field :minor_cataract_iris_prolapse, type: Boolean, default: false
  field :minor_cataract_iris_prolapse_comment, type: String

  validates :sub_speciality, presence: { message: 'Sub Speciality cannot be blank' }
  validates :type, presence: { message: 'Select any type critical/major/minor' }

end