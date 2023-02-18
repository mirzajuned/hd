class ApiIntegration::DataRequests::CreateService
  def self.call(payload, url, request_type, organisation_id, facility_id, additional_data)
    data_request = ApiIntegration::DataRequest.new

    data_request.payload = payload
    data_request.additional_data = additional_data
    data_request.request_date = Date.current
    data_request.request_time = Time.current
    data_request.request_type = request_type
    data_request.url = url
    data_request.facility_id = facility_id
    data_request.organisation_id = organisation_id

    data_request.save!
  end
end
