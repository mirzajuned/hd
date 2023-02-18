class ApiIntegration::DataResponses::CreateService
  def self.call(payload, url, response_type, organisation_id, facility_id, additional_data)
    data_response = ApiIntegration::DataResponse.new

    data_response.payload = payload
    data_response.additional_data = additional_data
    data_response.response_date = Date.current
    data_response.response_time = Time.current
    data_response.response_type = response_type
    data_response.url = url
    data_response.facility_id = facility_id
    data_response.organisation_id = organisation_id

    data_response.save!
  end
end
