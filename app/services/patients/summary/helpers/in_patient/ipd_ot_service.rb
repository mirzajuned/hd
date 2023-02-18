module Patients
  module Summary
    module Helpers
      module InPatient
        class IpdOtService
          def self.call(params = {})
            ot = OtListView.find_by(ot_id: params[:ot_id])
            ot_schedule = OtSchedule.find_by(id: params[:ot_id])
            facility = Facility.find_by(id: ot.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: ot.facility_id, patient_id: ot.patient_id })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'IPD', event_type: "OT", event_type_color: "0f0" })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: ot.ot_id.to_s }, primary_model: "Ot" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # SPECIALTY FIELD
            options = options.merge({ specialty_id: ot_schedule.specialty_id })
            # LINKS & DISPLAY FIELDS
            if ["SCHEDULED", "RESCHEDULED"].include?(params[:sub_event_name])
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[ot.operating_doctor_id, ot.operating_doctor]] })
              options = options.merge({ has_links: true, links: { ot: ot.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: ot.ot_date, encounter_date_time: ot.ot_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "ENGAGED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[ot.operating_doctor_id, ot.operating_doctor]] })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            elsif params[:sub_event_name] == "COMPLETED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            elsif params[:sub_event_name] == "CANCELLED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            elsif params[:sub_event_name] == "LINKED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[ot.operating_doctor_id, ot.operating_doctor]] })
              options = options.merge({ has_links: true, links: { ot: ot.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            elsif params[:sub_event_name] == "UNLINKED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[ot.operating_doctor_id, ot.operating_doctor]] })
              options = options.merge({ has_links: true, links: { ot: ot.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            end

            PatientSummaryTimeline.where(query: { _id: ot.ot_id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
