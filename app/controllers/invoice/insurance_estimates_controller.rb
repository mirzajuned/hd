class Invoice::InsuranceEstimatesController < ApplicationController
  before_action :authorize

  def new
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:workflow_id])
    @tpa_form = TpaInsurancePreAuthorizationForm.find_by(tpa_insurance_workflow_id: @tpa_workflow.try(:id))
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: @tpa_workflow.try(:admission_id))
    @organisation_id = current_user.organisation_id
    @organisation = current_user.organisation

    # Logic for INS-INV Display_Id
    @invoicecount = Invoice::InsuranceEstimate.where(organisation_id: current_user.organisation_id).count
    if @invoicecount < 10
      @displaycounter = @organisation.identifier_prefix + "-INS-INV-EST-00" + (@invoicecount + 1).to_s
    elsif @invoicecount < 100 && @invoicecount > 9
      @displaycounter = @organisation.identifier_prefix + "-INS-INV-EST-0" + (@invoicecount + 1).to_s
    else
      @displaycounter = @organisation.identifier_prefix + "-INS-INV-EST-" + (@invoicecount + 1).to_s
    end
    # Logic for INS-INV Display_Id Ends

    @invoice = Invoice::InsuranceEstimate.new

    respond_to do |format|
      format.js { render "invoice/insurance_estimates/new", layout: false }
    end
  end

  def create
    @invoice = Invoice::InsuranceEstimate.new(insurance_invoice_params)
    @tpa = TpaInsurancePreAuthorizationForm.find_by(id: @invoice.tpa_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    @fullname = (@patient.try(:salutation).to_s + " " + params[:patient][:firstname] + " " + params[:patient][:middlename] + " " + params[:patient][:lastname]).to_s.strip

    if @invoice.save(validate: false)
      @patient.update_attributes(patient_params)
      @patient.update_attributes(fullname: @fullname)
      # model method for exact_age
      @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)
      @admission = Admission.find_by(id: @invoice.try(:admission_id))
      # For Refreshing Admission List
      @admission_selected = Admission.find_by(id: @tpa.try(:admission_id))
      respond_to do |format|
        format.js { render "invoice/insurance_estimates/show", layout: false }
      end
    end
  end

  def show
    @invoice = Invoice::InsuranceEstimate.find_by(id: params[:id])
    @tpa = TpaInsurancePreAuthorizationForm.find_by(id: @invoice.try(:tpa_id))
    @patient = Patient.find_by(id: @invoice.patient_id)
    @admission = Admission.find_by(id: @invoice.try(:admission_id))
    @facility = Facility.find_by(id: @invoice.facility_id) if @invoice.facility_id.present?

    respond_to do |format|
      format.js { render "invoice/insurance_estimates/show", layout: false }
    end
  end

  def edit
    @invoice = Invoice::InsuranceEstimate.find_by(id: params[:id])
    @tpa = TpaInsurancePreAuthorizationForm.find_by(id: @invoice.try(:tpa_id))
    @patient = Patient.find_by(id: @invoice.patient_id)
    @admission = Admission.find_by(id: @invoice.try(:admission_id))
    @organisation_id = current_user.organisation_id

    respond_to do |format|
      format.js { render "invoice/insurance_estimates/edit", layout: false }
    end
  end

  def update
    @patient = Patient.find_by(id: params[:invoice_insurance_estimate][:patient_id])
    @invoice = Invoice::InsuranceEstimate.find_by(id: params[:id])
    @tpa = TpaInsurancePreAuthorizationForm.find_by(id: @invoice.try(:tpa_id))
    @fullname = (@patient.try(:salutation).to_s + " " + params[:patient][:firstname] + " " + params[:patient][:middlename] + " " + params[:patient][:lastname]).to_s.strip
    @admission = Admission.find_by(id: @invoice.try(:admission_id))
    # Hack for Repeatative Service Saving
    @invoice.services.delete_all

    if @invoice.update_attributes(insurance_invoice_params)
      @patient.update_attributes(patient_params)
      @patient.update_attributes(fullname: @fullname)
      # model method for exact_age
      @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)

      # For Refreshing Admission List
      @admission_selected = Admission.find_by(id: @tpa.try(:admission_id))
      respond_to do |format|
        format.js { render "invoice/insurance_estimates/show", layout: false }
      end
    end
  end

  def print_estimate_invoice
    @invoice = Invoice::InsuranceEstimate.find_by(id: params[:invoice_id])
    @organisation = current_user.organisation
    @admission = Admission.find_by(id: @invoice.admission_id)
    @patient = Patient.find_by(id: @invoice.patient_id)
    # @tpa = TpaInsurancePreAuthorizationForm.find_by(id: @invoice.tpa_id)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "Invoice")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "invoice/insurance_estimates/print_estimate_invoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  private

  def insurance_invoice_params
    params.require(:invoice_insurance_estimate).permit(:mode_of_payment_insurance, :estimate_display_id, :organisation_id, :facility_id, :tpa_insurance_workflow_id, :net_amount, :total, :tax, :discount, :advance_payment, :mode_of_payment, :amount_paid_tpa, :amount_paid_patient, :patient_id, :admission_id, :tpa_id, services: [:_id, :name, :service_total, items: [:_id, :description, :quantity, :unit_price, :price, :item_code, :patient_payed]])
  end

  def patient_params
    params.require(:patient).permit(:firstname, :middlename, :lastname, :gender, :age, :address_1, :address_2, :city, :state, :pincode, :email)
  end
end
