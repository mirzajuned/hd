class AdmissionNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_type, type: String, default: "AdmissionNote"
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :doctor_id, type: BSON::ObjectId
  field :department, type: String
  field :specalityname, type: String
  field :specalityid, type: String
  field :encountertype, type: String, default: "IPD"
  field :encountertypeid, type: String, default: "440654001"
  field :note_created_at, type: Time, default: Time.current
  field :ward_id, type: BSON::ObjectId
  field :room_id, type: BSON::ObjectId
  field :bed_id, type: BSON::ObjectId
  field :daycare, type: Boolean
  field :admission_date, type: Date
  field :admission_time, type: Time
  field :discharge_date, type: Date
  field :admission_reason, type: String
  field :management_plan, type: String
  # Patient Info
  field :patient_name, type: String
  field :patient_age, type: String
  field :patient_gender, type: String
  field :mr_no, type: String
  field :patient_identifier_id, type: String
  field :blood_group, type: String
  field :marital_status, type: String
  field :occupation, type: String
  field :email, type: String
  field :address_1, type: String
  field :address_2, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: String
  field :emergency_contact_name, type: String
  field :emergency_mobile_number, type: String
  # Addition Info
  field :expected_management, type: String
  field :expected_stay, type: String
  field :hospitalization_reason, type: String
  field :complaint_date, type: Date
  field :medico_legal_case, type: String
  field :medico_legal_details, type: String
  field :payment_type, type: String

  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"
  def checkboxes_checked(checked)
    checked&.split(',')
  end

  after_save {
    self.update_patient_details
    self.update_admission_details
  }

  def update_patient_details
    @patient = Patient.find_by(id: self.patient_id)
    if @patient
      @patient.update_attributes(blood_group: self.blood_group, marital_status: self.marital_status, occupation: self.occupation, email: self.email, address_1: self.address_1, address_2: self.address_2, city: self.city, state: self.state, pincode: self.pincode, emergency_contact_name: self.emergency_contact_name, emergency_mobile_number: self.emergency_mobile_number)
    end
  end

  def update_admission_details
    @admission = Admission.find_by(id: self.admission_id)
    if @admission
      if self.discharge_date < self.admission_date
        discharge_date = self.admission_date
      else
        discharge_date = self.discharge_date
      end
      @admission.update_attributes(patient_arrived: true, facility_id: self.facility_id, doctor: self.doctor_id, admissiondate: self.admission_date, admissiontime: self.admission_time, dischargedate: discharge_date, admissionreason: self.admission_reason, managementplan: self.management_plan)
    end
  end
end
