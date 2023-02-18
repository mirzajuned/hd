class PrintSetting
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :type, type: String
  field :logo, type: String

  field :facility_ids, type: Array, default: []
  field :department_ids, type: Array, default: []

  field :header_height, type: Integer, default: 3
  field :footer_height, type: Integer, default: 2
  field :left_margin, type: Integer, default: 0
  field :right_margin, type: Integer, default: 0

  field :customised_letter_head, type: Boolean, default: false

  field :header_location, type: String
  field :header, type: String
  field :header_logo_location, type: String

  field :right, type: String
  field :left,  type: String

  field :customised_footer, type: Boolean, default: false
  field :footer_text, type: String

  field :updated, type: Boolean, default: true
  field :is_editable, type: Boolean, default: false
  field :hg_defined, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false

  field :organisation_id, type: BSON::ObjectId

  # Logo Uploader
  mount_uploader :logo, PrintSettingUploader

  # Validation
  validates_presence_of :name, message: 'Name cannot be blank.'
  validates_presence_of :facility_ids, message: 'Please select facility location'
  validates_presence_of :department_ids, message: 'Please select a Department.'

  # Use Scope to get PrintSetting for selected Departments
  def self.print_options(organisation_id, facility_id, department_ids)
    print_settings = where(organisation_id: organisation_id, facility_ids: facility_id,
                           :department_ids.in => department_ids, hg_defined: false, is_deleted: false)

    # Default Print
    print_settings = where(organisation_id: organisation_id, hg_defined: true) if print_settings.empty?

    print_settings
  end

  # Indexes
  # index({ organisation_id: 1 }) # db.print_settings.createIndex({ organisation_id: 1 })
end
