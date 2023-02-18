# rubocop:disable all
module Mis::NewClinicalReports
  class StructureAppointmentDetails
    class << self
      # rubocop:disable Layout/LineLength
      def call(appointment_list_view_id)
        list = AppointmentListView.find_by(id: appointment_list_view_id)
        mis_logger = Logger.new("#{Rails.root}/log/mis_patient_details_logger.log")
        appointment_info_started = Time.current
        patient = Patient.find_by(id: list&.patient_id)
        opd_visit_count = patient&.opd_visit_count.to_i
        appointment_id = list&.appointment_id
        appointment = Appointment.find_by(id: appointment_id)
        case_sheet_id = "#{appointment&.case_sheet_id}"
        case_sheet_obj = CaseSheet.find_by(id: case_sheet_id)
        opd_record = OpdRecord.find_by(appointmentid: appointment_id.to_s)
        patient_last_appointment = Appointment.where(patient_id: patient&.id.to_s).last&.appointmentdate
        patient_last_admission = Admission.where(patient_id: patient&.id.to_s).last&.admissiondate
        is_post_op = if patient_last_appointment.present? && patient_last_admission.present?
                       patient_last_admission > patient_last_appointment
                     else
                       false
                     end
        patient_visit, patient_visit_type_id, patient_visit_type = if is_post_op && opd_visit_count >= 1
                                                                      ['Post Op', Global.patient.common.postop.id, "#{Global.patient.common.postop.displayname}"]
                                                                   elsif opd_visit_count >= 2 && is_post_op == false
                                                                      ['Followup', Global.patient.common.followup.id, "#{Global.patient.common.followup.displayname}"]
                                                                   else
                                                                      ['New', Global.patient.common.new.id, "#{Global.patient.common.new.displayname}"]
                                                                   end
        appointment_type_id, appointment_type = if list&.appointmenttype == "appointment"
                                                  [Global.opd.common.appointment.id, "#{Global.opd.common.appointment.displayname}"]
                                                else
                                                  [Global.opd.common.walkin.id, "#{Global.opd.common.walkin.displayname}"]
                                                end
        # Patient Referral - will be pushed inside patient_info_hash and then patient_display_fields                
        patient_referral = PatientReferralType.find_by(patient_id: patient.try(:id).to_s)
        patient_referral_type_id = patient_referral&.referral_type_id
        patient_referral_type = ReferralType.find_by(id: patient_referral_type_id)&.try(:name)
        patient_sub_referral_type_id = patient_referral&.sub_referral_type.try(:id)
        patient_sub_referral_type_name = patient_referral&.sub_referral_type.try(:name)
        
        # Appointment Referral - will be pushed inside appointment_info_hash and then appointment_display_fields
        appointment_referral = PatientReferralType.find_by(appointment_id: appointment_id)
        appointment_referral_type_id = appointment_referral&.referral_type_id || patient_referral_type_id
        appointment_referral_type = ReferralType.find_by(id: appointment_referral_type_id)&.try(:name) || patient_referral_type
        appointment_sub_referral_type_id = appointment_referral&.sub_referral_type.try(:id) || patient_sub_referral_type_id
        appointment_sub_referral_type_name = appointment_referral&.sub_referral_type.try(:name) || patient_sub_referral_type_name
        
        patient_name = patient&.fullname
        patient_display_id = patient&.patient_identifier_id
        patient_mr_no = patient&.patient_mrn
        patient_age = patient&.age
        age = patient&.age.present? ? (patient&.age || patient&.age.to_i) : nil
        # age = (patient&.age.present?) ? patient&.age : ((patient&.dob_year.present? && patient&.dob_year.to_i > 0) ? (Date.current.year - patient&.dob_year.to_i) : nil)
        patient_gender = patient&.gender
        patient_type = list&.patient_type
        consulting_doctor = list&.consulting_doctor
        appointment_display_id = appointment&.display_id
        scheduled_date = list&.scheduled_date
        scheduled_time = list&.scheduled_time
        patient_mobilenumber = list&.patient_mobilenumber
        current_state = list&.current_state
        commune = list&.commune
        district = list&.district
        state = list&.state
        pincode = list&.pincode
        city = list&.city
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        appointment_date = list&.appointment_date
        appointment_datetime = list&.appointment_date
        appointmenttype = list&.appointmenttype
        facility_id = list&.facility_id
        facility = Facility.find_by(id: facility_id)
        facility_name = facility.try(:name)
        facility_qm = facility.try(:facility_setting).try(:queue_management) || false
        organisation_id = list&.organisation_id
        organisation = Organisation.find_by(id: organisation_id)
        organisation_name = organisation.try(:name)
        workflow_waiting_disable = organisation.try(:workflow_waiting_disable) || false
        appointment_start_time = list&.appointment_start_time
        appointment_end_time = list&.appointment_end_time
        appointment_type = list&.appointment_type
        patient_visit = patient_visit
        appointment_engaged_time = list&.appointment_engaged_time
        total_time = Mis::ClinicalService::AppointmentReportConverter.get_total_time(appointment_id) # TODO: calculate total time
        waiting_time = nil # Mis::ClinicalService::AppointmentReportConverter.get_waiting_time(appointment_id) # todo waiting time
        engaged_time =  nil # Mis::ClinicalService::AppointmentReportConverter.get_engaged_time(appointment_id) # todo calculate enagaged time
        other_doctors = Mis::ClinicalService::AppointmentReportConverter.get_other_doctors(appointment_id) # TODO: calculate other doctors by taking appointment_id
        other_users = Mis::ClinicalService::AppointmentReportConverter.get_other_users(appointment_id) # TODO: get other users
        doctor_ids = Mis::ClinicalService::AppointmentReportConverter.get_doctor_ids(appointment_id)
        patient_info_hash = { patient_name: patient_name, patient_display_id: patient_display_id,
                              patient_mr_no: patient_mr_no, patient_age: patient_age, age: age,
                              patient_gender: patient_gender, patient_type: patient_type,
                              patient_mobilenumber: patient_mobilenumber, 
                              patient_visit: patient_visit, commune: commune, district: district, 
                              state: state, pincode: pincode, city: city,
                              location_id: location_id, area_manager_id: area_manager_id,
                              area_manager_name: area_manager_name,
                              referral_type_id: patient_referral_type_id, 
                              referral_type: patient_referral_type,
                              sub_referral_type_id: patient_sub_referral_type_id, 
                              sub_referral_type_name: patient_sub_referral_type_name }
        appointment_info_hash = { consulting_doctor: consulting_doctor, 
                                  appointment_display_id: appointment_display_id,
                                  scheduled_date: scheduled_date, scheduled_time: scheduled_time,
                                  current_state: current_state, appointment_date: appointment_date,
                                  appointmenttype: appointmenttype, facility_id: facility_id, 
                                  facility_name: facility_name,
                                  appointment_start_time: appointment_start_time,
                                  appointment_end_time: appointment_end_time, 
                                  appointment_type: appointment_type,
                                  appointment_engaged_time: appointment_engaged_time, 
                                  total_time: total_time, organisation_id: organisation_id, 
                                  organisation_name: organisation_name,
                                  waiting_time: waiting_time, engaged_time: engaged_time, 
                                  other_doctors: other_doctors, other_users: other_users, 
                                  referral_type_id: appointment_referral_type_id, 
                                  referral_type: appointment_referral_type, 
                                  sub_referral_type_id: appointment_sub_referral_type_id,
                                  sub_referral_type_name: appointment_sub_referral_type_name,
                                  opd_record_id: opd_record.try(:id), 
                                  appointment_id: appointment_id }
        appointment_info_ended = Time.current
        # Get diagnoses for the appointment from Casesheet
        casesheet_by_diagnosis = casesheet_by_procedure = nil
        diagnoses = procedures = []
        if case_sheet_obj.present?
          casesheet_by_diagnosis = case_sheet_obj.diagnoses.where(appointment_id: "#{appointment&.id}") if case_sheet_obj.diagnoses.present?
          casesheet_by_diagnosis&.each do |diagnosis|
            diagnoses.push({
              diagnosis_name: diagnosis[:diagnosisname].titleize, 
              originalname: diagnosis[:diagnosisoriginalname],
              diagnosis_code: diagnosis[:icddiagnosiscode]
            })
          end
          # # Get procedures for the appointment from Casesheet
          casesheet_by_procedure = case_sheet_obj.procedures.where(appointment_id: "#{appointment[:id]}") if case_sheet_obj.procedures.present?
          casesheet_by_procedure&.each do |procedure|
            procedure_laterality_arr = compute_laterality("#{procedure[:procedureside]}")
            procedure_side = procedure_laterality_arr[2]
            procedure_name = procedure[:procedurename]
            procedures.push({
              procedure_name: procedure_name,
              procedure_side: procedure_side
            })
          end
        end

        clinical_workflow_started = Time.current
        clinical_workflow = []
        opd_clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: "#{appointment[:id]}")
        opd_clinical_workflow_id = opd_clinical_workflow.try(:id)
        transitions = opd_clinical_workflow.opd_clinical_workflow_state_transitions.pluck(:user_id, :from, :to, :transition_start, :transition_end, :department_id, :state_type, :station_id, :station_name, :station_code, :sub_station_id, :sub_station_code, :area_id, :with_user) rescue []
        clinical_workflow = Mis::OperationalReports::Opd::PatientVisitSummaryTatService.call(opd_clinical_workflow, transitions) if transitions.size > 0
        clinical_workflow_ended = Time.current
        
        display_patient_role_wise_tat = patient_role_wise_tat_mins = patient_role_wise_tat_secs = {}
        time_difference_proc = Proc.new { |arr| TimeDifference.between(arr[4], arr[3]).in_minutes }
        display_patient_role_wise_tat, patient_role_wise_tat_mins, patient_role_wise_tat_secs = Mis::OperationalReports::Opd::PatientVisitSummaryRoleTatService.call(opd_clinical_workflow, transitions, time_difference_proc) if transitions.size > 0
        tat_for_appointment_common_attr = {}
        tat_for_appointment_user_role_data = []
        tat_for_appointment_common_attr[:patient_visit_type_id] = patient_visit_type_id
        tat_for_appointment_common_attr[:patient_visit_type] = patient_visit_type
        tat_for_appointment_common_attr[:appointment_id] = appointment_id
        tat_for_appointment_common_attr[:appointment_date] = appointment_date
        tat_for_appointment_common_attr[:appointment_type_id] = appointment_type_id
        tat_for_appointment_common_attr[:appointment_type] = appointment_type
        tat_for_appointment_common_attr[:opd_clinical_workflow_id] = opd_clinical_workflow_id
        tat_for_appointment_common_attr[:primary_model_id] = opd_clinical_workflow_id
        tat_for_appointment_common_attr[:facility_id] = facility_id
        tat_for_appointment_common_attr[:facility_name] = facility_name
        tat_for_appointment_common_attr[:organisation_id] = organisation_id
        tat_for_appointment_user_role_data = Mis::OperationalReports::Opd::AppointmentTatUserRoleService.call(opd_clinical_workflow, transitions, time_difference_proc, workflow_waiting_disable, facility_qm) if transitions.size > 0
        
        search_fields = { patient_name: patient_name, patient_mobilenumber: patient_mobilenumber }
        filtering_fields = { organisation_id: organisation_id, appointment_date: appointment_date,
                             facility_id: facility_id, appointmenttype: appointmenttype,
                             appointment_type: appointment_type, patient_gender: patient_gender, 
                             age: age, commune: commune, district: district, state: state, 
                             pincode: pincode, city: city, location_id: location_id, 
                             area_manager_id: area_manager_id, area_manager_name: area_manager_name,
                             doctor_ids: doctor_ids, patient_visit: patient_visit, 
                             patient_referral_type_id: patient_referral_type_id,
                             appointment_referral_type_id: appointment_referral_type_id, 
                             referral_type_id: patient_referral_type_id,
                             appointment_start_time: appointment_start_time, 
                             appointment_referral_type: appointment_referral_type,
                             patient_referral_type: patient_referral_type }
        custom_fields = {}
        [ patient_info_hash, appointment_info_hash, search_fields, filtering_fields, custom_fields, diagnoses, procedures, clinical_workflow, display_patient_role_wise_tat, patient_role_wise_tat_mins, opd_clinical_workflow_id, tat_for_appointment_common_attr, tat_for_appointment_user_role_data, patient_role_wise_tat_secs ]
      # rescue StandardError => e
      #   mis_logger.info(" === Error in StructureAppointmentDetails while importing appointment details data: #{e.inspect}")
      end

      def compute_laterality(procedure_laterality_code)
        if procedure_laterality_code == "18944008"
          return ["r", "R", "Right"]
        elsif procedure_laterality_code == "8966001"
          return ["l", "L", "Left"]
        else
          return ["", "", ""]
        end
      end
    end
  end
end
