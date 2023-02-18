class Service
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :default_units, type: Integer
  field :unit_cost, type: Float

  field :service_type, type: String
  field :service_type_id, type: Integer
  field :is_custom, type: String

  belongs_to :organisation
  ## User and Facility are not set right now. There are not required. May be extended in future.
  # belongs_to :user
  # belongs_to :facility
end
