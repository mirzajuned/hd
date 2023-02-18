class LabRecord < Investigation::Record
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :_type, type: String
  field :appointment_id, type: String
  field :facility_id, type: String
  field :investigation_advised_id, type: String
  field :investigation_comment, type: String
  field :investigation_full_code, type: String
  field :investigation_name, type: String
  field :investigation_val, type: String
  field :loinc_class, type: String
  field :loinc_code, type: String
  field :name, type: String
  field :normal_range, type: String
  field :opd_record_id, type: String
  field :organisation_id, type: String
  field :patient_id, type: BSON::ObjectId

  field :requested_by, type: String
  field :specimen_date, type: String
  field :specimen_type, type: String
  field :state, type: String
  field :template_created_by, type: BSON::ObjectId



  scope :by_advised_user, -> (user_id) { where(advised_by: user_id) if user_id.present? }
  scope :by_performed_user, -> (user_id) { where(performed_by: user_id) if user_id.present? }
  scope :performed_on, -> (performed_date) { 
          where(:performed_at.gte => performed_date.beginning_of_day, :performed_at.lte => performed_date.end_of_day)
        }
  scope :advised_on, -> (advised_date) { 
          where(:advised_at.gte => advised_date.beginning_of_day, :advised_at.lte => advised_date.end_of_day)
        }

  def self.filters(params)
    records = by_advised_user(params[:advised_by]).by_performed_user(params[:performed_by])
    if params[:performed_at].present?
      records = records.performed_on(Date.parse(params[:performed_at]))
    end
    if params[:advised_at].present?
      records = records.advised_on(Date.parse(params[:advised_at]))
    end
    records
  end
end
