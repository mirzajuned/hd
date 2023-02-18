class Analytics::UserAverageTime
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :facility_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :role, type: String
  field :total_patient_seen, type: Integer, default: 0
  field :date, type: Date # date for which total time calculated
  field :total_time_given, type: Integer, default: 0 # in seconds
  field :opd_new_patient_count, type: Integer, default: 0
  field :opd_old_patient_count, type: Integer, default: 0
  field :avg_time_given, type: Integer, default: 0.0

  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
  field :is_migrated, type: Boolean, default: true

  def total_user_time_in_hrs
    hrs = (self.total_time_given / 3600).to_i
    minutes = (self.total_time_given / 60 % 60).to_i
    time = "#{hrs} H #{minutes} M"
  end

  def total_avg_time_in_mins
    minutes = (self.avg_time_given / 60).to_i
  end
end
