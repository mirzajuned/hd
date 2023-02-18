class TopIcdDiagnosis
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :specialty_id, type: Integer
  field :name, type: String
  field :list, type: Array
end
