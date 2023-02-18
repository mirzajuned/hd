class Inpatient::InsurancesController < ApplicationController
  before_action :authorize
  before_action :inpatient_insurance_tpa, only: [:show, :edit]

  # New Created While Creating Admission Refer ipd_patient_controller -> action admission_done
  def new; end

  def show
    respond_to do |format|
      format.js { render 'inpatient/insurance/show', layout: false }
    end
  end

  def edit
    respond_to do |format|
      format.js { render 'inpatient/insurance/edit', layout: false }
    end
  end

  def update
    @tpa = Admission.find_by(id: params[:insurance_id])
    params[:tpa][:insurance_status] = @tpa.is_insured == 'No' ? 'Not Insured' : 'Waiting'
    contact = Contact.find_by(id: params[:tpa][:insurance_contact_id])
    tpa_contact = Contact.find_by(id: params[:tpa][:tpa_contact_id])
    params[:tpa][:insurance_name] = contact&.display_name.to_s
    params[:tpa][:tpa_name] = tpa_contact&.display_name.to_s

    if @tpa.update_attributes(tpa_params)
      respond_to do |format|
        format.js { render 'inpatient/insurance/close', layout: false }
      end
    else
      respond_to do |format|
        format.js { render 'inpatient/insurance/edit', layout: false }
      end
    end
  end

  private

  def tpa_params
    params.require(:tpa).permit(
      :is_insured, :insurance_name, :insurance_contact_id, :tpa_name, :tpa_contact_no, :policy_no, :insurance_policy_no,
      :insurance_policy_expiry_date, :insurer, :company_name, :employee_id, :insurance_status, :comment,
      :insurance_comments, :approved_amount, :bracket_amount, :patient_id, :admission_id, :document_passport,
      :document_government_id, :document_vss, :document_aadharcard, :document_electioncard, :document_insurancecard,
      :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form, :sum_insured,
      :document_patient_cancelled_cheque, :admission_hospitalisation_type, :tpa_contact_id
    )
  end

  # insurance details saving in admission model now
  def inpatient_insurance_tpa
    @current_user = current_user
    @contact_groups = ContactGroup.where(organisation_id: @current_user.organisation_id, contact_group_type: 'tpa')
    @tpa_contact = @contact_groups.find_by(name: 'TPA')
    @insurance_contact = @contact_groups.find_by(name: 'Insurance')

    @contacts = Contact.where(is_deleted: false, organisation_id: @current_user.organisation_id)
    @tpa_contacts = @contacts.where(contact_group_id: @tpa_contact.try(:id))
    @insurance_contacts = @contacts.where(contact_group_id: @insurance_contact.try(:id))
    @tpa = Admission.find_by(id: params[:id])
  end
end
