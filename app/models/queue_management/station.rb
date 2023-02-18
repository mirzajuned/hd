class QueueManagement::Station
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :type, type: String
  field :display_code, type: String

  field :is_deleted, type: Boolean, default: false

  belongs_to :area, class_name: 'QueueManagement::Area'
  has_many :sub_stations, class_name: 'QueueManagement::SubStation'

  belongs_to :user
  belongs_to :facility
  belongs_to :organisation

  accepts_nested_attributes_for :sub_stations, class_name: 'QueueManagement::SubStation', allow_destroy: true

  default_scope -> { where(is_deleted: false) }

  validates_presence_of :name, :type, :display_code
  validates_uniqueness_of :name, case_sensitive: false, scope: [:area_id, :is_deleted], unless: :is_deleted
  validates_uniqueness_of :display_code, case_sensitive: false, scope: [:area_id, :is_deleted], unless: :is_deleted

  after_save :update_qm_station
  def update_qm_station
    QueueManagementJobs::QmModelJob.perform_later(self.class.name, id.to_s, 'station')
  end
end
