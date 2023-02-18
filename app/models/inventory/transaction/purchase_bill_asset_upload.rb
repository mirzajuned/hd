class Inventory::Transaction::PurchaseBillAssetUpload
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
  #field :purchase_bill_id,    type: BSON::ObjectId

  belongs_to :purchase_bill, class_name: '::Inventory::Transaction::PurchaseBill', inverse_of: :purchase_bill_assets
  mount_uploader :asset_path, PurchaseBillAssetUploader

  default_scope { where(is_deleted: false) }
end
