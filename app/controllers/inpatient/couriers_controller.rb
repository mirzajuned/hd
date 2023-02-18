class Inpatient::CouriersController < ApplicationController
  before_action :authorize

  def new
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = TpaInsurancePreAuthorizationForm.find_by(admission_id: @admission.try(:id))
    @couriers = Inpatient::Insurance::Courier.new
    @tpa_workflow_id = params[:tpa_workflow_id]

    respond_to do |format|
      format.js { render "inpatient/insurance/courier/new", :layout => false }
    end
  end

  def create
    @tpa_workflow_id = params[:tpa_workflow_id]
    @courier = Inpatient::Insurance::Courier.new(courier_params)

    if @courier.save
      respond_to do |format|
        format.js { render "inpatient/insurance/courier/show", layout: false }
      end
    end
  end

  def show
    @courier = Inpatient::Insurance::Courier.find_by(id: params[:id])

    respond_to do |format|
      format.js { render "inpatient/insurance/courier/show", layout: false }
    end
  end

  def edit
    @courier = Inpatient::Insurance::Courier.find_by(id: params[:id])
    @patient = Patient.find_by(id: @courier.patient_id)
    @admission = Admission.find_by(id: @courier.admission_id)
    @tpa = TpaInsurancePreAuthorizationForm.find_by(id: @courier.tpa_id)

    respond_to do |format|
      format.js { render "inpatient/insurance/courier/edit", layout: false }
    end
  end

  def update
    @courier = Inpatient::Insurance::Courier.find_by(id: params[:id])

    if @courier.update_attributes(courier_params)
      respond_to do |format|
        format.js { render "inpatient/insurance/courier/show", layout: false }
      end
    end
  end

  private

  def courier_params
    params.require(:inpatient_insurance_courier).permit(:sent_day, :courier_number, :courier_company, :courier_collected, :courier_handed, :contact_number, :comment, :current_status, :patient_id, :admission_id, :tpa_id)
  end
end
