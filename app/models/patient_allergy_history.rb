class PatientAllergyHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :antimicrobialagents, type: Array, default: []
  field :antifungalagents, type: Array, default: []
  field :antiviralagents, type: Array, default: []
  field :nsaids, type: Array, default: []
  field :eyedrops, type: Array, default: []
  field :contact, type: Array, default: []
  field :food, type: Array, default: []
  field :others, type: String
  field :flag, type: Integer, default: 0

  embedded_in :patienthistory, class_name: "::PatientHistory"

  def antimicrobialagents=(values)
    write_attribute(:antimicrobialagents, values.reject(&:blank?))
  end

  def antifungalagents=(values)
    write_attribute(:antifungalagents, values.reject(&:blank?))
  end

  def antiviralagents=(values)
    write_attribute(:antiviralagents, values.reject(&:blank?))
  end

  def nsaids=(values)
    write_attribute(:nsaids, values.reject(&:blank?))
  end

  def contact=(values)
    write_attribute(:contact, values.reject(&:blank?))
  end

  def food=(values)
    write_attribute(:food, values.reject(&:blank?))
  end

  def eyedrops=(values)
    write_attribute(:eyedrops, values.reject(&:blank?))
  end

  def empty?
    ignored_attrs = { '_id' => 1, 'created_at' => 1, 'updated_at' => 1 }
    self.attributes.all? { |k, v| v.blank? || ignored_attrs[k] }
  end
end
