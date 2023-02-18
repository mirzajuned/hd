module Patients
  module Summary
    module Helpers
      module Other
        class PatientService
          def self.call(params = {})
            # patient = Patient.find_by(id: params[:patient_id])
            # facility = Facility.find_by(id: appointment.facility_id)
            # options = { organisation_id: facility.organisation_id, facility_id: appointment.facility_id, patient_id: appointment.patient_id, user_id: nil, user_name: nil, users: nil, facility_name: facility.try(:name), encounter_type: 'OPD', encounter_date: appointment.appointment_date, encounter_date_time: appointment.appointment_start_time, query: { _id: patient.id }, primary_model: "Patient", optionals: {}, comments: [eval("Global.patient_summary_timeline." + params[:event_name] + "_" + params[:sub_event_name] ) % { :facility_name => facility.try(:name), :date => appointment.appointment_date.strftime("%d %b'%y"), :time => appointment.appointment_start_time.try(:strftime, '%I:%M %p') }], event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil, created_by: nil, updated_by: nil, is_deleted: false, has_links: true, links: { :PATIENT_EDIT_LINK => { :id => patient.id }}})
            # Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
