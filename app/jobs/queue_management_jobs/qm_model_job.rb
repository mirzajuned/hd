class QueueManagementJobs::QmModelJob < ActiveJob::Base
  queue_as :urgent

  QMLOGGER = Logger.new("#{Rails.root}/log/queue_management.log")

  def perform(qm_model_name, qm_model_id, key_identifier)
    qm_model = qm_model_name.constantize.find_by(id: qm_model_id)

    payload = { "#{key_identifier}": qm_model.attributes }.to_json
    url = Global.hg_qm_product[Rails.env]["updateQm#{key_identifier.camelize}"]['url']
    headers = Global.hg_qm_product[Rails.env]["updateQm#{key_identifier.camelize}"]['headers']

    # QMLOGGER.info("QmModelJob payload: #{payload} #{url}")
    response = RestClient::Request.execute(method: :post, url: url, payload: payload, headers: headers)
    # QMLOGGER.info("response payload: #{response}")

  rescue StandardError => e
    QMLOGGER.info("QmModelJob: #{e}")
  end
end
