module Mis::NewClinicalReports::Opd
  class AppointmentDetailsService
    class << self
      def call(appointment_list_view_id)
        list = AppointmentListView.find_by(id: appointment_list_view_id)
        apt_details = ::Mis::NewClinicalReports::StructureAppointmentDetails.call(appointment_list_view_id)
        patient_info_hash, appointment_info_hash, search_fields, filtering_fields, custom_fields, diagnoses, procedures, clinical_workflow, display_patient_role_wise_tat, patient_role_wise_tat_mins, opd_clinical_workflow_id, tat_for_appointment_common_attr, tat_for_appointment_user_role_data, patient_role_wise_tat_secs = apt_details
        appointment_details = MisClinical::Opd::ClinicalReportOpd.find_or_create_by(
          appointment_id: list[:appointment_id]
        )
        appointment_details.organisation_id = list[:organisation_id]
        appointment_details.facility_id = list[:facility_id]
        appointment_details.patient_display_fields = patient_info_hash
        appointment_details.appointment_display_fields = appointment_info_hash
        appointment_details.search_fields = search_fields
        appointment_details.filtering_fields = filtering_fields
        appointment_details.custom_fields = custom_fields
        appointment_details.diagnoses = diagnoses
        appointment_details.procedures = procedures
        appointment_details.clinical_workflow = clinical_workflow
        appointment_details.display_patient_role_wise_tat = display_patient_role_wise_tat
        appointment_details.patient_role_wise_tat_mins = patient_role_wise_tat_mins 
        appointment_details.patient_role_wise_tat_secs = patient_role_wise_tat_secs
        appointment_details.opd_clinical_workflow_id = opd_clinical_workflow_id
        appointment_details.save!
        tat_for_appointment_user_role_data.each_with_index do |tat_for_appointment_user_role, index|
          tat_appointment = MisClinical::Opd::AppointmentTurnAroundTimeData.find_or_create_by(appointment_id: tat_for_appointment_common_attr[:appointment_id], user_id: tat_for_appointment_user_role[:user_id]
          )
          tat_appointment.facility_id = tat_for_appointment_common_attr[:facility_id]
          tat_appointment.organisation_id = tat_for_appointment_common_attr[:organisation_id]
          tat_appointment.patient_visit_type_id = tat_for_appointment_common_attr[:patient_visit_type_id]
          tat_appointment.patient_visit_type = tat_for_appointment_common_attr[:patient_visit_type]

          tat_appointment.appointment_date = tat_for_appointment_common_attr[:appointment_date]
          tat_appointment.appointment_id = tat_for_appointment_common_attr[:appointment_id]
          tat_appointment.appointment_type_id = tat_for_appointment_common_attr[:appointment_type_id]
          tat_appointment.appointment_type = tat_for_appointment_common_attr[:appointment_type]

          tat_appointment.role_id = tat_for_appointment_user_role[:role_id]
          tat_appointment.role_name = tat_for_appointment_user_role[:role_name]
          tat_appointment.role_label = tat_for_appointment_user_role[:role_label]
          tat_appointment.user_id = tat_for_appointment_user_role[:user_id]
          tat_appointment.user_name = tat_for_appointment_user_role[:user_name]
          tat_appointment.display_tat = tat_for_appointment_user_role[:display_tat]
          tat_appointment.aggregated_tat_in_mins = tat_for_appointment_user_role[:aggregated_tat_in_mins]
          tat_appointment.aggregated_tat_in_secs = tat_for_appointment_user_role[:aggregated_tat_in_secs]
          tat_appointment.opd_clinical_workflow_id = tat_for_appointment_common_attr[:opd_clinical_workflow_id]
          tat_appointment.facility_name = tat_for_appointment_common_attr[:facility_name]
          tat_appointment.primary_model_id = tat_for_appointment_common_attr[:primary_model_id]
          tat_appointment.save!
        end
      end
    end
  end
end