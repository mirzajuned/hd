# No Offenses
class Authorization::HgPolicy
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps


  field :is_migrated, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false

  field :maker_checker_ability, type: Boolean, default: false
  field :default_value, type: Boolean, default: true

  field :entities, type: Array

  field :rules, type: Hash

  field :policy_identifier, type: String

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

end