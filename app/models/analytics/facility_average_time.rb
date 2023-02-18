class Analytics::FacilityAverageTime
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :date, type: Date # date for which total time calculated
  field :average_time, type: Integer, default: 0 # in Seconds
  field :total_patient_seen, type: Integer, default: 0 # patient seen count

  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
  field :is_migrated, type: Boolean, default: true

  def total_average_time_in_hrs
    hrs = (self.average_time / 3600).to_i
    minutes = (self.average_time / 60 % 60).to_i
    time = "#{hrs} hrs #{minutes} minutes"
    return time
  end
end
