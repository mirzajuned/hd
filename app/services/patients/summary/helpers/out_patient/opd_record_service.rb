module Patients
  module Summary
    module Helpers
      module OutPatient
        class OpdRecordService
          def self.call(params = {})
            opdrecord = OpdRecord.find_by(id: params[:opd_record_id])
            appointment = Appointment.find_by(id: opdrecord.appointmentid)
            facility = Facility.find_by(id: appointment.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: opdrecord.patientid })
            # SPECIALTY PARAMS
            options = options.merge({ specialty_id: appointment.specialty_id })
            # ACTUAL USER
            if ['optometrist', 'refraction', 'vision', 'biometry'].include?(opdrecord.templatetype)
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users:  [[opdrecord.optometrist_id, opdrecord.optometrist_name]] })
            elsif opdrecord.templatetype == 'nursing'
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users:  [[opdrecord.nurse_id, opdrecord.nurse_name]] })
            elsif opdrecord.templatetype == 'ar_nct'
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users:  [[opdrecord.ar_nct_id, opdrecord.ar_nct_name]] })
            else
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users:  [[opdrecord.consultant_id, opdrecord.consultant_name]] })
            end
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'OPD', event_type: "OPD_RECORD", event_type_color: "fed136" })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: opdrecord.id.to_s }, primary_model: "OpdRecord" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            options = options.merge({ has_links: true, links: { opdrecord: opdrecord.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name]) % { template_type: opdrecord.templatetype.to_s.upcase }], optionals: {} })

            PatientSummaryTimeline.where(query: { _id: opdrecord.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
