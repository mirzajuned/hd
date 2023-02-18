class OrganisationNotificationsController < ApplicationController
  before_action :authorize
  before_action :settings_enabled?
  before_action :authorized_by_policy?, only: [:index]
  before_action :find_notification, only: [:show, :display, :edit, :update, :destroy, :activate, :acknowledge]

  layout 'loggedin'

  def index
    @organisation_notifications = OrganisationNotification.includes(:user)
                                                          .where(organisation_id: current_user.organisation_id)

    tab_notifications

    all_facility_ids = @organisation_notifications.pluck(:facility_ids).flatten.uniq
    @facilities = Facility.where(:id.in => all_facility_ids)
                          .map { |facility| { id: facility.id.to_s, name: facility.name } }

    all_role_ids = @organisation_notifications.pluck(:role_ids).flatten.uniq
    @roles = Role.where(:id.in => all_role_ids.map(&:to_i))
                 .map { |role| { id: role.id.to_s, label: role.label } }
  end

  def display_all; end

  def new
    @organisation_notification = OrganisationNotification.new
  end

  def create
    @organisation_notification = OrganisationNotification.new(organisation_notification_params)
    if @organisation_notification.save
      render :show
    else
      render :new
    end
  end

  def show; end

  def display; end

  def edit; end

  def update
    if @organisation_notification.update_attributes(organisation_notification_params)
      render :show
    else
      render :edit
    end
  end

  def destroy
    @organisation_notification.update_attributes(deleted: params[:deleted])
  end

  def activate
    @organisation_notification.update_attributes(active: true, acknowledger_ids: [])
  end

  def acknowledge
    @organisation_notification.acknowledger_ids = @organisation_notification.acknowledger_ids.push(current_user.id.to_s)
    @organisation_notification.rl_user_ids = @organisation_notification.rl_user_ids - [current_user.id.to_s]

    delete_notification_redis if @organisation_notification.save
  end

  def read_later
    @organisation_notifications = OrganisationNotification.where(
      organisation_id: current_user.organisation_id, :acknowledger_ids.ne => current_user.id.to_s
    )

    @organisation_notifications.each do |notification|
      notification.rl_user_ids = notification.rl_user_ids.push(current_user.id.to_s)
      notification.save
    end
  end

  private

  def find_notification
    @organisation_notification = OrganisationNotification.find_by(id: params[:id])
  end

  def organisation_notification_params
    params[:organisation_notification][:web_links] = params[:organisation_notification][:web_links].values

    params.require(:organisation_notification).permit(
      :title, :body, :start_date, :end_date, :all_facilities, :all_roles,
      facility_ids: [], role_ids: [], web_links: [:link, :link_text]
    ).with_defaults(
      user_id: current_user.id, organisation_id: current_user.organisation_id, active: false,
      facility_ids: [], role_ids: []
    )
  end

  def tab_notifications
    @scheduled_notifications = @organisation_notifications.where(helpers.table_options('scheduled')).order(start_date: :asc)
    @active_notifications = @organisation_notifications.where(helpers.table_options('active')).order(start_date: :desc)
    @expired_notifications = @organisation_notifications.where(helpers.table_options('expired')).order(end_date: :desc)
    @disabled_notifications = @organisation_notifications.where(helpers.table_options('disabled')).order(updated_at: :desc)
  end

  def delete_notification_redis
    Redis::Master.new.del("new_user_notification:#{current_user.id}")
    Redis::Master.new.del("old_user_notification:#{current_user.id}")
  end

  def settings_enabled?
    return if current_organisation_setting.organisation_notification_enabled

    redirect_to root_path
  end

  def authorized_by_policy?
    return if helpers.user_authorized_by_policy?('HGP-103-100-101')

    redirect_to root_path
  end
end
