class RecordHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :user_id, type: String
  field :action, type: String
  field :actiontime, type: Time
  field :template_type, type: String

  belongs_to :user, optional: true
  embedded_in :opdrecord, class_name: "::OpdRecord", inverse_of: :record_histories
  embedded_in :ipdrecord, class_name: "::Inpatient::IpdRecord"
  embedded_in :invoice, class_name: "::Invoice"
  embedded_in :record, class_name: "::Investigation::Record"
  embedded_in :record, class_name: "::EhrInvestigation::Record"
  embedded_in :record, class_name: "::NursingRecord"
  embedded_in :record, class_name: "::PatientAssessment"
  embedded_in :record, class_name: "::Inpatient::WardChecklist"
  embedded_in :record, class_name: "::Inpatient::PreAnaesthesiaNote"
  embedded_in :record, class_name: "::OtChecklist"
end
