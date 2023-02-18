class ChiefComplaint
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :side, type: String
  field :duration, type: String
  field :duration_unit, type: String
  field :comment, type: String
  field :complaint_options, type: String
  field :is_available, type: String
  field :record_created_date, type: DateTime
  field :record_updated_date, type: DateTime
  field :history_started, type: Date

  # CaseSheet Fields
  field :record_id, type: BSON::ObjectId
  field :opd_chief_complaint_id, type: BSON::ObjectId

  field :user_id, type: BSON::ObjectId
  field :consultant_id, type: BSON::ObjectId
  field :consultant_name, type: String
  field :template_type, type: String

  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId
  field :entered_datetime, type: DateTime
  field :entered_from, type: String

  embedded_in :opd_record, class_name: "::OpdRecord"
  embedded_in :case_sheet, class_name: "::CaseSheet"
end
