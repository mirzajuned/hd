class EntityGroup
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :display_name, type: String
  field :abbreviation, type: String

  # Adress
  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :commune, type: String
  field :district, type: String

  field :is_active, type: Mongoid::Boolean, default: true
  field :is_migrated, type: Mongoid::Boolean, default: false
  
  belongs_to :organisation
  belongs_to :country, optional: true
end

# db.entity_groups.createIndex({'organisation_id': 1, 'is_active': 1}, {'background': true, 'name': 'idxfor_create_data'});
