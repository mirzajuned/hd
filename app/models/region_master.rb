class RegionMaster
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: BSON::ObjectId
  field :country_id, type: String
  
  field :name, type: String
  field :abbreviation, type: String
  
  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: false
end

# db.region_masters.createIndex({'organisation_id': 1, 'country_id': 1 }, {'background': true, 'name': 'idxfor_create_data'});
