class Patientdata::Read
  attr_accessor :users, :facilities, :departments

  def initialize(id)
    @patientid = id
    # current_user = current_user
  end

  def readpatient
    begin
      # This will return a Patient::Create object
      patient = Patient.find(patient_attributes)
      return patient
    rescue
      false
    end
  end

  def self.get_patient_attributes(patient_id, query_array)
    attributes = Patient.find_by(id: patient_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

  def self.get_patient_other_attributes(patient_id, query_array)
    attributes = PatientOtherIdentifier.find_by(patient_id: patient_id)&.attributes.slice(*query_array) # * or asterisk is required.
    return attributes
  end

  # def self.build(layout = 'us')
  #   new(Keyboard.new(:layout => layout))
  # end

  private

  def patient_attributes
    @patientid
  end
end
