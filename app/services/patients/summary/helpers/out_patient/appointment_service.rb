module Patients
  module Summary
    module Helpers
      module OutPatient
        class AppointmentService
          def self.call(params = {})
            appointment = Appointment.find_by(id: params[:appointment_id])
            app_list_view = AppointmentListView.find_by(appointment_id: params[:appointment_id])
            facility = Facility.find_by(id: app_list_view.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: app_list_view.facility_id, patient_id: app_list_view.patient_id })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'OPD', event_type: "Appointment", event_type_color: "354670" })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: app_list_view.appointment_id.to_s }, primary_model: "Appointment" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # SPECIALTY PARAMS
            options = options.merge({ specialty_id: appointment.specialty_id })
            # LINKS & DISPLAY FIELDS
            if ["SCHEDULED", "RESCHEDULED", "EDITED"].include?(params[:sub_event_name])
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[app_list_view.consulting_doctor_id, app_list_view.consulting_doctor]] })
              options = options.merge({ has_links: true, links: { appointment: app_list_view.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: app_list_view.appointment_date, encounter_date_time: app_list_view.appointment_start_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "ARRIVED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[app_list_view.consulting_doctor_id, app_list_view.consulting_doctor]] })
              options = options.merge({ has_links: true, links: { appointment: app_list_view.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: app_list_view.appointment_date, encounter_date_time: app_list_view.appointment_start_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "ENGAGED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[app_list_view.consulting_doctor_id, app_list_view.consulting_doctor]] })
              options = options.merge({ has_links: true, links: { appointment: app_list_view.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: app_list_view.appointment_date, encounter_date_time: app_list_view.appointment_engaged_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "COMPLETED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: app_list_view.appointment_date, encounter_date_time: app_list_view.appointment_end_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "CANCELLED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            end

            PatientSummaryTimeline.where(query: { _id: app_list_view.appointment_id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
