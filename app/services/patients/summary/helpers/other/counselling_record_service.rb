module Patients
  module Summary
    module Helpers
      module Other
        class CounsellingRecordService
          def self.call(params = {})
            counselling_record = Order::CounsellingRecord.find_by(id: params[:counselling_record_id])
            appointment = Appointment.find_by(id: counselling_record.appointment_id)
            facility = Facility.find_by(id: counselling_record.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: counselling_record.patient_id, specialty_id: counselling_record.specialty_id })
            # ACTUAL USER
            options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'OPD', event_type: "COUNSELLING_RECORD", event_type_color: "fed136" })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: counselling_record.id.to_s }, primary_model: "Order::CounsellingRecord" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            options = options.merge({ has_links: true, links: { counselling_record: counselling_record.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })

            PatientSummaryTimeline.where(query: { _id: counselling_record.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
