class ReferdocPatientRelation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :refer_doc_id, type: String
  field :patient_id, type: String
end
