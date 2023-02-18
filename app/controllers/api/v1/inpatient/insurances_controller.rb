module Api
  module V1
    class Inpatient::InsurancesController < ApiApplicationController
      before_action :authorize
      before_action :inpatient_insurance_tpa, only: [:show, :edit, :update]

      def new
        # New Created While Creating Admission Refer ipd_patient_controller -> action admission_done
      end

      def show
        respond_to do |format|
          format.js { render "inpatient/insurance/show", :layout => false }
        end
      end

      def edit
        respond_to do |format|
          format.js { render "inpatient/insurance/edit", :layout => false }
        end
      end

      def update
        if @tpa.update_attributes(tpa_params)
          if @tpa.is_insured?
            Admission.find_by(id: @tpa.admission_id).update_attributes(insurance_status: @tpa.insurance_status)
            respond_to do |format|
              format.js { render "inpatient/insurance/show", :layout => false }
            end
          else
            Admission.find_by(id: @tpa.admission_id).update_attributes(insurance_status: "Not Insured")
            respond_to do |format|
              format.js { render "inpatient/insurance/close", :layout => false }
            end
          end
        else
          respond_to do |format|
            format.js { render "inpatient/insurance/edit", :layout => false }
          end
        end
      end

      private

      def tpa_params
        params.require(:inpatient_insurance_tpa).permit(:is_insured, :insurance_name, :tpa_name, :tpa_contact_no, :policy_no, :insurer, :company_name, :employee_id, :insurance_status, :comment, :approved_amount, :bracket_amount, :patient_id, :admission_id, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form)
      end

      def inpatient_insurance_tpa
        @tpa = Inpatient::Insurance::Tpa.find_by(:id => params[:id])
      end
    end
  end
end
