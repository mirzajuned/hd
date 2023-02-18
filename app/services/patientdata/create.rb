class Patientdata::Create
  # attr_accessor :users,:facilities,:departments

  def initialize(params, current_user)
    @patientparams = params
    current_user = current_user
  end

  def createpatient
    begin
      # This will return a Patient::Create object
      patient = Patient.create(patient_attributes)
      unless @patientparams[:patientassets_attributes]
        create_patient_asset(patient)
      end
      return patient
    rescue => error
      # false
      $!.backtrace
    end
  end

  private

  def patient_attributes
    @patientparams.permit!
  end

  def create_patient_asset(patient)
    media = File.open(Rails.root + "app/assets/images/placeholder.png")
    Patientasset.create(patient_id: patient.id, asset_path: media)
  end
end
