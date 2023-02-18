class Inpatient::IpdRecord::AdmissionNotesController < ApplicationController
  before_action :authorize
  before_action :admission_note_form_params, only: [:new, :edit]
  before_action :find_ipdrecord_for_read, only: [:new, :edit]
  before_action :find_ipdrecord_for_write, only: [:create, :update]
  before_action :admission_note, only: [:edit, :update]

  def new
    @admission_note = @ipdrecord.build_admission_note
    respond_to do |format|
      format.js { render "inpatient/ipd_record/admission_note/form" }
    end
  end

  def create
    @admission_note = @ipdrecord.build_admission_note(admission_note_params)
    if @admission_note.save
      respond_to do |format|
        format.js { render "inpatient/ipd_record/admission_note/close" }
      end
      Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "ADMITTED", admission_id: @admission_note.admission_id, user_id: current_user.id, user_name: current_user.fullname })
    end
  end

  def edit
    respond_to do |format|
      format.js { render "inpatient/ipd_record/admission_note/form" }
    end
  end

  def update
    if @admission_note.update_attributes(admission_note_params)
      respond_to do |format|
        format.js { render "inpatient/ipd_record/admission_note/close" }
      end
      Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "ADMITTED", admission_id: @admission_note.admission_id, user_id: current_user.id, user_name: current_user.fullname })
    end
  end

  private

  def admission_note_form_params
    current_user = current_user
    @current_facility = current_facility
    @ward_count = Ward.where(facility_id: @current_facility.id).count
    @admission = Admission.find_by(id: params[:admission_id])
    if @ward_count < 0 || @admission.daycare
      @bed_details = "Daycare"
    else
      ward, room, bed = @admission.set_bed_details
      @bed_details = "#{bed&.code}(#{ward&.name}/#{room&.name})"
    end
    @tpa = @admission
    @patient = @admission.patient
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @age_gender = @patient.patient_age_gender

    # For Case Open All Notes Before Admitting
    @clinical_note = Inpatient::IpdRecord::ClinicalNote.find_by(admission_id: @admission.id)
  end

  def admission_note_params
    params.require(:inpatient_ipd_record_admission_note).permit(:template_type, :organisation_id, :facility_id, :admission_id, :patient_id, :user_id, :doctor_id, :department, :specalityname, :encountertype, :encountertypeid, :ward_id, :room_id, :bed_id, :daycare, :admission_date, :admission_time, :discharge_date, :admission_reason, :management_plan, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :blood_group, :marital_status, :occupation, :email, :address_1, :address_2, :city, :state, :pincode, :emergency_contact_name, :emergency_mobile_number, :expected_management, :expected_stay, :hospitalization_reason, :complaint_date, :medico_legal_case, :medico_legal_details, :payment_type)
  end

  def admission_note
    @admission_note = @ipdrecord.admission_note
  end

  def find_ipdrecord_for_read
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def find_ipdrecord_for_write
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record_admission_note][:admission_id])
  end
end
