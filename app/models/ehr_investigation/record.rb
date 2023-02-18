class EhrInvestigation::Record
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :test, type: String
  field :patient_id, type: BSON::ObjectId
  field :test_category, type: String
  field :investigation_val, type: String
  field :investigation_name, type: String
  field :normal_range, type: String
  field :_type, type: String
  field :investigation_comment, type: String
  field :specimen_date, type: String
  field :specimen_type, type: String
  field :doctors_remark, type: String
  field :investigation_record_id, type: BSON::ObjectId
  field :advised_at, type: DateTime
  field :advised_by, type: String
  field :performed_by, type: String
  field :performed_at, type: DateTime
  
  embeds_many :panel_records, :class_name => 'EhrInvestigation::PanelRecord'

  accepts_nested_attributes_for :panel_records, :class_name => 'EhrInvestigation::PanelRecord'

  embeds_many :record_histories
  accepts_nested_attributes_for :record_histories
end
