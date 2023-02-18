class CopaymentsController < ApplicationController
  before_action :authorize

  def new
    @admission = Admission.find(params[:admission_id])
    @patient = Patient.find(@admission.patient_id)
    @organisation = current_user.organisation
    @facility = Facility.find(@admission.facility_id)
    @user = current_user

    @copay = Copayment.new

    respond_to do |format|
      format.js {}
    end
  end

  def create
    @copay = Copayment.new(copay_params)
    if @copay.save
      respond_to do |format|
        format.js { render "show", layout: false }
      end
    end
  end

  def show
  end

  def edit
    @admission = Admission.find(params[:admission_id])
    @patient = Patient.find(@admission.patient_id)
    @organisation = current_user.organisation
    @facility = Facility.find(@admission.facility_id)
    @user = current_user

    @copay = Copayment.find(params[:id])

    respond_to do |format|
      format.js {}
    end
  end

  def update
    @copay = Copayment.find(params[:id])

    if @copay.update_attributes(copay_params)
      respond_to do |format|
        format.js { render 'show' }
      end
    end
  end

  def print_copay_receipt
    @copay = Copayment.find(params[:id])
    @organisation = current_user.organisation
    @admission = Admission.find(@copay.admission_id)
    @patient = Patient.find(@copay.patient_id)
    respond_to do |format|
      format.pdf { render :template => "copayments/print.pdf.erb", :pdf => "xyz", :layout => 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :footer => { :right => '[page] of [topage]' } }
    end
  end

  private

  def copay_params
    params.require(:copayment).permit(:service, :amount, :user_id, :organisation_id, :facility_id, :admission_id, :patient_id)
  end
end
