class TaxCollected
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :opd_tax, type: Float, default: 0.0
  field :ipd_tax, type: Float, default: 0.0
  field :pharmacy_tax, type: Float, default: 0.0
  field :optical_tax, type: Float, default: 0.0

  field :currency_id, type: String
  field :currency_symbol, type: String

  belongs_to :facility
  belongs_to :organisation
  embeds_many :tax_details
end
