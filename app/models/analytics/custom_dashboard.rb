class Analytics::CustomDashboard
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :dashboard_name, type: String

  field :selected_data, type: String

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  def checkboxes_checked(checked)
    checked&.split(',')
  end
end
