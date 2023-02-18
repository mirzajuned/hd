module Patients
  module Summary
    class TimelineWorker
      def self.call(params = {})
        if params[:event_name] == 'OPD_APPOINTMENT'
          if params[:workflow] == true
            Patients::Summary::Helpers::OutPatient::WorkflowAppointmentService.new(params).call
          else
            Patients::Summary::Helpers::OutPatient::AppointmentService.call(params)
          end
        elsif params[:event_name] == 'OPD_RECORD'
          Patients::Summary::Helpers::OutPatient::OpdRecordService.call(params)
        elsif params[:event_name] == 'IPD_ADMISSION'
          Patients::Summary::Helpers::InPatient::IpdAdmissionService.call(params)
        elsif params[:event_name] == 'IPD_OT'
          Patients::Summary::Helpers::InPatient::IpdOtService.call(params)
        elsif params[:event_name] == 'IPD_DISCHARGE'
          Patients::Summary::Helpers::InPatient::IpdDischargeService.call(params)
        elsif params[:event_name] == 'IPD_RECORD'
          Patients::Summary::Helpers::InPatient::IpdRecordService.call(params)
        elsif params[:event_name] == 'UPLOAD'
          Patients::Summary::Helpers::Other::UploadService.call(params)
        elsif ['IPD_ADVANCE', 'OPD_ADVANCE', 'OPTICAL_ADVANCE', 'PHARMACY_ADVANCE'].include?(params[:event_name])
          Patients::Summary::Helpers::Other::AdvanceService.call(params)
        elsif params[:event_name] == 'IPD_INVOICE'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'OPD_INVOICE'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'OPTICAL_INVOICE'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'PHARMACY_INVOICE'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'OPTICAL_RETURN'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'PHARMACY_RETURN'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'INSURANCE_INVOICE'
          Patients::Summary::Helpers::Other::InvoiceService.call(params)
        elsif params[:event_name] == 'CERTIFICATE'
          Patients::Summary::Helpers::Other::CertificateService.call(params)
        elsif params[:event_name] == 'PATIENT_REFERENCE'
          Patients::Summary::Helpers::Other::ReferralService.call(params)
        elsif params[:event_name] == 'COUNSELLOR_RECORD'
          Patients::Summary::Helpers::Other::CounsellorRecordService.call(params)
        elsif params[:event_name] == 'COUNSELLING_RECORD'
          Patients::Summary::Helpers::Other::CounsellingRecordService.call(params)
        elsif params[:event_name] == 'NURSING_RECORD'
          if params[:templatetype] == 'assessment'
            Patients::Summary::Helpers::InPatient::NursingRecordService.assessment(params)
          elsif params[:templatetype] == 'otchecklist'
            Patients::Summary::Helpers::InPatient::NursingRecordService.otchecklist(params)
          elsif params[:templatetype] == 'ward_checklist'
            Patients::Summary::Helpers::InPatient::NursingRecordService.wardchecklist(params)
          elsif params[:templatetype] == 'pre_anaesthesia_note'
            Patients::Summary::Helpers::InPatient::NursingRecordService.pre_anaesthesia_note(params)
          else
            Patients::Summary::Helpers::InPatient::NursingRecordService.call(params)
          end
        end
      end
    end
  end
end
