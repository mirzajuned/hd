class Finance::PanelMaster
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String                         #Display Name
  field :description, type: String
  field :last_edited_by, type: String
  field :is_disable, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :dispensary_master_id, type: BSON::ObjectId


  belongs_to :dispensary_master, optional: true

end
