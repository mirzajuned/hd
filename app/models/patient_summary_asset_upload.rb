class PatientSummaryAssetUpload
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include Mongoid::Ancestry

  has_ancestry

  field :name, type: String
  field :parent_folder_id, type: String
  field :is_folder, type: String
  field :is_root, type: String
  field :is_custom, type: String
  field :asset_path, type: String
  field :content_type, type: String
  field :asset_type, type: String
  field :extension, type: String
  field :file_size, type: String
  field :reported_date, type: Date, default: Date.current
  field :reported_time, type: Time, default: Time.current
  field :format, type: String
  field :store_directory, type: String
  field :uploaded_via_backend, type: String

  field :source, type: String
  field :ipdrecord_id, type: String
  field :opdrecord_id, type: String
  field :investigation_id, type: String
  field :type, type: String

  field :diagram_type, type: String
  field :eyeside, type: String
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :upload_retry_counter, type: Integer, default: 0
  field :is_migrated, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false

  field :specialty_id, type: String

  has_many :patient_asset_upload_tags

  belongs_to :patient

  # belongs_to :organisation, index: {background: true}
  # belongs_to :facility, index: {background: true}
  belongs_to :user, index: { background: true }, optional: true

  # embeds_many :comments
  embeds_many :comments, class_name: '::Comment'
  accepts_nested_attributes_for :comments

  def self.compute_mongoid_for_tags(idstring, namestring, specialty_id, organisation_id, user_id, patient_summary_asset_id)
    if idstring.present? && idstring.length > 0
      idarray = idstring.split(",")
      namearray = namestring.split(",")
      idarray.each_with_index() do |id, index|
        if id.include?("#!##")
          PatientAssetUploadTag.create(:tag_name => namearray[index], :tag_name_lcase => namearray[index].downcase, :doctor => user_id, user_id: user_id, specialty_id: specialty_id, organisation_id: organisation_id, :is_custom => "Y", :patient_summary_asset_upload_id => patient_summary_asset_id)
        end
      end
    end
  end

  def store_previous_model_for_asset_path
    if asset_path.remove_previously_stored_files_after_update && asset_path_changed?
      @previous_model_for_asset_path ||= self.find_previous_model_for_asset_path
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

  def upload_tag
    case parent_folder_id
    when '560cc6f72b2e26135d000000'
      'P'
    when '560cc6f72b2e26135d000001'
      'R'
    when '560cc6f72b2e26135d000002'
      'L'
    when '560cc6f72b2e26135d000003'
      'Or'
    when '560cc6f72b2e26135d000004'
      'In'
    when '560cc6f72b2e26135d000005'
      'O'
    when '560cc6f72b2e26135d000006'
      'I'
    when '560cc6f72b2e26135d000007'
      'D'
    when '560cc6f72b2e26135d000008'
      'Op'
    else
      'A'
    end
  end

  mount_uploader :asset_path, PatientSummaryUploader
  validates_presence_of :asset_path
  validates_integrity_of :asset_path
  validates_processing_of :asset_path
end
