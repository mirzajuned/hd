class Analytics::GeneralOverview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # date wise data needed
  field :date, type: Date

  # appointment count
  field :appointment_created_count, type: Integer, default: 0
  field :appointment_arrived_count, type: Integer, default: 0

  # old vs new patient count
  field :opd_new_patient_count, type: Integer, default: 0
  field :opd_old_patient_count, type: Integer, default: 0

  # frequency of revisits
  field :first_opd_visit, type: Integer, default: 0
  field :second_opd_visit, type: Integer, default: 0
  field :third_opd_visit, type: Integer, default: 0
  field :fourth_opd_visit, type: Integer, default: 0
  field :fifth_opd_visit, type: Integer, default: 0
  field :above_fifth_opd_visit, type: Integer, default: 0

  # admission_count
  field :admission_created_count, type: Integer, default: 0
  field :admission_admitted_count, type: Integer, default: 0

  # ot count
  field :ot_count, type: Integer, default: 0

  # ids need to be stored
  field :facility_id, type: BSON::ObjectId
  field :specialty_id, type: String
  field :user_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :arrids, type: Array

  scope :created_on, ->(s, e, org) {
                       where(:date.gte => (Time.current.beginning_of_day - s.days),
                             :date.lte => (Time.current.end_of_day - e.days)).where(organisation_id: org)
                     }

  field :data_type, type: String  # can be day, week, month, year
  field :start_date, type: Date   # start date
  field :end_date, type: Date     # end date
  field :data_type_range, type: Integer # can be year(2019), can be month number(8), can be week number (32), can be day number (232)
  field :in_year, type: Integer
end
