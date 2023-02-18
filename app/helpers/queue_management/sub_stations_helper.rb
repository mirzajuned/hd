module QueueManagement::SubStationsHelper
  def qm_format_user(user)
    user.try(:custom_name_format)
  end
end
