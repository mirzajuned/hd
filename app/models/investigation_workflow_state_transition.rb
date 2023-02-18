class InvestigationWorkflowStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :namespace, type: String
  field :event, type: String
  field :from, type: String
  field :to, type: String
  belongs_to :investigation_workflow
end
