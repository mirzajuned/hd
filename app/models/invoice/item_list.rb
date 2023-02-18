class Invoice::ItemList
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :item_name, type: String
  field :facility_id, type: BSON::ObjectId
  field :use_count_opd, type: Integer, default: 0
  field :use_count_ipd, type: Integer, default: 0
  field :use_count_insurance, type: Integer, default: 0
  field :opdsum, type: Float, default: 0
  field :ipdsum, type: Float, default: 0
  field :insurancesum, type: Float, default: 0
  field :organisation_id, type: BSON::ObjectId
end
