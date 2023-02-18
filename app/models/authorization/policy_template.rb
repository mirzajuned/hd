# No Offenses
class Authorization::PolicyTemplate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps


  field :is_migrated, type: Boolean, default: true
  field :is_disable, type: Boolean, default: false
  field :last_edited_by, type: String

  # field :setup_type, type: String, default: "User" #User/Designation

  field :policy_ids, type: String, default: ""

  field :name, type: String

  # field :user_id, type: BSON::ObjectId
  # field :designation_id, type: BSON::ObjectId

  # field :hg_policy_id, type: BSON::ObjectId

  field :organisation_id, type: BSON::ObjectId


end