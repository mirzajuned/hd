class Patientdata::Update
  attr_accessor :users, :facilities, :departments

  def initialize(params, current_user, patientid)
    @patientparams = params
    current_user = current_user
    @patient = Patient.find(patientid)
  end

  def updatepatient
    begin
      # This will return a Patient::Create object
      if @patient.update(patient_attributes)
        unless @patientparams[:patientassets_attributes]
          create_patient_asset(@patient)
        end
        if @patient.dob.present?
          create_patient_birthday(@patient)
        end
        # model method for exact_age
        @patient.get_exact_age(@patient.age.to_i, @patient.age_month.to_i)
      end

      return @patient
    rescue
      false
    end
  end

  private

  def create_patient_asset(patient)
    media = File.open(Rails.root + "app/assets/images/placeholder.png")
    Patientasset.create(patient_id: patient.id, asset_path: media)
  end

  def create_patient_birthday(patient)
    patient_birthday = PatientBirthday.find_by(patient_id: patient.id)
    if patient_birthday
      patient_birthday.update(dob: patient.dob.strftime("%d%m"))
    else
      PatientBirthday.create(patient_id: patient.id, dob: patient.dob.strftime("%d%m"))
    end
  end

  def patient_attributes
    @patientparams.permit!
  end
end
