class CustomTemplateHeadersController < ApplicationController
  before_action :authorize
  before_action :set_organisation_setting
  before_action :set_type, only: [:edit, :update]

  def index; end

  def edit
    setting_name, setting_type = setting_details
    @print_data = @organisation_setting.custom_template_header_options[setting_name][setting_type]
    @invoice_header_data = @organisation_setting.custom_invoice_header_title["#{@type}_#{setting_type}_title".to_sym][setting_type][0] if invoice_type?
  end

  def update
    update_internal_hash
    @organisation_setting.save!
  end

  private

  def set_organisation_setting
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end

  def set_type
    @type = params[:flag].split("_").first
  end

  def update_internal_hash(final_hash = {})
    setting_name, setting_type = setting_details

    params[:print_details].each { |key, value| final_hash.merge!("#{key}": value == 'true') }

    # next 2 lines done intentionally, hash order was not getting updated after save
    @organisation_setting.custom_template_header_options[setting_name][setting_type] = []
    @organisation_setting.save!

    @organisation_setting.custom_template_header_options[setting_name][setting_type] = [final_hash]
    if invoice_type?
      invoice_header_titles = {}
      params[:header_titles].each { |key, value| invoice_header_titles.merge!("#{key}": value) }
      @organisation_setting.custom_invoice_header_title["#{@type}_#{setting_type}_title".to_sym][setting_type]=[invoice_header_titles]
    end
  end

  def setting_details
    setting_name = params[:setting_name].to_sym
    setting_type = params[:setting_type].to_sym

    [setting_name, setting_type]
  end

  def invoice_type?
    params[:setting_type].to_s == 'invoices'
  end
end
