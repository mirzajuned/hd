class InvoiceServiceCard
  include Mongoid::Document
  include Mongoid::Timestamps

  field :service_name, type: String
  field :service_type, type: String, default: "Service"
  field :service_id, type: BSON::ObjectId, default: BSON::ObjectId.new()
  # Case to check where the card was created from
  field :created_from, type: String
  # Case Soft Delete
  field :card_deleted, type: Boolean, default: false
  # Use Count
  field :use_count, type: Integer
  field :use_amount, type: Integer

  has_many :invoice_item_card

  belongs_to :facility
  belongs_to :organisation
  belongs_to :user

  validates :service_name, uniqueness: true, if: :name_unique_within_facility

  def name_unique_within_facility
    @invoiceservicecard = InvoiceServiceCard.find_by(facility_id: facility_id, service_name: service_name).present?
  end
end
