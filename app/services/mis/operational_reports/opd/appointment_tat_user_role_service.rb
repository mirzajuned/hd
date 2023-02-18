module Mis::OperationalReports::Opd
  class AppointmentTatUserRoleService
    class << self

      def call(opd_clinical_workflow, transitions, time_difference_proc, workflow_waiting_disable = false, facility_qm = false)
        tat_for_appointment_user_role_data = []
        @transitions = transitions
        compute_start_end_time
        tat_for_appointment_user_role_data = appointment_user_role_wise_tat(opd_clinical_workflow, time_difference_proc, workflow_waiting_disable, facility_qm)
        return tat_for_appointment_user_role_data
      end

      def compute_start_end_time
        @transitions.each_with_index do |transition, index|
          if transition[0].nil? # user_id will be nil in cases where patient is transitoned from a user(ex ar_nct) to "away" state or to "complete" state.
            @transitions[index][0] = @transitions[index-1][0]
          elsif transition[4].nil?  # end time is nil then take start time of previous index and end time will be start time of current index.
            @transitions[index][4] = transition[3]
            @transitions[index][3] = @transitions[index-1][3]
          elsif transition[3].nil? # start time is nil then take end time of previous index.
            @transitions[index][3] = @transitions[index-1][4]
          end
        end
      end

      def time_conversion_min_to_hrmin(minutes)
        hours = minutes / 60
        mins = minutes % 60
        time_conversion_hrmin = "#{hours}:#{mins}"
        return time_conversion_hrmin
      end

      def appointment_user_role_wise_tat(opd_clinical_workflow, time_difference_proc, workflow_waiting_disable, facility_qm)
        all_roles = JSON.parse(Global.send("user_roles").to_json)
        departments = []
        appointment_user_role_wise_tat = []
        excluded_roles = ["admin", "owner"]
        transition_user_group_by = @transitions.group_by{ |transition_arr| transition_arr[0] } # Grouping by user_id from transitions array
        transition_user_group_by.each do |user_id, transition|
          tat_data_user_role = {}
          user = user_id.nil? ? nil : User.find(user_id)
          if user.nil?
            roles = [nil, "", ""]
          elsif user.present? && user.roles.present?
            roles = user.roles.pluck(:id, :name, :label).reject { |role| excluded_roles.include?(role[1]) }.flatten
          elsif user.present?
            roles = user.role_ids.map{|role_id| all_roles.select { |ele| ele == role_id.to_s }}
            roles = roles.map{|roles| roles.map{|role| [role[0], role[1]['name'], role[1]['label']]}}.flatten
          end
          department = Department.find_by(id: transition[0][5])
          departments = department.present? ? [department[:id], transition[0][5], department[:name]] : ['', '', '']
          # transition_arr_nonil = transition.reject { |arr| arr[2] != roles[1] }
          if workflow_waiting_disable == true
            transition_arr_nonil = if department.present? && transition[0][5].present?
                                        transition.reject { |arr| arr[5].to_s != department.id.to_s }
                                      else
                                        transition.reject { |arr| arr[2] != roles[1] }
                                      end
          else
            if facility_qm == true
              transition_arr_nonil = if department.present? && transition[0][5].present?
                                      transition.reject { |arr| arr[1] != 'call' || arr[5].to_s != department.id.to_s }
                                    else
                                      transition.reject { |arr| arr[1] != 'call' || arr[2] != roles[1] }
                                    end
            else
              transition_arr_nonil = if department.present? && transition[0][5].present?
                                      transition.reject { |arr| arr[1] != 'check_out' || arr[5].to_s != department.id.to_s }
                                    else
                                      transition.reject { |arr| arr[1] != 'check_out' || arr[2] != roles[1] }
                                    end
            end
          end
          transition_arr_sum = transition_arr_nonil.map(&time_difference_proc).sum().round()
          aggregated_tat_in_secs = transition_arr_nonil.map(&sec_time_diff_proc).sum().round()
          transition_arr_sum_str = transition_arr_sum > 0 ? time_conversion_min_to_hrmin(transition_arr_sum) : "-"
          tat_data_user_role = { user_id: "#{user_id}", user_name: "#{user[:fullname] rescue ''}", role_id: "#{roles[0]}", role_name: "#{roles[1]}", role_label: "#{roles[2]}", display_tat: "#{transition_arr_sum_str}", aggregated_tat_in_mins: transition_arr_sum, aggregated_tat_in_secs: aggregated_tat_in_secs, user_department_id: department.try(:id) }
          appointment_user_role_wise_tat.push(tat_data_user_role) 
        end
        return appointment_user_role_wise_tat
      end

      def sec_time_diff_proc
        Proc.new { |arr| TimeDifference.between(arr[4], arr[3]).in_seconds }
      end

    end
  end
end