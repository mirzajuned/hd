module Api
  module V1
    module Silfra
      class MedicationPrescriptionsController < ApiApplicationController
        def view_medication_prescription
          @patient_id = params[:patient_id]
          if @patient_id.present?
            @prescriptions = PatientPrescription.where(patient_id: @patient_id.to_s).order(created_at: :desc)
          end
        end
      end
    end
  end
end
