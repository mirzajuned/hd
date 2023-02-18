class PatientSummaryTimelineRoute
  def self.matches?(request)
    patient = Patient.find_by(id: request.params[:patient_id])

    patient.present?
  end
end
