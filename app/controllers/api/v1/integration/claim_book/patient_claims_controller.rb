module Api::V1::Integration::ClaimBook
  class PatientClaimsController < ApiApplicationController
    respond_to :json
    before_action :doorkeeper_authorize!
    after_action :create_data_request, :create_data_response

    def register_case
      set_patient
      set_facility
      set_admission

      @room_type = Room.find_by(id: @admission.room_id)&.type
      @doctor = User.find_by(id: @admission.doctor)
      @case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
      @diagnoses = @case_sheet.diagnoses.group_by(&:icddiagnosiscode)

      template = 'api/v1/integration/claim_book/patient_claims/register_case.json.jbuilder'
      @data_hash = JSON.parse(render_to_string(template: template, format: :json))

      render json: @data_hash
    rescue StandardError => e
      message = e.try(:message) || 'Invalid Request'

      @data_hash = { status_code: 400, message: message }

      render json: @data_hash
    end

    def update_case_status
      set_patient
      set_facility
      set_admission

      @admission.update!(insurance_status: params[:state])

      @data_hash = { status_code: 200, message: 'Case Status Updated Successfully.' }

      render json: @data_hash
    rescue StandardError => e
      message = e.try(:message) || 'Invalid Request'

      @data_hash = { status_code: 400, message: message }

      render json: @data_hash
    end

    private

    def set_patient
      @patient_other_identifier = PatientOtherIdentifier.find_by(mr_no: params[:mrn])
      @patient = Patient.find_by(id: @patient_other_identifier&.patient_id)
      raise Errors::FindByNil.new('Patient', 'mrn') if @patient_other_identifier.nil?
    end

    def set_facility
      @facility = Facility.find_by(abbreviation: params[:hospitalCode], :organisation_id.in => @patient.reg_hosp_ids)
      raise Errors::FindByNil.new('Facility', 'hospitalCode') if @facility.nil?
    end

    def set_admission
      @admission = Admission.find_by(patient_id: @patient.id, display_id: params[:caseID])
      raise Errors::FindByNil.new('Admission', 'caseId') if @admission.nil?
    end

    def create_data_request
      organisation_id = @patient.reg_hosp_ids[0] if @patient.present?
      facility_id = @facility&.id
      url = "#{params[:controller]}/#{params[:action]}"
      data_hash = params[:patient_claim].permit!.to_hash

      ApiIntegration::DataRequests::CreateService.call(data_hash, url, 'received', organisation_id, facility_id, {})
    end

    def create_data_response
      organisation_id = @patient.reg_hosp_ids[0] if @patient.present?
      facility_id = @facility&.id
      url = "#{params[:controller]}/#{params[:action]}"

      ApiIntegration::DataResponses::CreateService.call(@data_hash, url, 'sent', organisation_id, facility_id, {})
    end
  end
end
