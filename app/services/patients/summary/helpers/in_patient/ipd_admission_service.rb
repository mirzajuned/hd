module Patients
  module Summary
    module Helpers
      module InPatient
        class IpdAdmissionService
          def self.call(params = {})
            adm_list_view = AdmissionListView.find_by(admission_id: params[:admission_id])
            admission = Admission.find_by(id: params[:admission_id])
            facility = Facility.find_by(id: adm_list_view.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: adm_list_view.facility_id, patient_id: adm_list_view.patient_id })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'IPD', event_type: "ADMISSION", event_type_color: "800080" })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: adm_list_view.admission_id.to_s }, primary_model: "Admission" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # SPECIALTY FIELD
            options = options.merge({ specialty_id: admission.specialty_id })
            # LINKS & DISPLAY FIELDS
            if ["SCHEDULED", "EDITED"].include?(params[:sub_event_name])
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[adm_list_view.admitting_doctor_id, adm_list_view.admitting_doctor]] })
              options = options.merge({ has_links: true, links: { admission: adm_list_view.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              if params[:sub_event_name] == "EDITED" && adm_list_view.current_state != "Scheduled"
                options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
              else
                options = options.merge({ encounter_date: adm_list_view.admission_date, encounter_date_time: adm_list_view.admission_time, event_date_time: Time.current })
              end
            elsif params[:sub_event_name] == "ADMITTED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: [[adm_list_view.admitting_doctor_id, adm_list_view.admitting_doctor]] })
              options = options.merge({ has_links: true, links: { admission: adm_list_view.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: adm_list_view.admission_date, encounter_date_time: adm_list_view.admission_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "DISCHARGED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: true, links: { admission: adm_list_view.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: adm_list_view.discharge_date, encounter_date_time: adm_list_view.discharge_time, event_date_time: Time.current })
            elsif params[:sub_event_name] == "CANCELLED"
              options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
              options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name])], optionals: {} })
              options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            end

            PatientSummaryTimeline.where(query: { _id: adm_list_view.admission_id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
