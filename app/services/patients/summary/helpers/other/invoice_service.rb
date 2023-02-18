module Patients
  module Summary
    module Helpers
      module Other
        class InvoiceService
          def self.call(params = {})
            invoice = if params[:event_name] == 'PHARMACY_RETURN' || params[:event_name] == 'OPTICAL_RETURN'
                        Inventory::Transaction::Return.find_by(id: params[:invoice_id])
                      else
                        Invoice.find_by(id: params[:invoice_id])
                      end
            facility = Facility.find_by(id: invoice.facility_id)
            options = {}
            # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: invoice.patient_id, specialty_id: invoice.specialty_id })
            # ACTUAL USER
            options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
            # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: params[:encounter_type], event_type: 'Invoice', event_type_color: 'a52a2a' })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            # QUERY PARAMETERS
            options = options.merge({ query: { _id: invoice.id.to_s }, primary_model: 'Invoice' })
            # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # LINKS
            # byebug
            if params[:is_draft]
              options = options.merge({ has_links: true, links: { invoice: invoice.attributes }, comments: [eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name] + '_DRAFT')], optionals: {} })
            elsif params[:is_converted] == false
              options = options.merge({ has_links: true, links: { invoice: invoice.attributes }, comments: [eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name] + '_CONVERTED')], optionals: {} })
            elsif params[:is_deleted]
              options = options.merge({ has_links: true, links: { invoice: invoice.attributes }, comments: [eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name])], optionals: {}, is_deleted: true })
            else
              options = options.merge({ has_links: true, links: { invoice: invoice.attributes }, comments: [eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name])], optionals: {} })
            end

            PatientSummaryTimeline.where(query: { _id: invoice.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
