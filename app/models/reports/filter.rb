class Reports::Filter
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :filter_name, type: String
  field :filter_value_name, type: String
  field :filter_type, type: String
  field :category, type: String
  field :value_type, type: String
  field :values, type: Hash
  field :organisation_id, type: String
  field :facility_id, type: String
  field :filter_group, type: String
  field :values_predefined, type: Boolean, default: true
  field :is_active, type: Boolean, default: true
  field :type, type: String
end


