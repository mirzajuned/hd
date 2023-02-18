class AdmissionListViews::UndoStateService
  def self.call(admission_list_view)
    facility_id = admission_list_view.facility_id
    specialty_id = admission_list_view.specialty_id

    state_transitions = admission_list_view.admission_state_transitions

    last_transition = state_transitions[-1]
    from_user_id = last_transition.user_id
    AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, from_user_id, 'dec')

    new_last_transition = state_transitions[-2]
    last_transition&.delete
    new_last_transition&.update(end_time: nil)

    to_user_id = new_last_transition&.user_id
    AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, to_user_id, 'inc')

    admission_list_view.update(user_id: new_last_transition&.user_id,
                               start_time: new_last_transition&.start_time,
                               sm_state: new_last_transition&.to,
                               message: new_last_transition&.message)
  end
end
