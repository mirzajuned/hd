class UserLogTrail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :action_taken, type: String
  field :user_role, type: String
  field :ip_address, type: String
  field :user_name, type: String # user name of user who is adding a new user
  field :user_id, type: BSON::ObjectId # user id of user who is adding a new user
  field :time, type: Time, default: Time.current

  field :changes_field, type: Hash, default: {}

  embedded_in :user, class_name: '::User'
end
