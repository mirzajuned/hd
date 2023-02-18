module QueueManagement::StationsHelper
  def delete_sub_station?
    accessible_time = Time.current.between?(Time.zone.parse('21:00'), Time.zone.parse('23:59:59'))
    non_production_environment = !(Rails.env.production? || Rails.env.preproduction?)

    accessible_time || non_production_environment
  end
end
