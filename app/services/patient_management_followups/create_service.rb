module PatientManagementFollowups
  module CreateService
    def self.call(opdrecord)
      PatientManagementFollowup.where(record_id: opdrecord.id, patient_id: opdrecord.patientid).try(:destroy_all)

      appointment = Appointment.find_by(id: opdrecord.appointmentid)
      facility = Facility.find_by(id: appointment.facility_id)
      organisation = facility.organisation

      if facility.clinical_workflow
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
        consultant_id = User.find_by(:id => workflow.consultant_ids.last)
      else
        consultant_id = User.find_by(:id => appointment.consultant_id.to_s)
      end

      advice_data = opdrecord.has_advice?
      if !opdrecord.advice.opdfollowuptimeframe.blank?
        patient_advice = PatientManagementFollowup.new()
        patient_advice['doctor_name'] = consultant_id.fullname
        patient_advice['doctor'] = appointment.consultant_id.to_s
        patient_advice['user_id'] = appointment.consultant_id.to_s
        patient_advice['facility_id'] = appointment.facility_id
        patient_advice['patient_id'] = opdrecord.patientid
        patient_advice['record_id'] = opdrecord.id
        patient_advice['specalityid'] = opdrecord.specalityid
        patient_advice['specalityname'] = opdrecord.specalityname
        patient_advice['encounter_type'] = opdrecord.encountertype
        patient_advice['encountertypeid'] = opdrecord.encountertypeid
        patient_advice['encounter_date'] = opdrecord.created_at
        patient_advice['followup_advice'] = OpdRecordsHelper.get_label_for_opd_followup_timeframe(opdrecord.advice.opdfollowuptimeframe)
        followup_timeframe = OpdRecordsHelper.get_label_for_opd_followup_timeframe(opdrecord.advice.opdfollowuptimeframe).split(" ")
        patient_advice['followup_date'] = Date.current + followup_timeframe[0].to_i.send(followup_timeframe[1].downcase)
        patient_advice['organisation_id'] = organisation.id
        patient_advice.save()
      end
    end
  end
end
