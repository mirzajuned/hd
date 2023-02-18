module Mis::OperationalReports::Opd
  class PatientVisitSummaryTatService
    class << self

    def call(opd_clinical_workflow, transitions)
      clinical_worflow = []
      @transitions = transitions
      clinical_worflow = process_clinical_workflow(opd_clinical_workflow, transitions)
      return clinical_worflow
    end

    def compute_time_bw_transition_states(start_time, end_time)
      total_time = ''
      begin
        set_end_time = end_time.nil? ? Time.now : end_time
        time_hash = TimeDifference.between(set_end_time, start_time).in_general
                                  .delete_if { |unit, value| (value == 0 || ['hours', 'minutes'].exclude?(unit.to_s)) }
                                  .stringify_keys
        if time_hash['minutes'].to_i < 0
          time_hash['hours'] -= 1 if time_hash['hours'].present?
          time_hash['minutes'] += 60
        end
        time_hash.each { |k, v| total_time += "#{v} #{k.upcase[0]} " }
        total_time = '0 M' if total_time.blank?
      rescue StandardError
        total_time = 'NA'
      end
      total_time
    end

    def gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index=0, time_index=0, start_time_index=3, end_time_index=4)
      all_roles = JSON.parse(Global.send("user_roles").to_json)
      workflow_transition = {}
      from_to_other_states = { "not_arrived" => ["441968004", "not_arrived", "Not Arrived"], "away" => ["135793001", "away", "Away"], "complete" => ["255594003", "complete", "Completed"], "incomplete" => ["255599008", "incomplete", "Incomplete"], "" => ["", "", ""] }
      excluded_roles = ["admin", "owner"]
      from_roles_arr = to_roles_arr = ["", "", ""]
      from_roles_arr = from_to_other_states["#{@transitions[opd_wt_arr_index][1]}"] unless from_to_other_states["#{@transitions[opd_wt_arr_index][1]}"].nil?
      to_roles_arr = from_to_other_states["#{@transitions[opd_wt_arr_index][2]}"] unless from_to_other_states["#{@transitions[opd_wt_arr_index][2]}"].nil?
      # From User Id
      from_user_id = from_user_name = from_user = nil
      from_user_id =  if @transitions[opd_wt_arr_index-user_index][0].present?
                        @transitions[opd_wt_arr_index-user_index][0]
                      elsif opd_wt_arr[6] == 'station' && opd_wt_arr[7].present?
                        opd_wt_arr[7]
                      end
      from_user = if from_user_id.present? && opd_wt_arr[6] == 'user'
                    User.find_by(id: from_user_id)
                  end
      from_roles =  if opd_wt_arr[6] == 'station'
                      [opd_wt_arr[7], opd_wt_arr[8], opd_wt_arr[8]]
                    elsif from_user.present? && from_user.roles.present?
                      from_user.roles.pluck(:id, :name, :label).reject { |role| excluded_roles.include?(role[1]) }.flatten
                    elsif from_user.present?
                      role_array = from_user.role_ids.map{|role_id| all_roles.select { |ele| ele == role_id.to_s }}
                      role_array.map{|roles| roles.map{|role| [role[0], role[1]['name'], role[1]['label']]}}.flatten
                    else
                      from_roles_arr
                    end
      
      from_role = if from_roles.count > 0 && from_roles[2].present?
                    from_roles[2]
                  elsif opd_wt_arr[6] == 'user'
                    opd_wt_arr[2]
                  end
      from_user_name =  if from_user.try(:fullname).present?
                          from_user.try(:fullname)
                        elsif opd_wt_arr[8].present?
                          opd_wt_arr[8]
                        end
      from_id = if from_user.try(:id).present?
                  from_user.try(:id)
                elsif opd_wt_arr[6] == 'station'
                  opd_wt_arr[7]
                end

      # To User Id
      to_user_id = to_user_name = to_user = nil
      to_role = ''

      to_user_id = @transitions[opd_wt_arr_index][0] unless @transitions[opd_wt_arr_index][0].nil?
      to_user = if to_user_id.present?
                  User.find_by(id: to_user_id)
                end
      to_roles = if to_user.try(:id).nil? 
                    to_roles_arr 
                 else
                    to_user.roles.pluck(:id, :name, :label).reject { |role| excluded_roles.include?(role[1]) }.flatten
                 end
      to_role = if to_roles[1].present?
                  to_roles[1]
                else
                  opd_wt_arr[2]
                end
      to_user_name =  if to_user.try(:fullname).present?
                        to_user.try(:fullname)
                      elsif opd_wt_arr[6] == 'station' && opd_wt_arr[8].present?
                        (opd_wt_arr[9].present?) ? "#{opd_wt_arr[8]} (#{opd_wt_arr[9]})" : opd_wt_arr[8]
                      end
      to_user_name = "#{to_user_name} (#{opd_wt_arr[11]})" if opd_wt_arr[11].present?
      to_id = if to_user.present?
                "#{to_user.try(:id)}"
              elsif opd_wt_arr[6] == 'station' && opd_wt_arr[7].present?
                opd_wt_arr[7].to_s
              end
      start_time = end_time = Time.now
      start_time = @transitions[opd_wt_arr_index-time_index][start_time_index] unless @transitions[opd_wt_arr_index-time_index][start_time_index].nil?
      end_time = @transitions[opd_wt_arr_index][end_time_index] unless @transitions[opd_wt_arr_index][end_time_index].nil?

      time_diff = compute_time_bw_transition_states(start_time, end_time)
      workflow_transition = { display_user_name: "#{from_user_name}", from_name: "#{from_user_name}", to_name: "#{to_user_name}", from_id: "#{from_id}", to_id: "#{to_id}", display_role_name: "#{from_role}", from_role: "#{from_role}", to_role: "#{to_role}", from_role_id: "#{from_roles[0]}", to_role_id: "#{to_roles[0]}", time_diff: "#{time_diff}", from: opd_wt_arr[1], to: opd_wt_arr[2], department_id: opd_wt_arr[5] }
      return workflow_transition
    end

    def process_clinical_workflow(opd_clinical_workflow, transitions)
      clinical_worflow = []
      @transitions.each_with_index do |opd_wt_arr, opd_wt_arr_index|
        next if opd_wt_arr[2] == 'cancelled'
        workflow_transition = {}
        user_index_offset = 0
        time_index_offest = 0
        start_time_index_offset = 3
        end_time_index_offset = 4
        if opd_wt_arr[0].nil?
          if opd_wt_arr[1] == "not_arrived"
            user_index_offset = 1
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[1] == "away"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[1] == "complete"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[1] == "incomplete"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "not_arrived"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "away"
            user_index_offset = 1
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "complete"
            user_index_offset = time_index_offest = 1
            start_time_index_offset = end_time_index_offset = 3
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "incomplete"
            user_index_offset = time_index_offest = 1
            start_time_index_offset = end_time_index_offset = 3
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[6] == 'station'
            user_index_offset = 1   
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          else
            user_index_offset = 1   
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            workflow_transition[:to_name] = workflow_transition_to_name(opd_wt_arr[5])
            clinical_worflow.push(workflow_transition)
          end
        else
          if opd_wt_arr[1] == "not_arrived"
            user_index_offset = 1
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[1] == "away"
            user_index_offset = 1
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[1] == "complete"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[1] == "incomplete"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)  
          elsif opd_wt_arr[2] == "not_arrived"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "away"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "complete"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          elsif opd_wt_arr[2] == "incomplete"
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          else
            user_index_offset = 1
            workflow_transition = gen_clinical_workflow_hash(opd_wt_arr, opd_wt_arr_index, user_index_offset, time_index_offest, start_time_index_offset, end_time_index_offset)
            clinical_worflow.push(workflow_transition)
          end
        end
      end
      return clinical_worflow
    end

    def  workflow_transition_to_name(dept_id)
      case dept_id
        when '309935007'
          'Ophthalmology Investigation' 
        when '309964003'
          'Radiology Investigation'
        when '261904005'
          'Laboratory Investigation'
        when '50121007'
          'Optical Shop'
        when '284748001'
          'Pharmacy Shop'
        when '450368792'
          'TPA Department' 
        end 
      end
    end
  end
end