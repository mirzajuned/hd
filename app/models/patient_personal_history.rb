class PatientPersonalHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :problems, type: Array
  field :flag, type: Integer, default: 0

  embedded_in :patienthistory, class_name: "::PatientHistory"

  def problems=(values)
    write_attribute(:problems, values.reject(&:blank?))
  end

  def empty?
    ignored_attrs = { '_id' => 1, 'created_at' => 1, 'updated_at' => 1 }
    self.attributes.all? { |k, v| v.blank? || ignored_attrs[k] }
  end
end
