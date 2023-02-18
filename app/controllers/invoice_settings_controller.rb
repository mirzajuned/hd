class InvoiceSettingsController < ApplicationController
  before_action :invoice_setting, only: [:tax_settings, :update]

  def tax_settings
    organisation_id_array = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    options = { :organisation_id.in => organisation_id_array, country_id: country_id, is_deleted: false }

    @tax_rates = TaxRate.where(options).order(created_at: :desc)
    @tax_groups = TaxGroup.where(options).order(created_at: :desc)

    @tax_rate_ids = @tax_groups.pluck(:tax_rate_ids).flatten.uniq
    @tax_group_rates = @tax_rates.where(:id.in => @tax_rate_ids)
                                 .map { |tgr| { id: tgr.id, name: tgr.name, rate: tgr.rate } }
  end

  def update
    @invoice_setting&.update(tax_enabled_opd: params[:tax_enabled_opd], tax_enabled_ipd: params[:tax_enabled_ipd],
                             tax_enabled_pharmacy: params[:tax_enabled_pharmacy],
                             tax_enabled_optical: params[:tax_enabled_optical],
                             show_tax_in_print: params[:show_tax_in_print],
                             gst_indentification_number: params[:gst_indentification_number])

    render json: { 'success': true }
  end

  private

  def invoice_setting
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
  end
end
