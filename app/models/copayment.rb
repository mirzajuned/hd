class Copayment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :service, type: String
  field :amount, type: String

  belongs_to :patient
  belongs_to :admission
  belongs_to :organisation
  belongs_to :facility
  belongs_to :user
end
