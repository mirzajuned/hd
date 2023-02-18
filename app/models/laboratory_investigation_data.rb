class LaboratoryInvestigationData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :is_deleted, type: Boolean, default: false
  field :is_custom, type: Boolean, default: true
  field :only_sub_test, type: Boolean, default: false
  field :has_sub_tests, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :created_by, type: BSON::ObjectId
  field :is_custom, type: Boolean
  field :is_uploaded, type: Boolean
  field :normal_range, type: String
  field :investigation_name, type: String
  field :loinc_code, type: String
  field :loinc_class, type: String
  field :short_name, type: String
  field :test_type, type: String
  field :specialty_id, type: String
  field :investigation_id, type: String
  field :panel_ids, type: Array
  field :level, type: String

  has_and_belongs_to_many :laboratory_panel_investigation_datas, :class_name => 'LaboratoryPanelInvestigationData'
end

################### ACTIVE RECORD CODE COMMENTED #############################################3
# class LaboratoryInvestigationData < ActiveRecord::Base
# self.table_name = :laboratory_investigations
# self.primary_key = :investigation_id
# end
