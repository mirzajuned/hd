module Patients
  module Summary
    module Helpers
      module OutPatient
        class WorkflowAppointmentServiceBk
          def self.call(params = {})
            workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id].to_s)
            appointment = AppointmentListView.find_by(appointment_id: params[:appointment_id].to_s)
            facility = Facility.find_by(id: workflow.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: workflow.facility_id, patient_id: workflow.patient_id })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'OPD', event_type: "Appointment", event_type_color: "354670" })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: workflow.appointment_id.to_s }, primary_model: "Appointment" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            if ["SCHEDULED", "RESCHEDULED", "EDITED"].include?(params[:sub_event_name])
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[appointment.consulting_doctor_id, appointment.consulting_doctor]] })
              options = options.merge({ has_links: true, links: { appointment: workflow.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: appointment.appointment_date, encounter_date_time: appointment.appointment_start_time, event_date_time: Time.current })

            elsif params[:sub_event_name] == "ARRIVED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[appointment.consulting_doctor_id, appointment.consulting_doctor]] })
              options = options.merge({ has_links: true, links: { appointment: workflow.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })

            elsif params[:sub_event_name] == "ENGAGED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[appointment.consulting_doctor_id, appointment.consulting_doctor]] })
              options = options.merge({ has_links: true, links: { appointment: workflow.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })

            elsif params[:sub_event_name] == "COMPLETED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })

            elsif params[:sub_event_name] == "CANCELLED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })

            elsif params[:sub_event_name] == "WORKFLOW"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[workflow.user_id, workflow.with_user]] })
              options = options.merge({ has_links: true, links: { appointment: workflow.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name]) % { user_name: workflow.with_user.to_s.upcase }], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })

            elsif params[:sub_event_name] == "AWAY"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: true, links: { appointment: workflow.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            end

            PatientSummaryTimeline.where(query: { _id: workflow.appointment_id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
