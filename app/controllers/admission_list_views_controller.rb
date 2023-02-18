class AdmissionListViewsController < ApplicationController
  before_action :authorize
  before_action :set_admission_list_view

  def new_message
    @user = User.find_by(id: params[:to_user])
  end

  def change_state
    # @admission_list_view.send("assign_to_#{params[:to_state]}", params[:to_user], 'user', params[:message])
    if params[:to_state] == 'receptionist'
      @admission_list_view.send("assign_to_receptionist", params[:to_user], 'user', params[:message])
    elsif params[:to_state] == 'nurse'
      @admission_list_view.send("assign_to_nurse", params[:to_user], 'user', params[:message])
    elsif params[:to_state] == 'doctor'
      @admission_list_view.send("assign_to_doctor", params[:to_user], 'user', params[:message])
    elsif params[:to_state] == 'counsellor'
      @admission_list_view.send("assign_to_counsellor", params[:to_user], 'user', params[:message])
    elsif params[:to_state] == 'tpa'
      @admission_list_view.send("assign_to_tpa", params[:to_user], 'user', params[:message])
    end

    facility_id = @admission_list_view.facility_id
    specialty_id = @admission_list_view.specialty_id
    to_user_id = params[:to_user]
    from_user_id = params[:from_user]

    AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, to_user_id, 'inc')
    AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, from_user_id, 'dec')
  end

  def undo_state
    AdmissionListViews::UndoStateService.call(@admission_list_view)
  end

  private

  def set_admission_list_view
    @admission_list_view = AdmissionListView.find_by(id: params[:id])
  end
end
