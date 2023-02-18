# No Offenses
class OtSchedule
  include Mongoid::Document
  include Mongoid::Timestamps

  after_save :ot_list_view

  field :otdate, type: Date
  field :ottime, type: Time
  field :otenddate, type: Date
  field :otendtime, type: Time
  field :surgeonname, type: BSON::ObjectId
  field :procedurename, type: String
  field :theatreno, type: BSON::ObjectId
  field :theatrename, type: String
  field :display_id, type: String
  field :operation_done, type: Boolean, default: false
  field :ready_for_ot, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false
  field :is_engaged, type: Boolean, default: false
  field :send_to_ward, type: Boolean, default: false
  field :specialty_id, type: String
  field :is_migrated, type: Boolean, default: true
  field :organisation_id, type: BSON::ObjectId
  field :confirm_ot, type: Boolean, default: false

  belongs_to :patient
  belongs_to :user
  belongs_to :facility
  belongs_to :admission, optional: true
  belongs_to :ward, optional: true
  belongs_to :bed, optional: true
  belongs_to :bed_type, optional: true
  belongs_to :case_sheet, optional: true

  def ot_list_view
    ot_list_view = OtListView.find_by(ot_id: id.to_s)
    if ot_list_view.present?
      OtListViews::UpdateService.call(ot_list_view, self)
    else
      OtListViews::CreateService.call(self)
    end
  end
end
