class OtherInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :investigationstage, type: String
  field :investigationname, type: String
  field :investigation_name, type: String
  field :loincclass, type: String
  field :loinccode, type: String
  field :laboratorytestid, type: String

  embedded_in :opdrecord, class_name: "::OpdRecord"
end
