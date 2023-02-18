class Api::V2::AppointmentListsService
  class << self
    def clinical_all(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = if params[:custom_filter].present?
               # list = list.where(:state.nin => ['complete', 'not_arrived'])
               apply_clinical_custom_filter(params, list).skip(skip).limit(limit)
             else
               # list = list.where(:state.nin => ['complete', 'not_arrived']).skip(skip).limit(limit)
               list.skip(skip).limit(limit)
             end

      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_myqueue(params, list, current_user, active_user)
      skip, limit = skip_limit_value(params)
      list = if active_user == 'all' || active_user.blank?
               list.where(:state.nin => ['complete', 'not_arrived']).skip(skip).limit(limit)
             else
               list.where(state: current_user.primary_role, user_id: active_user).skip(skip).limit(limit)
             end
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_refferral(params, list, current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = if current_user.role_ids.any? { |ele| [159561009, 59561000, 159562000].include?(ele) }
               list.where(referral: true).skip(skip).limit(limit)
             else
               list.where(referral: true, doctor_ids: current_user.id.to_s).skip(skip).limit(limit)
              end
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_in_progress(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      if params[:custom_filter].present?
        list = list.where(:state.nin => ['complete', 'not_arrived', 'receptionist', 'waiting'])
        list = apply_clinical_custom_filter(params, list).skip(skip).limit(limit)
      else
        list = list.where(:state.nin => ['complete', 'not_arrived', 'receptionist', 'waiting']).skip(skip).limit(limit)
      end
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_incomplete(params, list, _current_user, active_user)
      skip, limit = skip_limit_value(params)
      list = if active_user == 'all' || active_user.blank?
               list.where(state: 'incomplete').skip(skip).limit(limit)
             else
               list.where(state: 'incomplete', user_id: active_user).skip(skip).limit(limit)
             end
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_complete(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(state: 'complete').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_my_complete(params, list, _current_user, active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(state: 'complete', :doctor_ids.in => [active_user]).skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def clinical_not_arrived(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(state: 'not_arrived').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_myqueue(params, list, _current_user, active_user)
      skip, limit = skip_limit_value(params)
      myqueue = list.where(:current_state.ne => 'complete').skip(skip).limit(limit)
      list = if active_user == 'all' || active_user.blank?
               myqueue
             else
               list.where(scheduling_user_id: active_user).skip(skip).limit(limit)
             end
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_scheduled(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(current_state: 'Scheduled').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_waiting(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(current_state: 'Waiting').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_engaged(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(current_state: 'Engaged').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_completed(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(current_state: 'Completed').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_my_completed(params, list, _current_user, active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(current_state: 'Completed', consulting_doctor_id: BSON::ObjectId(active_user)).skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_incompleted(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = list.where(current_state: 'Incompleted').skip(skip).limit(limit)
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    def non_clinical_all(params, list, _current_user, _active_user)
      skip, limit = skip_limit_value(params)
      list = if params[:custom_filter].present?
               # list = list.where(:current_state.in => ['Scheduled', 'Waiting', 'Engaged'])
               apply_non_clinical_custom_filter(params, list).skip(skip).limit(limit)
             else
               # list = list.where(:current_state.in => ['Scheduled', 'Waiting', 'Engaged']).skip(skip).limit(limit)
               list.skip(skip).limit(limit)
             end
      patient_params = fetch_patient_params(list.pluck(:patient_id))
      [list, patient_params]
    end

    private

    def fetch_patient_params(patient_ids)
      patients = Patient.where(:id.in => patient_ids)
      @patient_fields = patients.map do |patient|
        age_year, age_month = patient.calculate_age(true)
        title_content = ''
        title_content += 'One Eyed' if patient.one_eyed == 'Yes'
        age_in_months = (age_year.to_i * 12) + age_month.to_i
        if age_year.present? && (49...960).exclude?(age_in_months)
          title_content += ' | ' if patient.one_eyed == 'Yes'
          title_content += age_year < 4 ? 'Baby' : 'Old Age'
        end
        bang = !title_content.empty?
        { id: patient.id.to_s, bang: bang, title: title_content }
      end
    end

    def apply_clinical_custom_filter(params, list)
      user = params[:user] # 'doctor' or 'optometrist'
      user_ids = params[:user_ids]
      list = case user
             when 'doctor'
               list = list.where(state: 'doctor')
               list.where(:doctor_ids.in => user_ids) if user_ids.present?
             when 'optometrist'
               list = list.where(state: 'optometrist')
               list.where(:optometrist_ids.in => user_ids) if user_ids.present?
             when 'counsellor'
               list.where(state: 'counsellor')
             else
               list
             end
      # list = list.order('appointment_start_time ASC') # order alphabetcally
    end

    def apply_non_clinical_custom_filter(params, list)
      user = params[:user] # 'doctor' or 'optometrist'
      user_id = params[:user_id] # decide string or array
      list = case user
             when 'doctor'
               list.where(scheduling_user_id: user_id) if user_id.present?
             when 'optometrist'
               list.where(scheduling_user_id: user_id) if user_id.present?
             else
               list
             end
      # list = list.order('appointment_start_time ASC') # order alphabetcally
    end

    def skip_limit_value(params)
      limit = params[:limit].present? ? params[:limit].to_i : 20
      skip = if params[:page_num].present?
               limit * (params[:page_num].to_i - 1)
             else
               0
             end
      [skip, limit]
    end
  end
end
