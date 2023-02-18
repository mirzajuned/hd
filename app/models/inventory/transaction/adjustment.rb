class Inventory::Transaction::Adjustment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend SearchType

  field :return_adjustment_number, type: String

  field :transaction_date, type: Date

  field :adjustment_display_id, type: String

  field :entered_by, type: String
  field :entry_type, type: String

  field :note, type: String
  field :total_cost, type: Float
  field :adjusted_amount, type: Float
  field :comments, type: String
  field :search_type, type: String

  field :department_name, type: String
  field :department_id, type: String

  field :user_id, type: BSON::ObjectId
  field :store_name, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :bkp_adjustment_display_id, type: String
  field :item_entry_type, type: String

  embeds_many :items, class_name: '::Inventory::Transaction::Item'
  embeds_many :sequences, class_name: '::Inventory::Transaction::Adjustment::Sequence'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    refund = new
    refund.items.build(*args)
    refund
  end
end
