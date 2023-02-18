class RadiologyRecord < Investigation::Record
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps


  #
  # embeds_many :panel_lab_records, :class_name => 'Investigation::PanelLabRecord'
  #
  # accepts_nested_attributes_for :panel_lab_records
end
