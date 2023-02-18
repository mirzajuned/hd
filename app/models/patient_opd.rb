class PatientOpd
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :created_date, type: String
  embeds_many :records, class_name: "::Record"
  embeds_many :procedures, class_name: "::Procedure"
  embeds_many :diagnosis, class_name: "::Diagnosis"
end
