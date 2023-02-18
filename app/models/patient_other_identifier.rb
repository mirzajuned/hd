class PatientOtherIdentifier # means these identifiers are used by clinics or hospitals who have their own way of storing identifiers of patients. These ids are external to HealthGraph's ID. This gives flexibility then what healthgraph creates that is ORG-PAT-uniqueid.
  include Mongoid::Document
  include Mongoid::Timestamps
  after_save :update_appointment_list_view, :admission_list_view, :ot_list_view, if: ->(obj) { obj.mr_no_changed? }

  field :mr_no, type: String
  field :ip_no, type: String
  field :patient_id, type: String
  field :organisation_id, type: String
  field :facility_id, type: String
  field :doctor, type: String

  def admission_list_view
    AdmissionListView.where(patient_id: self.patient_id).try(:each) do |alv|
      alv.update(patient_mr_no: self.mr_no)
    end
  end

  def ot_list_view
    OtListView.where(patient_id: self.patient_id).try(:each) do |olv|
      olv.update(patient_mr_no: self.mr_no)
    end
  end

  def update_appointment_list_view
    OpdClinicalWorkflow.where(patient_id: self.patient_id).try(:each) do |workflow|
      workflow.update(patient_mrno: self.mr_no)
    end
    AppointmentListView.where(patient_id: self.patient_id).try(:each) do |alv|
      alv.update(patient_mrno: self.mr_no)
    end
  end
end
