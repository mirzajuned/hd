class QueueManagement::Area
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  belongs_to :user
  belongs_to :facility
  belongs_to :organisation

  has_many :stations, class_name: 'QueueManagement::Station'

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false, scope: :facility_id

  after_save :update_qm_area
  def update_qm_area
    QueueManagementJobs::QmModelJob.perform_later(self.class.name, id.to_s, 'area')
  end
end
