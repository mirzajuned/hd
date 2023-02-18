class UserStatesController < ApplicationController
  before_action :authorize

  def change_state
    if params[:single_facility] == 'true'
      # One Fac
      @opd_total_patient_count, @ipd_total_patient_count, @facility_to_myqueue_hash = User::StatusManagement.get_patients_counts_in_myqueue(current_user)
      clear_my_queue_before_ot = ActiveModel::Type::Boolean.new.cast("#{current_organisation['clear_my_queue_before_ot']}")
      clear_my_queue_before_offline = ActiveModel::Type::Boolean.new.cast("#{current_organisation['clear_my_queue_before_offline']}")
      switching_to_state = params[:state][0]
      if (@opd_total_patient_count > 0 && clear_my_queue_before_ot == true && switching_to_state == "OT")
        @facilities = current_user.facilities.where(show_user_state: true).order(name: :asc)
        @user_state = UserState.where(user_id: current_user.id)
        respond_to do |format|
          format.js { render 'us_logout_patients_in_myqueue' }
        end
      elsif (@opd_total_patient_count > 0 && clear_my_queue_before_offline == true && switching_to_state == "Offline")
        @facilities = current_user.facilities.where(show_user_state: true).order(name: :asc)
        @user_state = UserState.where(user_id: current_user.id)
        respond_to do |format|
          format.js { render 'us_logout_patients_in_myqueue' }
        end
      else
        @states = user_state.states
        @selected_state = params[:state]
        @inactive_states = @states - [@selected_state]
        user_state.update_attributes(active_state: @selected_state[0], state_color: @selected_state[1], inactive_states: @inactive_states)
        User::StatusManagement.update_user_state_in_redis(current_user, user_state.facility_id, @selected_state[0], @selected_state[1])
        respond_to do |format|
          format.js {render :js => "window.location.href='/outpatients/appointment_management'"}
          format.html { redirect_to root_path } #redirect_back fallback_location: root_path
        end
      end
    else
      # Multi Fac Save
      params[:opd].try(:each) do |id_opd|
        @user_state = UserState.find_by(id: id_opd)
        @user_state.update_attributes(active_state: "OPD", state_color: "#008000", inactive_states: [["OT", "#f0ad4e"], ["Offline", "#ff0000"]])
        User::StatusManagement.update_user_state_in_redis(current_user, @user_state.facility_id, "OPD", "#008000")
      end
      params[:ot].try(:each) do |id_ot|
        @user_state = UserState.find_by(id: id_ot)
        @user_state.update_attributes(active_state: "OT", state_color: "#f0ad4e", inactive_states: [["OPD", "#008000"], ["Offline", "#ff0000"]])
        User::StatusManagement.update_user_state_in_redis(current_user, @user_state.facility_id, "OT", "#f0ad4e")
      end
      params[:offline].try(:each) do |id_offline|
        @user_state = UserState.find_by(id: id_offline)
        @user_state.update_attributes(active_state: "Offline", state_color: "#ff0000", inactive_states: [["OPD", "#008000"], ["OT", "#f0ad4e"]])
        User::StatusManagement.update_user_state_in_redis(current_user, @user_state.facility_id, "Offline", "#ff0000")
      end

      respond_to do |format|
        format.js { render 'close' }
      end

      user_id = current_user["_id"]
      user = User.find_by(id: user_id)
      user.update_attribute(:is_set_state_done_manually, true)

      oldloggedin_user = Redis::Local.new.get("user:#{user_id}")
      # Remove the OLD entry from ehr:current:list; setting is_set_state_done_manually changed the object.
      oldloggedin_user_hash = { "user:#{user_id}" => JSON.parse(oldloggedin_user) }
      Redis::Master.new.lrem('ehr:current:list', -1, oldloggedin_user_hash.to_json)

      loggedin_user = user.to_json
      Redis::Local.new.set("user:#{user_id}", loggedin_user)
      # Adding the NEW entry from ehr:current:list.
      current_hash = { "user:#{user_id}" => JSON.parse(loggedin_user) }
      Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)

      # Broadcasting udated user object to sync the updated loggedin_user i.e. User information in Redis::Local of currently running servers.
      current_json = { "user:#{user_id}" => loggedin_user }
      Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

    end
  end

  def set_user_state # Multi Fac
    @facilities = current_user.facilities.where(show_user_state: true).order(name: :asc)
    @user_state = UserState.where(user_id: current_user.id)
    @opd_total_patient_count, @ipd_total_patient_count, @facility_to_myqueue_hash = User::StatusManagement.get_patients_counts_in_myqueue(current_user)
    @clear_my_queue_before_ot = ActiveModel::Type::Boolean.new.cast("#{current_organisation['clear_my_queue_before_ot']}")
    @clear_my_queue_before_offline = ActiveModel::Type::Boolean.new.cast("#{current_organisation['clear_my_queue_before_offline']}")
    respond_to do |format|
      format.js {}
    end
  end

end
