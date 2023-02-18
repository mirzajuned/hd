class PatientsServicesSaveService
  def self.handle_patients_service(event)
    @patients_service = PatientsService.new
    @patients_service[:patient_id] = event.patient_id
    @patients_service[:user_id] = event.user_id
    @patients_service[:description] = event.description
    @patients_service[:interaction_type] = event.type
    @patients_service.save
  end
end
