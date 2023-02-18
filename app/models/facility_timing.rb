class FacilityTiming
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :day, type: Integer
  field :start_time, type: Time
  field :end_time, type: Time
  # field :count, type: Integer
  field :facility_id, type: String
  field :user_id, type: String
  field :organisation_id, type: String
  field :ip_address, type: String

  # validates :name, :presence => {:message => 'Facility Name cannot be blank'}
end
