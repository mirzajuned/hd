module Patients
  module Summary
    module Helpers
      module Other
        class UploadService
          def self.call(params = {})
            asset = PatientSummaryAssetUpload.find_by(id: params[:asset_id])
            facility = Facility.find_by(id: params[:facility_id])
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: asset.patient_id, specialty_id: asset.specialty_id })
            # ACTUAL USER
            options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: 'Upload', event_type: "Upload", event_type_color: "f00" })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: asset.id.to_s }, primary_model: "PatientSummaryAssetUpload" })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            options = options.merge({ has_links: true, links: { asset: asset.attributes }, comments: [(eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name]) % { file_type: ('"' + asset.name.to_s.upcase + '"' if asset.name.present?) || '' }).strip], optionals: {} })

            PatientSummaryTimeline.where(query: { _id: asset.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
