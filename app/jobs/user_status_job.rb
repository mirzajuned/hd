class UserStatusJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id, organisation_id, state, quota, current_user_id)
    current_user = User.find_by(id: current_user_id)
    user_status = UserStatus.find_by(user_id: user_id, end_time: nil, deleted: false)

    # If state or quota has not changed - return
    return if user_status && user_status.state == state && user_status.quota == quota

    new_user_status = UserStatus.new(
      start_time: Time.now, state: state, quota: quota, organisation_id: organisation_id,
      modified_by: current_user&.fullname, modified_by_id: current_user_id, user_id: user_id
    )

    new_user_status.save!

    # Update last UserStatus
    user_status&.set(end_time: new_user_status.start_time)

    delete_duplicates(user_id) if state == 'active'
  rescue StandardError => e
    puts e.message
  end

  private


  # TODO: Discuss on the scenarios.
  # Deleting all entries where Start Date & End Date are same (if new state is 'active').

  # TODO : SCENARIOS FOR REFERENCE REMOVE ONCE CLEARED
  # User was inactive and the following scenarios ran on the same day
  # (1)Active
  #   Will create entry with state 'active', end_time nil
  # (2)Inactive
  #   Will create entry with state 'inactive', end_time nil
  #   Will update end_time of (1) with same date as start_date
  # (3)Active
  #   Will create entry with state 'active', end_time nil
  #   Will update end_time of (2) with same date as start_date
  #   Will delete (1) & (2) as it will be duplicate entries where start and end are same.
  # Final State (1) - deleted, (2) - deleted, (3) - not_deleted

  # User was active and the following scenarios ran on the same day
  # (1)Inactive
  #   Will create entry with state 'inactive', end_time nil
  # (2)Active
  #   Will create entry with state 'active', end_time nil
  #   Will update end_time of (1) with same date as start_date
  #   Will delete (1) as it will be duplicate entry where start and end are same.
  # (3)Inactive
  #   Will create entry with state 'inactive', end_time nil
  #   Will update end_time of (2) with same date as start_date
  #   Will not delete anything.
  # Final State (1) - deleted, (2) - not_deleted, (3) - not_deleted

  def delete_duplicates(user_id)
    UserStatus.where(
      user_id: user_id, :start_time.gte => Date.today, :end_time.lte => Date.today.end_of_day
    ).update_all(deleted: true)
  end
end
