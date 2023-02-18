module Patients
  module Summary
    module Helpers
      module Other
        class AdvanceService
          def self.call(params = {})
          	advance_payment = AdvancePayment.find_by(id: params[:advance_payment_id])
            facility = Facility.find_by(id: advance_payment.facility_id)
            options = {}
            # # FINDERS
            options = options.merge({ organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: advance_payment.patient_id, specialty_id: advance_payment.specialty_id })
            # # ACTUAL USER
            options = options.merge({ user_id: params[:user_id], user_name: params[:user_name], users: nil })
            # # DISPLAY FIELDS
            options = options.merge({ facility_name: facility.try(:name), encounter_type: params[:encounter_type], event_type: 'Advance', event_type_color: 'a52a2a' })
            options = options.merge({ encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current })
            # # QUERY PARAMETERS
            options = options.merge({ query: { _id: advance_payment.id.to_s }, primary_model: 'AdvancePayment' })
            # # EVENTS AND OTHER INFO
            options = options.merge({ is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil })
            # # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge({ created_by: nil, updated_by: nil })
            # # DELETED FLAG, FOR DISPLAY
            options = options.merge({ is_deleted: false })
            # # LINKS
            # # byebug
            options = options.merge({ has_links: true, links: { advance_payment: advance_payment.attributes }, comments: [eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name])], optionals: {} })
            PatientSummaryTimeline.where(query: { _id: advance_payment.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
