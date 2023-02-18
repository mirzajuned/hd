class Inpatient::Diagnosis
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :diagnosisregions, type: String
  field :diagnosisname, type: String
  field :icddiagnosiscodelength, type: Integer
  field :icddiagnosiscode, type: String
  field :position_1, type: String
  field :position_2, type: String
  field :position_3, type: String
  field :position_4, type: String
  field :position_5, type: String
  field :position_6, type: String
  field :position_7, type: String
  field :icddiagnosisfullcode, type: String
  field :icddagnosisdate, type: String
  field :record_id, type: String

  # validates :record_id,:presence => {:message => 'Record id is must to create Inpatient Diagnosis'}

  def get_diagnosis_icd_label(icdcode, attribute_code, position)
    icdattributes = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => "#{icdcode}", :attribute_code_position => "#{position}", :attribute_code => "#{attribute_code}")
    icdattributes[0].try(:attribute_display_label)
  end

  def get_diagnosis_icd_attributes(icdcode, position)
    # puts icdcode
    icdattributes = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => "#{icdcode}", :attribute_code_position => "#{position}")
    icdattributes.map do |icdattr|
      Array[icdattr.attribute_display_label, icdattr.attribute_code]
    end
  end
end
