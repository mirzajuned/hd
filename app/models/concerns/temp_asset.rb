require 'base64'
require 'active_support'

class TempAsset
  include Mongoid::Document
  include Mongoid::Timestamps

  field :asset_path, type: String
  field :content_type, type: String
  field :asset_type, type: String
  field :extension, type: String
  field :file_size, type: String
  field :diagram_type, type: String
  field :eyeside, type: String

  # attr_accessor :patient_id, :extension
  mount_uploader :asset_path, TempAssetUploader

  # def asset_path_data=(data)
  #   io = CarrierStringIO.new(Base64.decode64(data['data:image/png;base64,'.length .. -1]))
  #   self.asset_path = io
  # end
end
