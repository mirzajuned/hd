class WardOccupancy
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :checkindate, type: Date
  field :checkintime, type: Time
  field :checkoutdate, type: Date
  field :checkouttime, type: Time
  field :wasshifted, type: Boolean, default: false

  belongs_to :organisation
  belongs_to :facility
  belongs_to :department
  belongs_to :admission
  belongs_to :ward
  belongs_to :room
  belongs_to :bed
  belongs_to :patient
  belongs_to :user
end
