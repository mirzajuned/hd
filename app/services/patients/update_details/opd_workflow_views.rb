class Patients::UpdateDetails::OpdWorkflowViews
  def initialize(patient)
    @patient = patient
  end

  def call
    OpdClinicalWorkflow.where(patient_id: @patient.id.to_s).try(:each) do |workflow|
      workflow.update(update_attributes)
    end
  end

  private

  def update_attributes
    {
      patient_name: @patient.fullname,
      patient_mobilenumber: @patient.mobilenumber,
      patient_age: @patient.exact_age,
      patient_gender: @patient.gender,
      patient_type: @patient.patient_type.try(:label),
      patient_type_color: @patient.patient_type.try(:color)
    }
  end
end
