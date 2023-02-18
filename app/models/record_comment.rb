class RecordComment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  embedded_in :opdrecord, class_name: "::OpdRecord"
end
