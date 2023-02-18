class TpaInsuranceWorkflowStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  field :namespace, type: String
  field :event, type: String
  field :from, type: String
  field :to, type: String

  belongs_to :tpa_insurance_workflow

  scope :last_states, lambda { order("created_at asc") }
end

# indexes on this model's fields

# db.tpa_insurance_workflow_state_transitions.createIndex({ tpa_insurance_workflow_id: 1 })
