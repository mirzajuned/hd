class Analytics::CreateService
  def self.call(params, current_user_id, facility_id, type)
    Analytics::CreateJob.perform_later(params, current_user_id.to_s, facility_id.to_s, type)
  end
end
