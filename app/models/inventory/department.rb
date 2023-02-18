class Inventory::Department
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :display_name, type: String # for displaying on-boarding inventory
  field :department_id, type: String
  field :shop_name, type: String, default: 'org-name'
  field :shop_address, type: String, default: 'org-address'
  field :asset_path, type: String, default: '_old_'
  field :dl_number, type: String, default: ''
  field :tin, type: String, default: ''
  field :gst, type: String, default: ''
  field :username, type: String, default: ''
  field :contact, type: String
  field :email, type: String
  field :facility_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId

  # belongs_to :facility, class_name: '::Facility'

  def store_previous_model_for_asset_path
    if asset_path.remove_previously_stored_files_after_update && asset_path_changed?
      @previous_model_for_asset_path ||= find_previous_model_for_asset_path
    end
  end

  def find_previous_model_for_asset_path
    self.class.find(to_key.first)
  end

  def remove_previously_stored_asset_path
    if @previous_model_for_asset_path && @previous_model_for_asset_path.asset_path.path != asset_path.path && !asset_path.path.nil?
      @previous_model_for_asset_path.asset_path.remove!
      @previous_model_for_asset_path = nil
    end
  end

  mount_uploader :asset_path, InventoryUploader
end
