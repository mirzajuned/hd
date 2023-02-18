class Patients::UpdateDetails::AdmissionListViewService
  def initialize(patient)
    @patient = patient
  end

  def call
    AdmissionListView.where(patient_id: @patient.try(:id)).try(:each) do |alv|
      alv.update(update_attributes)
    end
  end

  private

  def update_attributes
    {
      patient_name: @patient.fullname,
      patient_age: @patient.exact_age,
      patient_gender: @patient.gender,
      patient_display_id: @patient.patient_identifier_id,
      patient_mr_no: @patient.patient_mrn,
      patient_type: @patient.patient_type.try(:label),
      patient_type_color: @patient.patient_type.try(:color),
      city: @patient&.city,
      commune: @patient&.commune,
      pincode: @patient&.pincode,
      district: @patient&.district,
      state: @patient&.state,
      patient_mobilenumber: @patient&.mobilenumber,
      age: @patient&.age
    }
  end
end
