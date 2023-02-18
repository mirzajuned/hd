class Inventory::Vendor::AssetUpload
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoCarrierWave

  field :asset_path,   type: String
  field :content_type, type: String
  field :asset_type,   type: String
  field :extension,    type: String
  field :file_size,    type: String
  field :name,         type: String
  field :is_deleted,   type: Boolean, default: false
  #field :vendor_id,    type: BSON::ObjectId

  belongs_to :vendor, class_name: '::Inventory::Vendor', inverse_of: :assets
  mount_uploader :asset_path, VenderAssetUploader

  default_scope { where(is_deleted: false) }
end
