class Patients::UpdateDetails::AppointmentListViewService
  def initialize(patient)
    @patient = patient
  end

  def call
    AppointmentListView.where(patient_id: @patient.try(:id).to_s).try(:each) do |alv|
      alv.update(update_attributes)
    end
  end

  private

  def update_attributes
    {
      patient_name: @patient.fullname,
      patient_mobilenumber: @patient.mobilenumber,
      patient_age: @patient.exact_age,
      patient_gender: @patient.gender,
      patient_mr_no: @patient.patient_mrn,
      patient_type: @patient.patient_type.try(:label),
      patient_type_color: @patient.patient_type.try(:color),
      city: @patient&.city,
      commune: @patient&.commune,
      pincode: @patient&.pincode,
      district: @patient&.district,
      state: @patient&.state,
      age: @patient&.age
    }
  end
end
