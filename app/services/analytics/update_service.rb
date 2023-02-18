class Analytics::UpdateService
  def self.call(params, current_user_id, current_facility_id, type)
    Analytics::UpdateJob.perform_later(params, current_user_id, current_facility_id, type)
  end
end
