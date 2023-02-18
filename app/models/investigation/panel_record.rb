class Investigation::PanelRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :investigation_name, type: String
  field :investigation_val, type: String
  field :normal_range, type: String
  embedded_in :record, class_name: "::Investigation::Record"
end
