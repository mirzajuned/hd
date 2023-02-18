module PatientTimelines
  module CreateService
    def self.call(opdrecord)
      appointment = Appointment.find_by(id: opdrecord.try(:appointmentid))
      if appointment.present?
        facility = Facility.find_by(id: appointment.facility_id)
        organisation = facility.organisation

        if facility.clinical_workflow
          workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
          consultant_id = User.find_by(:id => workflow.consultant_ids.last)
        else
          consultant_id = User.find_by(:id => appointment.consultant_id.to_s)
        end

        username = User.find_by(id: opdrecord.record_histories[0].user_id)

        PatientTimeline.where(record_id: opdrecord.id, patient_id: opdrecord.patientid).try(:destroy_all)

        patient_timeline = PatientTimeline.new()
        patient_timeline['consultant_name'] = consultant_id.fullname
        patient_timeline['consultant'] = appointment.consultant_id.to_s
        patient_timeline['user_id'] = username.try(:id)
        patient_timeline['user_name'] = username.try(:fullname)
        patient_timeline['facility_id'] = facility.id
        patient_timeline['facility_name'] = facility.name
        patient_timeline['patient_id'] = opdrecord.patientid
        patient_timeline['record_id'] = opdrecord.id
        patient_timeline['encountertype'] = opdrecord.encountertype
        patient_timeline['encountertypeid'] = opdrecord.encountertypeid
        patient_timeline['appointment_id'] = opdrecord.appointmentid
        patient_timeline['templatetype'] = opdrecord.templatetype
        patient_timeline['templateid'] = opdrecord.templateid
        patient_timeline['specalityid'] = opdrecord.specalityid
        patient_timeline['specalityname'] = opdrecord.specalityname
        patient_timeline['encounterdate'] = opdrecord.created_at
        patient_timeline['authorid'] = opdrecord.authorid
        patient_timeline.save()
      end
    end
  end
end
