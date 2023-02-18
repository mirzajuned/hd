class UsersMedicationList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :contents, type: String
  field :manufacturer, type: String
  field :presentation, type: String

  belongs_to :user
end
