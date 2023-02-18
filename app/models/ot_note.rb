class OtNote
  include Mongoid::Document
  field :_id, type: String
  field :patient_id, type: String
end
