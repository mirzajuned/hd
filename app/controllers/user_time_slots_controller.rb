class UserTimeSlotsController < ApplicationController
  before_action :authorize
  before_action :find_user_time_slot, only: [:edit, :update, :show_calendar]
  before_action :find_user, only: [:new, :edit, :show_calendar]

  def index
    level = params[:level]
    @organisation = current_user.organisation
    @organisations_setting = @organisation.organisations_setting

    if level == 'facility'
      @users = User.includes(:user_time_slot).where(role_ids: 158965000, :facility_ids.in => [current_facility.id], is_active: true)
    else
      @users = @organisation.users.includes(:user_time_slot).where(role_ids: 158965000, is_active: true)
    end
  end

  def new
    @user_time_slot = UserTimeSlot.new
  end

  def create
    @user_time_slot = UserTimeSlot.new(user_time_slot_params)

    return if @user_time_slot.save

    respond_to do |format|
      format.js { render 'errors.js.erb' }
    end
  end

  def edit
    @sessions = @user_time_slot.sessions
    @exception_sessions = @user_time_slot.exception_sessions.active_future
  end

  def update
    return if @user_time_slot.update(user_time_slot_params)

    respond_to do |format|
      format.js { render 'errors.js.erb' }
    end
  end

  def show_calendar; end

  def show_calendar_data
    events = UserTimeSlots::EventsDataService.new(params).start

    render json: events
  end

  private

  def user_time_slot_params
    params.require(:user_time_slot).permit(
      :user_id, :organisation_id, :calendar_duration,
      sessions_attributes: sessions_params, exception_sessions_attributes: exception_sessions_params
    )
  end

  def sessions_params
    [:id, :_destroy, :shared_id, :facility_id, :department_id, :start_time, :end_time,
     :slot_duration, :time_duration, days: []]
  end

  def exception_sessions_params
    sessions_params + [:start_date, :end_date]
  end

  def find_user_time_slot
    @user_time_slot = UserTimeSlot.find_by(id: params[:id])
  end

  def find_user
    @user = User.find_by(id: params[:user_id])

    @facilities_array = @user.facilities.pluck(:name, :id)
  end
end
