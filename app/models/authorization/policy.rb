# No Offenses
class Authorization::Policy
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps


  field :is_migrated, type: Boolean, default: true
  field :is_disable, type: Boolean, default: false
  field :last_edited_by, type: String

  field :maker_checker, type: Boolean, default: false

  field :authorized, type: Boolean, default: false

  field :entity_data, type: Hash

  field :rules, type: Hash

  field :module_name, type: String
  field :module_id, type: String
  field :module_code, type: String

  field :feature_name, type: String
  field :feature_id, type: String
  field :feature_code, type: String

  field :component_name, type: String
  field :component_id, type: String
  field :component_code, type: String

  field :description, type: String

  field :policy_identifier, type: String

  field :hg_policy_id, type: BSON::ObjectId

  field :organisation_id, type: BSON::ObjectId

  belongs_to :hg_policy

end