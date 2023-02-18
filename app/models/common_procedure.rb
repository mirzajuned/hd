class CommonProcedure
  include Mongoid::Document
  include Mongoid::Timestamps

  field :region, type: Array

  field :name, type: String
  field :code, type: String

  field :has_laterality, type: Boolean, default: false
  field :laterality, type: Array

  field :speciality_id, type: String
  field :speciality_name, type: String

  validates_presence_of :name, :region, :code, :speciality_id, :speciality_name
  validates_presence_of :laterality, if: :has_laterality?
  validates_uniqueness_of :code
end
