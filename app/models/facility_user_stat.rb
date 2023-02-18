class FacilityUserStat
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :facility_id, type: String
  field :user_id, type: String
  field :user_fullname, type: String
  field :primary_role, type: String
  field :patient_count, type: Integer, default: 0
  field :patient_ids, type: Array, default: []
end
