class WardNoteAssessmentJob < ActiveJob::Base
  queue_as :urgent
  def perform(admission_id, patient_id, currentuserid)
    @admission = Admission.find_by(id: admission_id)
    @patient = Patient.find_by(id: patient_id)
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
    @wardnote = @ipdrecord.ward_notes.last
    if @admission.present? && @patient.present? && @ipdrecord.present? && @wardnote.present?
      @vital = @patient.patient_vitals.new
      @vital.temperature = @wardnote.vitalsignstemperature
      @vital.pulse = @wardnote.vitalsignspulse
      @vital.height = @wardnote.anthropometryheight
      @vital.weight = @wardnote.anthropometryweight
      @vital.blood_pressure = @wardnote.vitalsignsbp
      @vital.respiratory_rate = @wardnote.vitalsignsrr
      @vital.spo2 = @wardnote.vitalsignsspo2
      @vital.bmi = @wardnote.anthropometrybmi
      @vital.vital_trail = { admission_id: @admission.id.to_s, patient_id: @patient.id.to_s, user: @admission.user_id.to_s, facility_id: @admission.facility_id.to_s, changein: "Change in Note of IPD" }
      @vital.save
    end
  end
end
