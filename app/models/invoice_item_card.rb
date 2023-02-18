class InvoiceItemCard
  include Mongoid::Document
  include Mongoid::Timestamps

  field :item_name, type: String
  field :item_type, type: String
  field :item_price, type: Float, default: 0.0 # amount including tax
  field :quantity, type: Integer
  field :item_id, type: BSON::ObjectId, default: BSON::ObjectId.new()
  field :user_name, type: String

  field :amount, type: Float, default: 0.0 # amount entered by user in form
  field :tax_group_id, type: BSON::ObjectId
  field :tax_inclusive, type: Boolean, default: true
  field :taxable_amount, type: Float, default: 0.0
  field :non_taxable_amount, type: Float, default: 0.0
  field :sac, type: String

  # Case to check where the card was created from
  field :created_from, type: String

  # Case Soft Delete
  field :card_deleted, type: Boolean, default: false

  belongs_to :invoice_service_card
  belongs_to :facility
  belongs_to :organisation
  belongs_to :user

  before_save :non_tax_default_values

  def non_tax_default_values
    @invoice_setting = InvoiceSetting.find_by(organisation_id: self.organisation_id)
    unless (@invoice_setting.try(:tax_enabled))
      self.amount = self.item_price
      self.non_taxable_amount = self.item_price
      self.taxable_amount = 0.0
    end
  end
end
