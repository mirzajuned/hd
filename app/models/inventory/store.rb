# used
class Inventory::Store
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :abbreviation_name, type: String
  field :department_name, type: String
  field :department_id, type: String

  field :central_purchasing_hub, type: Mongoid::Boolean, default: false
  field :days_before_expired, type: Integer, default: 90

  field :enable_sub_store, type: Boolean, default: false

  field :enable_stock_management, type: Boolean, default: true

  field :billable_transaction, type: Boolean, default: true
  field :enable_stock_entry, type: Boolean, default: true
  field :enable_transfer, type: Boolean, default: false
  field :enable_receiving, type: Boolean, default: false
  field :enable_tax_invoice, type: Boolean, default: false

  field :enable_purchase_order, type: Boolean, default: true
  field :enable_transfer_order, type: Boolean, default: false
  field :enable_receiving_order, type: Boolean, default: false

  field :in_house_consumption, type: Boolean, default: true
  field :store_consumption, type: Boolean, default: true # used for store consumption
  # central hub
  field :transfer_to_linked_stores, type: Boolean, default: true
  field :transfer_other_central_hub, type: Boolean, default: true
  field :receive_items_from_linked_stores, type: Boolean, default: true
  field :receive_items_from_other_central_hub, type: Boolean, default: true

  # field :outsourced_store, type: Boolean, default: false

  field :central, type: Mongoid::Boolean, default: false

  field :is_active, type: Boolean, default: true # for soft delete
  field :is_disable, type: Boolean, default: false #toggle disable/active

  field :shop_name, type: String
  field :gst, type: String
  field :tin, type: String
  field :dl_number, type: String
  field :username, type: String
  field :asset_path, type: String, default: '_old_'

  field :disclaimer, type: String
  field :show_disclaimer, type: Boolean, default: false

  field :facility_ids, type: Array, default: []

  field :store_ids, type: Array, default: []

  field :category_ids, type: Array, default: []

  field :vendor_ids, type: Array, default: []

  field :master_configuration, type: Boolean, default: false
  field :requisition, type: Boolean, default: false
  field :requisition_fulfillment, type: Boolean, default: false
  field :reorder_level, type: Boolean, default: false
  field :auto_requisition, type: Boolean, default: false
  field :requisition_requested_store_id, type: BSON::ObjectId
  field :requisition_requested_store_name, type: String

  # Adress
  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :district, type: String
  field :commune, type: String
  field :gst_state_code, type: String
  field :alpha_code, type: String
  field :is_union_territory, type: Boolean
  field :is_utgst_applicable, type: Boolean

  # Billing Address
  field :billing_address, type: String
  field :billing_city, type: String
  field :billing_state, type: String
  field :billing_pincode, type: Integer
  field :billing_district, type: String
  field :billing_commune, type: String

  # Contact
  field :telephone, type: String
  field :mobilenumber, type: String
  field :fax, type: String
  field :email, type: String

  field :facility_name, type: String

  field :organisation_id, type: BSON::ObjectId
  field :country_id, type: BSON::ObjectId
  field :billing_country_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  # belongs_to :facility

  field :entity_group_id, type: BSON::ObjectId

  field :integration_identifier, type: BSON::ObjectId # Used for integrating with 3rd Party HIS or other Inventory Solutions to pass item information during API integration.
  field :vendor_location_ids, type: Array, default: []
  has_and_belongs_to_many :users

  has_many :sub_stores, class_name: '::Inventory::SubStore', foreign_key: 'store_id'
  after_save :update_domain_count

  def update_domain_count
    return unless email_changed?

    old_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email_was.to_s.split('@')[1],
                                       deleted: false)
    old_domain.inc(use_count: -1) if old_domain && old_domain.use_count > 0

    new_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email.to_s.split('@')[1],
                                       deleted: false)
    new_domain&.inc(use_count: 1)
  end

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

  validates :department_id, presence: true
end
