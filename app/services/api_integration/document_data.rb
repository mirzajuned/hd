class ApiIntegration::DocumentData
  def create_integration_document_data(record_name, record_id, facility_id, url, provider)
    @facility = Facility.find_by(id: facility_id)
    @organisation = Organisation.find_by(id: @facility.organisation_id)

    # Send RestClient::Request
    rest_client_request(record_name, record_id, url, provider)

    # Save request/response data
    create_data_request
    create_data_response
  end

  private

  def rest_client_request(record_name, record_id, url, provider)
    @url = Global.send(provider)[Rails.env]['updateDocumentService']['url']
    @headers = Global.send(provider)[Rails.env]['updateDocumentService']['headers']
    @payload = send("#{provider}_payload", record_name, record_id, url)

    response = RestClient.post @url, @payload.to_json, @headers
    @response = JSON.parse(response)
  rescue RestClient::ExceptionWithResponse => e
    response = JSON.parse(e.response)
    @response = { status_code: response['status'], message: response['message'] }
  end

  def get_record(record_name, record_id)
    if record_name == 'DischargeNote'
      ipd_record = Inpatient::IpdRecord.find_by(id: record_id)
      @record = ipd_record&.discharge_note
    else
      @record = record_name.constantize.find_by(id: record_id)
    end
  end

  def claimbook_payload(record_name, record_id, url)
    get_record(record_name, record_id)

    admission = Admission.find_by(id: @record.admission_id)
    patient = Patient.find_by(id: @record.patient_id)
    patient_other_identifier = PatientOtherIdentifier.find_by(patient_id: patient.id)
    filename = "#{record_name.to_s.underscore}_record_#{record_id}.pdf"

    # return Payload
    {
      "hospitalCode": @facility.abbreviation, "mrn": patient_other_identifier.mr_no, "caseID": admission.display_id,
      "type": 'IP',
      "documents": [{
        "name": filename,
        "path": url,
        "type": record_name, "description": record_name
      }]
    }
  end

  def create_data_request
    data_hash = @payload
    organisation_id = @organisation.id.to_s
    facility_id = @facility.id.to_s
    ApiIntegration::DataRequests::CreateService.call(data_hash, @url, 'sent', organisation_id, facility_id, {})
  end

  def create_data_response
    data_hash = @response
    organisation_id = @organisation.id.to_s
    facility_id = @facility.id.to_s
    ApiIntegration::DataResponses::CreateService.call(data_hash, @url, 'received', organisation_id, facility_id, {})
  end
end
