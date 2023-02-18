module Patients
  module Summary
    module Helpers
      module InPatient
        class ClinicalNoteService
          def self.call(params = {})
            ipdrecord = Inpatient::IpdRecord::ClinicalNote.find_by(id: params[:ipd_record_id])
            admission = Admission.find_by(id: ipdrecord.admission_id)
            facility = Facility.find_by(id: admission.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: ipdrecord.patient_id })
            # ACTUAL USER
            options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'OPD' })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: ipdrecord.id }, primary_model: "Inpatient::IpdRecord::ClinicalNote" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            options = options.merge({ has_links: false, links: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name]) % { :template_type => ipdrecord.template_type, :user_name => params[:user_name], :date => Date.current.strftime("%d %b'%y"), :time => Time.current.strftime("%I:%M %p") }], optionals: {} })
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
