class QueueManagement::SubStation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :display_code, type: String
  field :is_deleted, type: Boolean, default: false

  belongs_to :area, class_name: 'QueueManagement::Area'
  belongs_to :station, class_name: 'QueueManagement::Station'

  belongs_to :user, optional: true # Permanent User
  belongs_to :facility
  belongs_to :organisation

  belongs_to :created_by, class_name: 'User'
  belongs_to :active_user, class_name: 'User', optional: true
  belongs_to :last_active_user, class_name: 'User', optional: true

  default_scope -> { where(is_deleted: false) }

  validates_presence_of :display_code
  validates_uniqueness_of :display_code, case_sensitive: false, scope: [:area_id, :is_deleted], unless: :is_deleted

  before_validation :update_active_user, if: -> { user_id_changed? && user_id.present? }
  before_validation :update_user_fields, if: -> { is_deleted_changed? && is_deleted }

  after_save :update_qm_sub_station
  after_save :update_dropdowns, if: -> { active_user_id_changed? && active_user_id.present? }
  after_save :dropdowns_delete_user, if: -> { is_deleted_changed? && is_deleted && last_active_user_id }

  def update_active_user
    user_active_station = QueueManagement::SubStation.find_by(active_user_id: user_id)
    return if user_active_station

    self.active_user_id = user_id
  end

  def update_user_fields
    self.last_active_user_id = active_user_id || user_id
    self.active_user_id = nil
    self.user_id = nil
  end

  def update_qm_sub_station
    QueueManagementJobs::QmModelJob.perform_later(self.class.name, id.to_s, 'sub_station')
  end

  def update_dropdowns
    QueueManagementJobs::SubStationJob.perform_later(id.to_s, active_user_id.to_s, 'update')
    QueueManagementJobs::StationJob.perform_later(station_id.to_s)
  end

  def dropdowns_delete_user
    QueueManagementJobs::SubStationJob.perform_later(id.to_s, last_active_user_id.to_s, 'remove')
    QueueManagementJobs::StationJob.perform_later(station_id.to_s)
  end
end
