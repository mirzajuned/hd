module OrganisationNotificationsHelper
  def selectable_facilities
    Facility.where(organisation_id: current_user.organisation_id, is_active: true).pluck(:name, :id)
  end

  def selectable_roles
    Role.all.pluck(:label, :id)
  end

  def table_options(type)
    today = Date.current

    case type
    when 'scheduled'
      { '$or': [{ :start_date.gt => today }, { start_date: today, active: false }], deleted: false }
    when 'active'
      { :start_date.lte => today, :end_date.gte => today, active: true, deleted: false }
    when 'expired'
      { '$or': [{ :end_date.lt => today, active: true }, { :start_date.lt => today, active: false }], deleted: false }
    when 'disabled'
      { deleted: true }
    else
      {}
    end
  end

  def generate_redis_notifications(key, type)
    user_notifications = type == 'new' ? new_notifications.to_json : old_notifications.to_json

    Redis::Master.new.set(key, user_notifications)
    Redis::Master.new.expireat(key, 1.day.from_now.beginning_of_day.to_i)

    user_notifications
  end

  def new_notifications
    notification_query({ :acknowledger_ids.nin => [current_user.id.to_s] })
  end

  def old_notifications
    notification_query({ acknowledger_ids: current_user.id.to_s })
  end

  def notification_query(new_options = nil)
    options = { organisation_id: current_user.organisation_id, active: true, deleted: false,
                :start_date.lte => Date.current, :end_date.gte => Date.current }
    options = options.merge(all_conditional_query)

    options = options.merge(new_options) if new_options

    notifications = OrganisationNotification.includes(:user)
                                            .where(options)
                                            .order(start_date: :desc, created_at: :desc)

    notifications.map { |n| { id: n.id.to_s, title: n.title, fullname: n.user.fullname, start_date: n.start_date } }
  end

  private

  def all_conditional_query
    facility_id = current_facility.id.to_s
    role_ids = current_user.role_ids.map(&:to_s)

    {
      '$or': [
        { all_facilities: true, all_roles: true },
        { facility_ids: facility_id, all_roles: true },
        { all_facilities: true, :role_ids.in => role_ids },
        { facility_ids: facility_id, :role_ids.in => role_ids }
      ]
    }
  end
end
