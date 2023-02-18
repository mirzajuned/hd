class ServiceMaster
  include Mongoid::Document
  include Mongoid::Timestamps

  field :service_type, type: String
  field :service_type_code, type: String
  field :service_type_code_name, type: String
  field :service_type_code_type, type: String

  field :service_name, type: String
  field :service_amount, type: Float

  field :service_code, type: String
  field :organisation_service_code, type: String

  field :is_active, type: Boolean, default: true

  field :activity_log, type: Hash, default: {}

  field :department_ids, type: Array, default: []

  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  # For Legacy Data Only
  field :is_legacy, type: Boolean, default: false
  field :item_card_id, type: BSON::ObjectId

  field :specialty_id, type: String
  field :sub_specialty_id, type: String

  field :is_migrated, type: Boolean, default: true

  belongs_to :service_group
  belongs_to :service_sub_group
  # belongs_to :organisation
  # belongs_to :user

  validates_presence_of :service_type, :service_name, :service_code, :user_id, :organisation_id
  validates_presence_of :service_type_code, if: -> { ['Procedure', 'Investigation'].include?(service_type) }

  def service_master_description
    description = "#{service_type}-#{service_sub_group.name}-#{service_name}"
    if organisation_service_code.present?
      "#{description}(#{organisation_service_code}/#{service_code})"
    else
      "#{description}(#{service_code})"
    end
  end

  # Indexes
  # index({ organisation_id: 1, service_type: 1 })
  # db.service_masters.createIndex({ organisation_id: 1, service_type: 1 })
end
