class Inventory::CheckoutLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :department_id, type: String
  field :recipient, type: String
  field :authorized_by, type: String # Make it a reference later
  field :quantity, type: Integer
  field :total, type: Float, default: 0

  belongs_to :facility, class_name: '::Facility'
  embeds_many :items, class_name: '::Inventory::CheckoutLog::Item'

  accepts_nested_attributes_for :items

  scope :newest_log_first, -> { order('updated_at DESC') }
end
