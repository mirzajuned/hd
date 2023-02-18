module Patients
  module Summary
    module Helpers
      module InPatient
        class NursingRecordService
          def self.call(params = {})
            nursingrecord = NursingRecord.find_by(id: params[:nursing_record_id])
            admission = Admission.find_by(id: nursingrecord.admission_id)
            facility = Facility.find_by(id: nursingrecord.facility_id)
            options = {}
            # FINDERS
            options = options.merge(organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: nursingrecord.patient_id)
            # ACTUAL USER
            options = options.merge(user_id: params[:user_id], user_name: params[:user_name], users: nil)
            # DISPLAY FIELDS
            options = options.merge(facility_name: facility.try(:name), encounter_type: 'IPD', event_type: 'NURSING_RECORD', event_type_color: '354670')
            options = options.merge(encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current)
            # QUERY PARAMETERS
            template_type = if params[:templatetype] == 'pain'
                              'PAIN ASSESSMENT'
                            elsif params[:templatetype] == 'careplan'
                              'CARE PLAN'
                            else
                              params[:templatetype].upcase
                            end
            options = options.merge(query: { _id: nursingrecord.id.to_s }, primary_model: 'Inpatient::NursingRecord')
            # EVENTS AND OTHER INFO
            options = options.merge(is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil)
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge(created_by: nil, updated_by: nil)
            # DELETED FLAG, FOR DISPLAY
            options = options.merge(is_deleted: false)
            # LINKS
            options = options.merge(has_links: true, links: { nursingrecord: nursingrecord.attributes }, comments: [format(eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name]), template_type: template_type)], optionals: {})

            options = options.merge("parent_id": nursingrecord.id)

            PatientSummaryTimeline.where(query: { _id: nursingrecord.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end

          def self.assessment(params = {})
            assessment = PatientAssessment.find_by(id: params[:assessment_id])
            admission = Admission.find_by(id: assessment.admission_id)
            facility = Facility.find_by(id: admission.facility_id)
            options = {}
            # FINDERS
            options = options.merge(organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: assessment.patient_id)
            # ACTUAL USER
            options = options.merge(user_id: params[:user_id], user_name: params[:user_name], users: nil)
            # DISPLAY FIELDS
            options = options.merge(facility_name: facility.try(:name), encounter_type: 'IPD', event_type: 'NURSING_RECORD', event_type_color: '354670')
            options = options.merge(encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current)
            # QUERY PARAMETERS
            template_type = params[:templatetype].upcase
            options = options.merge(query: { _id: assessment.id.to_s }, primary_model: 'Inpatient::NursingRecord')
            # EVENTS AND OTHER INFO
            options = options.merge(is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil)
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge(created_by: nil, updated_by: nil)
            # DELETED FLAG, FOR DISPLAY
            options = options.merge(is_deleted: false)
            # LINKS
            options = options.merge(has_links: true, links: { assessment: assessment.attributes }, comments: [format(eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name]), template_type: template_type)], optionals: {})
            options = options.merge("parent_id": assessment.id)
            PatientSummaryTimeline.where(query: { _id: assessment.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end

          def self.otchecklist(params = {})
            otchecklist = OtChecklist.find_by(id: params[:ot_checklist_id])
            admission = Admission.find_by(id: otchecklist.admission_id)
            facility = Facility.find_by(id: admission.facility_id)
            options = {}
            # FINDERS
            options = options.merge(organisation_id: facility.organisation_id, facility_id: facility.id, patient_id: otchecklist.patient_id)
            # ACTUAL USER
            options = options.merge(user_id: params[:user_id], user_name: params[:user_name], users: nil)
            # DISPLAY FIELDS
            options = options.merge(facility_name: facility.try(:name), encounter_type: 'IPD', event_type: 'NURSING_RECORD', event_type_color: '354670')
            options = options.merge(encounter_date: Date.current, encounter_date_time: Time.current, event_date_time: Time.current)
            # QUERY PARAMETERS
            options = options.merge(query: { _id: otchecklist.id.to_s }, primary_model: 'Inpatient::NursingRecord')
            # EVENTS AND OTHER INFO
            options = options.merge(is_active: true, event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id], event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name], sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id], sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name], department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil)
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge(created_by: nil, updated_by: nil)
            # DELETED FLAG, FOR DISPLAY
            options = options.merge(is_deleted: false)
            # LINKS
            options = options.merge(has_links: true, links: { otchecklist: otchecklist.attributes }, comments: [format(eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name]), template_type: 'OT CHECKLIST')], optionals: {})
            options = options.merge("parent_id": otchecklist.id)
            PatientSummaryTimeline.where(query: { _id: otchecklist.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end

          def self.wardchecklist(params = {})
            wardchecklist = Inpatient::WardChecklist.find_by(id: params[:ward_checklist_id])
            admission = Admission.find_by(id: wardchecklist.admission_id)
            facility = Facility.find_by(id: admission.facility_id)
            options = {}
            # FINDERS
            options = options.merge(organisation_id: facility.organisation_id, facility_id: facility.id,
                                    patient_id: wardchecklist.patient_id)
            # ACTUAL USER
            options = options.merge(user_id: params[:user_id], user_name: params[:user_name], users: nil)
            # DISPLAY FIELDS
            options = options.merge(facility_name: facility.try(:name), encounter_type: 'IPD',
                                    event_type: 'NURSING_RECORD', event_type_color: '354670')
            options = options.merge(encounter_date: Date.current, encounter_date_time: Time.current,
                                    event_date_time: Time.current)
            # QUERY PARAMETERS
            options = options.merge(query: { _id: wardchecklist.id.to_s }, primary_model: 'Inpatient::NursingRecord')
            # EVENTS AND OTHER INFO
            options = options.merge(is_active: true,
                                    event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id],
                                    event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name],
                                    sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id],
                                    sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name],
                                    department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil)
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge(created_by: nil, updated_by: nil)
            # DELETED FLAG, FOR DISPLAY
            options = options.merge(is_deleted: false)
            # LINKS
            options = options.merge(has_links: true, links: { wardchecklist: wardchecklist.attributes },
                                    comments: [format(eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name]),
                                                      template_type: 'WARD CHECKLIST')], optionals: {})
            options = options.merge("parent_id": wardchecklist.id)
            PatientSummaryTimeline.where(query: { _id: wardchecklist.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end

          def self.pre_anaesthesia_note(params = {})
            pre_anaesthesia_note_id = Inpatient::PreAnaesthesiaNote.find_by(id: params[:pre_anaesthesia_note_id])
            admission = Admission.find_by(id: pre_anaesthesia_note_id.admission_id)
            facility = Facility.find_by(id: admission.facility_id)
            options = {}
            # FINDERS
            options = options.merge(organisation_id: facility.organisation_id, facility_id: facility.id,
                                    patient_id: pre_anaesthesia_note_id.patient_id)
            # ACTUAL USER
            options = options.merge(user_id: params[:user_id], user_name: params[:user_name], users: nil)
            # DISPLAY FIELDS
            options = options.merge(facility_name: facility.try(:name), encounter_type: 'IPD',
                                    event_type: 'NURSING_RECORD', event_type_color: '354670')
            options = options.merge(encounter_date: Date.current, encounter_date_time: Time.current,
                                    event_date_time: Time.current)
            # QUERY PARAMETERS
            options = options.merge(query: { _id: pre_anaesthesia_note_id.id.to_s }, primary_model: 'Inpatient::NursingRecord')
            # EVENTS AND OTHER INFO
            options = options.merge(is_active: true,
                                    event_id: eval("Patients::Summary::Events::#{params[:event_name]}")[:id],
                                    event_name: eval("Patients::Summary::Events::#{params[:event_name]}")[:name],
                                    sub_event_id: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:id],
                                    sub_event_name: eval("Patients::Summary::SubEvents::#{params[:sub_event_name]}")[:name],
                                    department_name: facility.department_ids[0], sub_department_name: nil, sub_speciality_name: nil)
            # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
            options = options.merge(created_by: nil, updated_by: nil)
            # DELETED FLAG, FOR DISPLAY
            options = options.merge(is_deleted: false)
            # LINKS
            options = options.merge(has_links: true, links: { pre_anaesthesia_note_id: pre_anaesthesia_note_id.attributes },
                                    comments: [format(eval('Global.patient_summary_timeline.' + params[:event_name] + '_' + params[:sub_event_name]),
                                                      template_type: 'PRE ANAESTHESIA NOTE')], optionals: {})
            options = options.merge("parent_id": pre_anaesthesia_note_id.id)
            PatientSummaryTimeline.where(query: { _id: pre_anaesthesia_note_id.id.to_s }).update_all(is_active: false)
            Patients::Summary::TimelineService.call(options)
          end
        end
      end
    end
  end
end
