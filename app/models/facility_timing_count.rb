class FacilityTimingCount
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :start_time, type: String
  field :end_time, type: String
  field :count, type: Integer
  field :facility_id, type: String
  field :user_id, type: String
  field :organisation_id, type: String
  field :day, type: String
  # field :ip_address, type: String

  # validates :name, :presence => {:message => 'Facility Name cannot be blank'}
end
