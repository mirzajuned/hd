class ApiKey
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :access_token, type: String
  field :expiry_time, type: DateTime

  validates :access_token, uniqueness: true
  belongs_to :user
end
