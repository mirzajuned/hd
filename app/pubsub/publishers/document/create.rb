# require 'celluloid/current'
#
# class Document::Create
#   include Wisper::Publisher
#
#   def call(record_name, record_id, facility_id, provider)
#     return if host.nil?
#
#     url = "#{host}/api/v1/documents/download.pdf?record_name=#{record_name}&record_id=#{record_id}"
#
#     broadcast(:create_integration_document_data, record_name, record_id, facility_id, url, provider)
#   end
#
#   private
#
#   def host
#     Global.healthgraph[Rails.env]['host']
#   rescue NoMethodError
#     nil
#   end
# end
