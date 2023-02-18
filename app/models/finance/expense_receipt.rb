class Finance::ExpenseReceipt
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :comment_text, type: String

  field :asset_path, type: String
  field :name, type: String

  embedded_in :expense, class_name: "::Finance::Expense"

  mount_uploader :asset_path, ExpenseReceiptUploader
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

  # validates_presence_of :asset_path
  # validates_integrity_of :asset_path
  # validates_processing_of :asset_path
end
