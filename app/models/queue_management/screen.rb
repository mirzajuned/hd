class QueueManagement::Screen
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :username, type: String
  field :passcode, type: String
  field :expiry_date, type: Date

  belongs_to :user
  belongs_to :facility
  belongs_to :organisation

  validates_presence_of :name, :username, :passcode, :expiry_date

  validates_uniqueness_of :username, case_sensitive: false, scope: :facility_id, message: 'Username Already Exists'
  validates_uniqueness_of :passcode, case_sensitive: false, scope: :facility_id

  after_save :update_qm_screen
  def update_qm_screen
    QueueManagementJobs::QmModelJob.perform_later(self.class.name, id.to_s, 'screen')
  end
end
