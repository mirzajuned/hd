class TpaInsuranceNotesController < ApplicationController
  before_action :authorize
  before_action :set_current_user_facility
  before_action :find_insurance_form, only: [:new, :edit, :all_tpa_notes]

  def new
    @tpa_note = TpaInsuranceNote.new

    respond_to do |format|
      format.js {}
    end
  end

  def create
    @tpa_note = TpaInsuranceNote.new(tpa_note_params)
    if @tpa_note.save!

      respond_to do |format|
        format.js { render "tpa_insurance_notes/show", layout: false }
      end
    end
  end

  def edit
    @tpa_note = TpaInsuranceNote.find_by(id: params[:id])
  end

  def update
    @tpa_note = TpaInsuranceNote.find_by(id: params[:id])
    @tpa_note.update_attributes(tpa_note_params) if @tpa_note.present?

    respond_to do |format|
      format.js { render "tpa_insurance_notes/show", layout: false }
    end
  end

  def all_tpa_notes
    @tpa_notes = TpaInsuranceNote.where(organisation_id: @current_user.organisation_id, patient_id: @tpa_workflow.patient_id, tpa_insurance_workflow_id: @tpa_workflow.try(:id)).order_by(created_at: "desc")
  end

  def fetch_note_details
    @tpa_note = TpaInsuranceNote.find_by(id: params[:id])

    respond_to do |format|
      format.js { render 'append_tpa_note_details' }
    end
  end

  private

  def find_insurance_form
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:tpa_insurance_workflow_id])
    @patient = Patient.find_by(id: @tpa_workflow.patient_id)
    @insurance_details = TpaInsurancePreAuthorizationForm.find_by(tpa_insurance_workflow_id: @tpa_workflow.id)
  end

  def set_current_user_facility
    @current_user = current_user
    @current_facility = current_facility
  end

  def tpa_note_params
    params.require(:tpa_insurance_note).permit(:created_by, :patient_id, :appointment_id, :admission_id, :user_id, :facility_id, :organisation_id, :tpa_insurance_workflow_id, :room_cap_per_day, :note_name, :ailment_procedure_cap, :room_restrictions_comments, :pre_auth_admission_amount_date, :tpa_date_of_reply, :tpa_time_of_reply, :mode_of_reply, :addition_authorize_approval_date, :addition_authorize_amount_approved, :addition_authorize_comments, :pre_auth_admission_amount_approved, :pre_auth_admission_comments, :additional_auth_amount_approved, :query, :additional_auth_comments, :ailment_procedure_additional_comments, :ailment_procedure_comments, :denial, :patient_copays, :patient_copays => [])
  end
end
