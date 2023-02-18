class AdmissionStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :namespace, type: String
  field :event, type: String
  field :from, type: String
  field :to, type: String
  field :created_at, type: DateTime

  # Additional Fields
  field :user_id, type: BSON::ObjectId
  field :department_id, type: String
  field :start_time, type: DateTime, default: Time.current
  field :end_time, type: DateTime
  field :message, type: String

  embedded_in :admission_list_view

  def total_time
    td = TimeDifference.between(start_time, (end_time || Time.current)).in_general
    td = td.delete_if { |_k, v| v == 0 }

    duration_array = []
    td.first(2).each { |component, value| duration_array << "#{value} #{component}".titleize }

    duration_array.join(' ') # return
  end
end
