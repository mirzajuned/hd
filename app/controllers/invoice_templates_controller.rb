class InvoiceTemplatesController < ApplicationController
  layout 'loggedin'
  respond_to :js, :json, :html

  before_action :authorize
  before_action :set_payers, only: [:new, :edit]
  before_action :set_specialties, only: [:new, :edit]
  before_action :set_invoice_template, only: [:edit, :update, :destroy]

  def index
    @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id.to_s, version: 'v21.0', is_active: true)
  end

  def new
    @invoice_template = InvoiceTemplate.new
  end

  def create
    @invoice_template = InvoiceTemplate.new(invoice_template_params)

    return if @invoice_template.save

    set_payers
    render :new
  end

  def edit
    template_services = @invoice_template[:template_details]
    @template_services = if template_services != 'null' 
                          JSON.parse(template_services.gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
                        else
                          # template_services  
                          nil
                        end
    
    facility_id = @invoice_template.facility_id
    specialty_id = @invoice_template.specialty_id
    department_id = @invoice_template.department_id

    options = { facility_id: facility_id, specialty_id: specialty_id, department_id: department_id }
    @pricing_masters = PricingMaster.includes(:service_master, :service_group, :service_sub_group).where(options)
                                    .group_by(&:service_group_id)

    @surgery_packages = SurgeryPackage.where(options)
  end

  def update
    return if @invoice_template.update_attributes(invoice_template_params)

    set_payers
    render :edit
  end

  def destroy
    @invoice_template.update_attributes(is_active: false)
  end

  private

  def invoice_template_params
    params[:invoice_template][:template_details] = params[:invoice_template][:template_details].to_json

    params.require(:invoice_template).permit(:organisation_id, :facility_id, :specialty_id, :department_id, :user_id,
                                             :payer_master_id, :version, :name, :total, :template_details)
  end

  def set_invoice_template
    @invoice_template = InvoiceTemplate.find_by(id: params[:id])
  end

  def set_payers
    @payer_masters = PayerMaster.where(facility_id: current_facility.id.to_s)
    @payer_fields = @payer_masters.map { |c| { id: c.id.to_s, display_name: c.display_name } }
  end

  def set_specialties
    @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @selected_specialty = @invoice_template.try(:specialty_id) || @available_specialties.first.id
  end
end
