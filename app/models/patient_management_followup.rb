class PatientManagementFollowup
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :doctor, type: BSON::ObjectId
  field :encounter_type, type: String # OPD or IPD
  field :encounter_date, type: Date
  field :followup_advice, type: String
  field :followup_date, type: Date
  # field :options, type: Hash  # {:doctor => "user_id", :o_id => "eee", :app_id => "dddd" }

  belongs_to :organisation
  belongs_to :facility
  belongs_to :patient
  belongs_to :user
end
