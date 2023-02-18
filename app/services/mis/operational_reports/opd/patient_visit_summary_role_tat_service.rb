module Mis::OperationalReports::Opd
  class PatientVisitSummaryRoleTatService
    class << self

      def call(opd_clinical_workflow, transitions, time_difference_proc)
        roles = Role.pluck(:name) + ['ophthal_investigation', 'radiology_investigation', 'laboratory_investigation', 'tpa_department']
        @display_patient_role_wise_tat = Hash[roles.product(["-"])]
        @patient_role_wise_tat_mins = Hash[roles.product(["-"])]
        @patient_role_wise_tat_secs = Hash[roles.product([0])]
        @transitions = transitions.map{ |t| add_end_time(t) }
        compute_start_end_time(@transitions)
        appointment_role_wise_tat(opd_clinical_workflow, @transitions, time_difference_proc, sec_time_diff_proc)
        return [@display_patient_role_wise_tat, @patient_role_wise_tat_mins, @patient_role_wise_tat_secs]
      end

      def compute_start_end_time(transitions)
        @transitions.each_with_index do |transition, index|
          if transition[4].nil?  # end time is nil then take start time of previous index and end time will be start time of current index.
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

      def appointment_role_wise_tat(opd_clinical_workflow, transitions, time_difference_proc, sec_time_diff_proc)
        transition_user_group_by = @transitions.group_by{ |transition_arr| transition_arr[2] } # Grouping by role_name from transitions array
        transition_user_group_by.each do |role, transition|
          transition_arr_nonil = transition.reject { |t| t[3].nil? || t[4].nil? }
          transition_arr_sum = transition_arr_nonil.map(&time_difference_proc).sum().round()
          transition_arr_sum_str = transition_arr_sum > 0 ? time_conversion_min_to_hrmin(transition_arr_sum) : "-"
          @display_patient_role_wise_tat["#{role}"] = transition_arr_sum_str
          @patient_role_wise_tat_mins["#{role}"] = transition_arr_sum > 0 ? "#{transition_arr_sum}" : "-"
          @patient_role_wise_tat_secs["#{role}"] = transition_arr_nonil.map(&sec_time_diff_proc).sum().round()
        end
      end

      private

      def sec_time_diff_proc
        Proc.new { |arr| TimeDifference.between(arr[4], arr[3]).in_seconds }
      end

      def add_end_time(t)
        if t[4].nil? && t[2] != 'incomplete' && t[2] != 'cancelled'
          [ t[0], t[1], t[2], t[3], Time.current, t[5] ]
        else
          t
        end
      end

      def  workflow_transition_to_name(dept_id)
        case dept_id
          when '309935007'
            'ophthal_investigation' 
          when '309964003'
            'radiology_investigation'
          when '261904005'
            'laboratory_investigation'
          when '50121007'
            'optical'
          when '284748001'
            'pharmacist'
          when '450368792'
            'tpa_department' 
          end
      end
    end
  end
end