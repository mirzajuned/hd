module Patients
  module Summary
    module Helpers
      module InPatient
        class IpdRecordService
          def self.call(params = {})
            ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ipd_record_id])
            admission = Admission.find_by(id: ipdrecord.admission_id)
            facility = Facility.find_by(id: admission.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: ipdrecord.patient_id, specialty_id: admission.specialty_id })
            # ACTUAL USER
            options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'IPD', event_type: "IPD_RECORD", event_type_color: "354670" })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            # QUERY PARAMETERS
            if params[:ipdtemplatetype] == 'clinical_note'
              note = ipdrecord.clinical_note
            elsif params[:ipdtemplatetype] == "Operative Note"
              note = ipdrecord.operative_notes.find_by(id: params[:note_id])
            elsif params[:ipdtemplatetype] == "Discharge Note"
              note = ipdrecord.discharge_note
            elsif params[:ipdtemplatetype] == "Ward Note"
              note = ipdrecord.ward_notes.find_by(id: params[:note_id])
            elsif params[:ipdtemplatetype] == 'Bom Note'
              note = Inpatient::BillOfMaterial.find_by(id: params[:bom_id])
            end
            options = options.merge({ query: { _id: note.id.to_s }, primary_model: "Inpatient::IpdRecord" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            unless params[:ipdtemplatetype] == "clinical_note"
              template_type = params[:ipdtemplatetype].to_s.upcase
            else
              template_type = "ADMISSION NOTE"
            end
            options = options.merge({ has_links: true, links: { ipdrecord: note.attributes }, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name]) % { template_type: template_type }], optionals: {}, template_type: template_type })
            options = options.merge("parent_id": ipdrecord.id)

            PatientSummaryTimeline.where(query: { _id: note.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
