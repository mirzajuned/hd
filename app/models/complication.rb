class Complication
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :complication_name, type: String
  field :code, type: String
  field :comment, type: String
  field :complication_original_side, type: String

  field :operative_note_id, type: String
  field :ipd_record_id_id, type: String
  field :case_sheet_complication_id, type: String
  field :procedure_id, type: String
  field :procedure_code, type: String

  field :entered_by, type: String
  field :entered_by_id, type: String
  field :entered_at_facility, type: String
  field :entered_at_facility_id, type: String
  field :entered_datetime, type: String

  field :updated_by, type: String
  field :updated_by_id, type: String
  field :updated_at_facility, type: String
  field :updated_at_facility_id, type: String
  field :updated_datetime, type: String

  field :is_deleted, type: Boolean, default: 0

  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"
end
