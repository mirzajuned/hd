class PatientAssessmentJob < ActiveJob::Base
  queue_as :urgent
  def perform(admission_id, patient_id, currentuserid)
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    if @admission.present? && @patient.present?
      @assessment = PatientAssessment.find_by(admission_id: @admission.id)
      if @assessment.present?
        @vital = @patient.patient_vitals.new
        @vital.temperature = @assessment.temperature
        @vital.pulse = @assessment.pulse
        @vital.height = @assessment.height
        @vital.weight = @assessment.weight
        @vital.blood_pressure = @assessment.blood_pressure
        @vital.respiratory_rate = @assessment.respiratory_rate
        @vital.bmi = @assessment.bmi
        @vital.spo2 = @assessment.spo2
        @vital.vital_comment = @assessment.vital_comment
        @vital.vital_trail = { admission_id: @admission.id.to_s, patient_id: @patient.id.to_s, user: @admission.user_id.to_s, facility_id: @admission.facility_id.to_s, changein: "Asssessment form Ipd" }
        @vital.save
      end
    end
  end
end
