class Appointmentasset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :asset_path, type: String
  field :content_type, type: String
  field :asset_type, type: String
  field :extension, type: String
  field :file_size, type: String

  belongs_to :appointment
  # attr_accessor :patient_id, :extension
  mount_uploader :asset_path, AppointmentAssetUploader
  # hack for carrier wave to work
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
end
