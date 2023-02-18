module Mis::RevenueReports
  class UpdatePatientService
    class << self
      def call(patient_id, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        mis_revenue_with_patient = Finance::ReportData.where(:'patient_display_fields.patient_id' => patient_id)
        patient = Patient.find_by(id: patient_id)
        mis_logger.info(" ======= #{mis_revenue_with_patient.count} revenue report data found with patient id: #{patient_id}")
        if mis_revenue_with_patient.count > 0 && patient.present?
          patient_name = patient.fullname
          age = (patient.age.present? && patient.age > 0) ? patient.age : patient.exact_age
          patient_hash = {
            'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 'gender': patient.gender,
            'patient_identifier_id': patient.patient_identifier_id, 'patient_mrn': patient.patient_mrn
          }
          mis_revenue_with_patient.update_all(patient_display_fields: patient_hash)
        else
          mis_logger.info("Patient not found with id: #{patient_id}")
        end
      # rescue StandardError => e
      #   mis_logger.error(" === error in UpdatePatientService :: #{e.inspect}")
      end
    end
  end
end
