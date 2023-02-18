class InvoiceSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  # TaxSetting
  field :tax_enabled_opd, type: Boolean, default: false
  field :tax_enabled_ipd, type: Boolean, default: false
  field :tax_enabled_optical, type: Boolean, default: false
  field :tax_enabled_pharmacy, type: Boolean, default: false
  field :gst_indentification_number, type: String
  field :show_tax_in_print, type: Boolean, default: true
  field :terms_and_condition, type: String

  belongs_to :organisation
end

# Index organisation_id
