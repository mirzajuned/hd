class OpdClinicalWorkflowStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  field :namespace, type: String
  field :event, type: String
  field :from, type: String
  field :to, type: String
  field :user_note, type: String
  field :state_type, type: String
  field :transition_start, type: DateTime
  field :transition_end, type: DateTime
  belongs_to :opd_clinical_workflow

  scope :last_states, lambda { order("created_at desc") }
  # index for query
  # db.opd_clinical_workflow_state_transitions.createIndex({ opd_clinical_workflow_id: 1 })
end
