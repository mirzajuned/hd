class Api::V2::TabsService
  class << self
    def all_clinical_workflow(_active_user, list, _current_date)
      all_list = list.reject { |ocw| ocw[:appointment_type_label].nil? }
      count = all_list.count
      all_list.nil? ? nil : ['all', 'ALL PATIENTS', count]
    end

    def myqueue_clinical_workflow(active_user, list, _current_date, role)
      my_queue = if active_user == 'all' || active_user.blank?
                   list.select { |ocw| ['complete', 'not_arrived'].exclude?(ocw[:state]) }
                 else
                   list.select { |ocw| ocw[:state] == role && ocw[:user_id] == active_user }
                end
      count = my_queue.count
      my_queue.nil? ? nil : ['my_queue', 'MY QUEUE', count]
    end

    def referral_clinical_workflow(active_user, current_user, current_date, list, role)
      referral =  if current_user.role_ids.any? { |ele| [159561009, 59561000, 159562000].include?(ele) }
                    list.select { |ocw| ocw[:referral] }
                  else
                    list.select { |ocw| ocw[:referral] && ocw[:doctor_ids].include?(active_user) }
                  end
      referral =  nil if role == 'doctor' && current_date > Date.current

      count = referral&.count
      referral.nil? ? nil : ['referral', 'REFERRAl', count]
    end

    def inprogress_clinical_workflow(_active_user, list)
      in_progress = list.select { |ocw| ['complete', 'not_arrived', 'receptionist', 'waiting'].exclude?(ocw[:state]) }
      count = in_progress.count
      in_progress.nil? ? nil : ['in_progress', 'IN PROGRESS', count]
    end

    def incompleted_clinical_workflow(active_user, list, _current_date, _role)
      incompleted = if active_user == 'all' || active_user.blank?
                      list.select { |ocw| ocw[:state] == 'incomplete' && ocw[:user_id].include?(active_user) }
                    else
                      list.select { |ocw| ocw[:state] == 'incomplete' }
                    end
      count = incompleted.count
      incompleted.nil? ? nil : ['incomplete', 'INCOMPLETE', count]
    end

    def completed_clinical_workflow(_active_user, list, _current_date)
      completed = list.select { |ocw| ocw[:state] == 'complete' }
      count = completed.count
      completed.nil? ? nil : ['completed', 'ALL COMPLETED', count]
    end

    def my_completed_clinical_workflow(active_user, list, _current_date)
      mycompleted = list.where(state: 'complete', :doctor_ids.in => [active_user]).to_a
      count = mycompleted.count
      mycompleted.nil? ? nil : ['my_completed', 'MY COMPLETED', count]
    end

    def my_appointment_clinical_workflow(active_user, list)
      my_appointment = list.select { |ocw| ocw[:doctor_ids].include?(active_user) }
      count = my_appointment.count
      my_appointment.nil? ? nil : ['my_appointment', 'MY OP PATIENT', count]
    end

    def not_arrived_clinical_workflow(_active_user, list, current_date, role)
      not_arrived =  case role
                     when 'doctor'
                       current_date == Date.current ? list.select { |ocw| ocw[:state] == 'not_arrived' } : nil
                     else
                       list.select { |ocw| ocw[:state] == 'not_arrived' }
                     end
      count = not_arrived&.count
      not_arrived.nil? ? nil : ['not_arrived', 'NOT ARRIVED', count]
    end

    def all_non_clinical_workflow(list)
      # all = list.select { |alv| ['Scheduled', 'Waiting', 'Engaged'].include?(alv[:current_state]) }
      all = list
      count = all.count
      all.nil? ? nil : ['all', 'All PATIENTS', count]
    end

    def myqueue_non_clinical_workflow(active_user, list)
      my_queue = list.select { |ocw| ['complete'].exclude?(ocw[:current_state]) }
      if active_user == 'all' || active_user.blank?
        my_queue
      else
        my_queue = my_queue.select { |ocw| ocw[:scheduling_user_id] == active_user }
      end
      count = my_queue.count
      my_queue.nil? ? nil : ['my_queue', 'MY QUEUE', count]
    end

    def scheduled_non_clinical_workflow(list)
      scheduled = list.select { |alv| alv[:current_state] == 'Scheduled' }
      count = scheduled.count
      scheduled.nil? ? nil : ['scheduled', 'SCHEDULED', count]
    end

    def waiting_non_clinical_workflow(_active_user, list, _current_date, _role)
      waiting = list.select { |alv| alv[:current_state] == 'Waiting' }
      count = waiting.count
      waiting.nil? ? nil : ['waiting', 'WAITING', count]
    end

    def engaged_non_clinical_workflow(_active_user, list, _current_date, _role)
      engaged = list.select { |alv| alv[:current_state] == 'Engaged' }
      count = engaged.count
      engaged.nil? ? nil : ['engaged', 'ENGAGED', count]
    end

    def completed_non_clinical_workflow(_active_user, list, _current_date, _role)
      completed =  list.select { |alv| alv[:current_state] == 'Completed' }
      count = completed.count
      completed.nil? ? nil : ['completed', 'ALL COMPLETED', count]
    end

    def my_completed_non_clinical_workflow(active_user, list, _current_date, _role)
      completed = list.select do |alv|
        alv[:current_state] == 'Completed' && alv[:consulting_doctor_id] == BSON::ObjectId(active_user)
      end
      count = completed.count
      completed.nil? ? nil : ['my_completed', 'MY COMPLETED', count]
    end

    def incompleted_non_clinical_workflow(_active_user, list, _current_date, _role)
      incompleted =  list.select { |alv| alv[:current_state] == 'Incompleted' }
      count = incompleted.count
      incompleted.nil? ? nil : ['incomplete', 'INCOMPLETED', count]
    end
  end
end
