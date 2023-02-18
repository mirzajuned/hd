class UsersOpdRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :base_template, type: String
  field :record_details, type: String

  belongs_to :user
end
