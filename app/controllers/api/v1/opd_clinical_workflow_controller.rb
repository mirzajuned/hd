module Api
  module V1
    class OpdClinicalWorkflowController < ApiApplicationController
      before_action :authorize_token

      def checkout
        workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
        transitions = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
        appointment_id = workflow.appointment_id.to_s
        @appointment = Appointment.find_by(id: appointment_id)
        if params[:send_to_department].present?
          department = Department.find_by(id: params[:to_department])
          if params[:department_model].present?
            if params[:department_model] == 'Investigation::Queue'
              record = Investigation::Queue.find_by(patient_id: params[:patient_id], investigation_type: params[:type])
              record&.update(appointment_id: appointment_id, appointment_date: Date.current, appointment_time: Time.current)
            else
              record = params[:department_model].constantize.find_by(appointment_id: appointment_id)
            end
            if record.present?
              @record_found = true
              record.update(my_queue: true)
              workflow.update!(department_id: department.id.to_s, with_department: department.name, user_id: nil,
                               in_department: true, with_user: nil, with_user_role: nil)
              workflow.check_out
            else
              @record_found = false
            end
          elsif params[:to_department] == '450368792' # TPA department
            workflow.update!(department_id: department.id.to_s, with_department: department.name, user_id: nil,
                             in_department: true, with_user: nil, with_user_role: nil)
            workflow.check_out
          end

          @to_department = true
          @to_id = params[:to_department]
        else
          to_user = User.find_by(id: params[:to_user])
          workflow.update!(user_id: to_user.id, with_user: to_user.fullname, with_user_role: to_user.primary_role,
                           department_id: nil, with_department: nil, in_department: false)
          workflow.check_out

          @to_department = false
          @to_id = params[:to_user]
        end

        second_last_state = transitions.all[-2]
        if second_last_state.present? && second_last_state.department_id.present?
          @find_department_id = second_last_state.department_id
          @state = second_last_state
          find_department_update_status
          if @department_prescription.present? && second_last_state.event != 'check_out'
            @department_prescription.update(my_queue: false)
          end
        end

        if second_last_state&.user_id.present?
          @from_department = false
          @from_id = second_last_state&.user_id
          update_redis_counter(workflow.specialty_id)
        elsif second_last_state&.department_id.present?
          @from_department = true
          @from_id = second_last_state&.department_id
          update_redis_counter(workflow.specialty_id)
        end

        Patients::Summary::TimelineWorker.call(
          event_name: 'OPD_APPOINTMENT', sub_event_name: 'CHECKOUT', appointment_id: workflow.appointment_id,
          user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true
        )
      end

      # def change_state
      #   workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
      #   # current_user = User.find_by(id: params[:current_user_id])
      #   @appointment = Appointment.find_by(id: workflow.appointment_id)
      #   from = workflow.state
      #   to = params[:to].to_s

      #   if params[:send_to_department]
      #     department_id = params[:to_department]
      #     department = Department.find_by(id: department_id)
      #     @all_appointments = Appointment.where(patient_id: params[:patient_id]).order(created_at: :desc)

      #     # updating latest appointment_id
      #     if params[:department_model] == "Investigation::Queue"
      #       if @all_appointments.count > 1
      #         @precription = Investigation::Queue.find_by(patient_id: params[:patient_id], investigation_type: params[:type])
      #         if @precription.present?
      #           @precription.update(appointment_id: @all_appointments[0].id.to_s, appointment_date: Date.current, appointment_time: Time.current)
      #         end
      #       end
      #       record_present = Investigation::Queue.find_by(appointment_id: workflow.appointment_id.to_s, investigation_type: params[:type])
      #     # else
      #     #   record_present = eval(params[:department_model]).find_by(appointment_id: workflow.appointment_id)
      #     elsif params[:department_model] == 'PatientPrescription'
      #       record_present = PatientPrescription.find_by(appointment_id: workflow.appointment_id)
      #     elsif params[:department_model] == 'PatientOpticalPrescription'
      #       record_present = PatientOpticalPrescription.find_by(appointment_id: workflow.appointment_id)
      #     end

      #     if record_present
      #       @record_found = true
      #       update_redis = true
      #       update_pst = true
      #       doctor_arr = workflow.doctor_ids
      #       optometrist_arr = workflow.optometrist_ids
      #       record_present.update(my_queue: true)

      #       workflow.update(department_id: department_id, with_department: department.name, user_id: nil, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr, in_department: true)
      #       unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:department_id) == workflow.try(:department_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
      #         workflow.send(from + '_to_' + to)
      #       end
      #     else
      #       @record_found = false
      #     end
      #   else
      #     to_user = params[:to_user].to_s
      #     to_user_name = User.find_by(id: to_user)
      #     update_redis = true
      #     update_pst = true
      #     @record_found = true

      #     if to_user_name.role_ids.include? 158965000
      #       doctor_arr = workflow.doctor_ids
      #       if doctor_arr.size == 1 and !workflow.opd_clinical_workflow_state_transitions.pluck(:to).include? 'doctor'
      #         doctor_arr.shift
      #       end
      #       doctor_arr << to_user_name.id.to_s
      #     else
      #       doctor_arr = workflow.doctor_ids
      #     end
      #     doctor_arr = doctor_arr.uniq

      #     if to_user_name.role_ids.include? 28229004
      #       optometrist_arr = workflow.optometrist_ids

      #       if optometrist_arr.blank?
      #         optometrist_arr = []
      #         optometrist_arr << to_user_name.id.to_s
      #       end
      #     else
      #       optometrist_arr = workflow.optometrist_ids
      #     end

      #     workflow.update(department_id: nil, with_department: nil, in_department: false, user_id: to_user, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr)

      #     unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:user_id) ==  workflow.try(:user_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
      #       workflow.send(from + '_to_' + to)
      #     end
      #   end

      #   transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id).order(created_at: :asc)
      #   @last_state = transitions.all[-1]
      #   @second_last_state = transitions.all[-2]

      #   if @second_last_state.present?
      #     if @second_last_state.department_id.present?
      #       @state = @second_last_state
      #       @find_department_id = @second_last_state.department_id
      #       find_department_update_status
      #       if @department_prescription.present?
      #         @department_prescription.update(my_queue: false)
      #       end
      #       @from_id = @second_last_state.department_id
      #       @from_department = true
      #     else
      #       @from_id = @second_last_state.user_id
      #       @from_department = false
      #     end
      #   end

      #   if @last_state.department_id.present?
      #     @state = @last_state
      #     @find_department_id = @last_state.department_id
      #     find_department_update_status
      #     if @department_prescription.present?
      #       @department_prescription.update(my_queue: true)
      #     end
      #     @to_id = @last_state.department_id
      #     @to_department = true
      #   else
      #     @to_id = @last_state.user_id
      #     @to_department = false
      #   end

      #   if params[:to] == "counsellor"
      #     create_update_counsellor_workflow(workflow)
      #   end

      #   if params[:referral] == "true"
      #     if workflow.referral_details
      #       ref_details = workflow.referral_details.clone
      #     else
      #       ref_details = Hash.new
      #     end
      #     ref_details[current_user.id.to_s + "_" + ref_details.size.to_s] = [current_user.fullname, params[:referralnote], Time.current, to_user_name.fullname]
      #     reverse_hash = Hash[ref_details.to_a.reverse]
      #     workflow.update(referral: true, :referral_details => reverse_hash)
      #   end

      #   if update_redis == true
      #     update_redis_counter
      #   end

      #   if update_pst == true
      #     Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "WORKFLOW", appointment_id: workflow.appointment_id, user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true })
      #   end
      # end

      def change_state
        workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
        # current_user = User.find_by(id: params[:current_user_id])
        @appointment = Appointment.find_by(id: workflow.appointment_id)
        consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
        from = workflow.state
        to = params[:to].to_s

        if params[:send_to_department]
          department_id = params[:to_department]
          department = Department.find_by(id: department_id)
          @all_appointments = Appointment.where(patient_id: params[:patient_id]).order(created_at: :desc)

          # updating latest appointment_id
          if params[:department_model] == "Investigation::Queue"
            if @all_appointments.count > 1
              @precription = Investigation::Queue.find_by(patient_id: params[:patient_id], investigation_type: params[:type])
              if @precription.present?
                @precription.update(appointment_id: @all_appointments[0].id.to_s, appointment_date: Date.current, appointment_time: Time.current)
              end
            end
            record_present = Investigation::Queue.find_by(appointment_id: workflow.appointment_id.to_s, investigation_type: params[:type])
          else
            record_present = eval(params[:department_model]).find_by(appointment_id: workflow.appointment_id)
          end

          if record_present
            @record_found = true
            update_redis = true
            update_pst = true
            doctor_arr = workflow.doctor_ids.uniq
            consultant_arr = workflow.consultant_ids.uniq
            optometrist_arr = workflow.optometrist_ids.uniq
            record_present.update(my_queue: true)

            workflow.update(department_id: department_id, with_department: department.name, user_id: nil, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr, in_department: true, consultant_ids: doctor_arr, in_department: true)

            if workflow.state == 'check_out'
              workflow.send("check_in_#{to}")
            else
              unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:department_id) == workflow.try(:department_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
                workflow.send(from + '_to_' + to)
              end
            end
          else
            @record_found = false
          end
        else
          to_user = params[:to_user].to_s
          to_user_name = User.find_by(id: to_user)
          update_redis = true
          update_pst = true
          @record_found = true

          if to_user_name.role_ids.include? 158965000
            doctor_arr = workflow.doctor_ids
            if doctor_arr.size == 1 and !workflow.opd_clinical_workflow_state_transitions.pluck(:to).include? 'doctor'
              doctor_arr.shift
            end
            doctor_arr << to_user_name.id.to_s
          else
            doctor_arr = workflow.doctor_ids
          end
          doctor_arr = doctor_arr.uniq

          if to_user_name.role_ids.include? 28229004
            optometrist_arr = workflow.optometrist_ids

            if optometrist_arr.blank?
              optometrist_arr = []
            end
            optometrist_arr << to_user_name.id.to_s
          else
            optometrist_arr = workflow.optometrist_ids
          end

          if consultant_id_role_ids.include? 28229004
            consultant_arr = optometrist_arr
          else
            consultant_arr = doctor_arr
          end
          consultant_arr = consultant_arr.uniq

          workflow.update(department_id: nil, with_department: nil, in_department: false, user_id: to_user, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role, doctor_ids: doctor_arr, consultant_ids: consultant_arr, optometrist_ids: optometrist_arr)

          if workflow.state == 'check_out'
            workflow.send("check_in_#{to}")
          else
            unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:user_id) ==  workflow.try(:user_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
              workflow.send(from + '_to_' + to)
            end
          end
        end

        transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id).order(created_at: :asc)
        @last_state = transitions.all[-1]
        @second_last_state = transitions.all[-2]

        if @last_state.present?
          if @last_state.department_id.present?
            @state = @last_state
            @find_department_id = @last_state.department_id
            find_department_update_status
            if @department_prescription.present?
              @department_prescription.update(my_queue: true)
            end
            # @to_id = @last_state.department_id
            # @to_department = true
          else
            # @to_id = @last_state.user_id
            # @to_department = false
          end
        end

        if @second_last_state.present?
          if @second_last_state.department_id.present?
            @state = @second_last_state
            @find_department_id = @second_last_state.department_id
            find_department_update_status
            if @department_prescription.present? && @second_last_state.event != 'check_out'
              @department_prescription.update(my_queue: false)
            end
            # @from_id = @second_last_state.department_id
            # @from_department = true
          else
            # @from_id = @second_last_state.user_id
            # @from_department = false
          end
        end

        if params[:to] == "counsellor"
          create_update_counsellor_workflow(workflow)
        end

        if params[:referral] == "true"
          if workflow.referral_details
            ref_details = workflow.referral_details.clone
          else
            ref_details = Hash.new
          end
          ref_details[current_user.id.to_s + "_" + ref_details.size.to_s] = [current_user.fullname, params[:referralnote], Time.current, to_user_name.fullname]
          reverse_hash = Hash[ref_details.to_a.reverse]
          workflow.update(referral: true, :referral_details => reverse_hash)
        end

        if update_redis == true
          update_redis_counter(workflow.specialty_id)
        end

        if update_pst == true
          Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "WORKFLOW", appointment_id: workflow.appointment_id, user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true })
        end
      end

      def get_patient
        workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
        @appointment = Appointment.find_by(id: workflow.appointment_id)
        consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
        from = workflow.state
        to = params[:to].to_s

        if params[:to_user].present?
          to_user = params[:to_user].to_s
          to_user_name = User.find_by(id: to_user)

          if to_user_name.role_ids.include? 158965000
            doctor_arr = workflow.doctor_ids
            if doctor_arr.size == 1 and !workflow.opd_clinical_workflow_state_transitions.pluck(:to).include? 'doctor'
              doctor_arr.shift
            end
            doctor_arr << to_user_name.id.to_s
          else
            doctor_arr = workflow.doctor_ids
          end
          doctor_arr = doctor_arr.uniq

          if to_user_name.role_ids.include? 28229004
            optometrist_arr = workflow.optometrist_ids

            if optometrist_arr.blank?
              optometrist_arr = []
            end  
            optometrist_arr << to_user_name.id.to_s
          else
            optometrist_arr = workflow.optometrist_ids
          end
          
          if consultant_id_role_ids.include? 28229004
            consultant_arr = optometrist_arr
          else
            consultant_arr = doctor_arr
          end
          consultant_arr = consultant_arr.uniq

          workflow.update(department_id: nil, with_department: nil, in_department: false, user_id: to_user, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role, doctor_ids: doctor_arr, consultant_ids: consultant_arr, optometrist_ids: optometrist_arr)

          if workflow.state == 'check_out'
            workflow.send("check_in_#{to}")
          else
            unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:user_id) ==  workflow.try(:user_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
              workflow.send("#{from}_to_#{to}")
            end
          end
        elsif params[:to_department].present?
          @department_id = params[:to_department]
          @department = Department.find_by(id: @department_id)
          to = find_department
          doctor_arr = workflow.doctor_ids.uniq
          optometrist_arr = workflow.optometrist_ids.uniq
          consultant_arr = workflow.consultant_ids.uniq

          workflow.update(department_id: @department_id, with_department: @department.name, user_id: nil, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr, in_department: true, consultant_ids: consultant_arr)
          if workflow.state == 'check_out'
            workflow.send("check_in_#{to}")
          else
            unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:department_id) == workflow.try(:department_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
              workflow.send("#{from}_to_#{to}")
            end
          end
        end

        transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id).order(created_at: :asc)
        @last_state = transitions.all[-1]
        @second_last_state = transitions.all[-2]

        if @last_state.department_id.present?
          @state = @last_state
          @find_department_id = @last_state.department_id
          find_department_update_status
          if @department_prescription.present?
            @department_prescription.update(my_queue: true)
          end
          @to_department = true
          @to_id = @last_state.department_id
        else
          @to_department = false
          @to_id = @last_state.user_id
        end

        if @second_last_state.present?
          if @second_last_state.department_id.present?
            @state = @second_last_state
            @find_department_id = @second_last_state.department_id
            find_department_update_status
            if @department_prescription.present?
              @department_prescription.update(my_queue: false)
            end
            @from_department = true
            @from_id = @second_last_state.department_id
          else
            @from_department = false
            @from_id = @second_last_state.user_id
          end
        end

        update_redis_counter(workflow.specialty_id)

        Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "WORKFLOW", appointment_id: workflow.appointment_id, user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true })
      end

      def has_arrived
        @source = params[:source]
        @appointment_id = params[:appointment_id]
        @appointment = Appointment.find_by(id: @appointment_id)
        consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
        workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment_id)
        @current_user = User.find_by(id: params[:current_user_id])
        current_user_primary_role = @current_user.primary_role
        if @current_user.role_ids.include? 158965000
          if consultant_id_role_ids.include? 158965000
            doctor_arr = workflow.consultant_ids
          else
            doctor_arr = workflow.doctor_ids
          end
          doctor_arr.pop unless doctor_arr.size == 1
          doctor_arr << @current_user.id.to_s
        else
          if consultant_id_role_ids.include? 158965000
            doctor_arr = workflow.consultant_ids
          else
            doctor_arr = workflow.doctor_ids
          end
        end
        doctor_arr = doctor_arr.uniq

        if @current_user.role_ids.include? 28229004
          optometrist_arr = workflow.optometrist_ids
          optometrist_arr << @current_user.id.to_s
        else
          optometrist_arr = workflow.optometrist_ids
        end

        if consultant_id_role_ids.include? 28229004
          consultant_arr = optometrist_arr
        else
          consultant_arr = doctor_arr
        end
        consultant_arr = consultant_arr.uniq

        # create_update_counsellor_workflow(workflow) if @current_user.role_ids.include?499992366

        workflow.update_attributes(in_department: false, department_id: nil, start_time: Time.current, user_id: @current_user.id.to_s, with_user: @current_user.fullname, with_user_role: @current_user.primary_role, optometrist_ids: optometrist_arr, doctor_ids: doctor_arr, consultant_ids: consultant_arr)

        @patient = Patient.find_by(id: @appointment.patient_id)
        @patient.inc(opd_visit_count: 1)
        @opd_visit_count = @patient.try(:opd_visit_count).to_i
        @appointment.update_attributes(visit_no: @opd_visit_count, arrived: true, start_time: Time.current)

        ::Analytics::Appointment::UpdateService.patient_arrived(@appointment.id.to_s, @current_user.id.to_s, @appointment.facility_id.to_s)

        if workflow.try(:not_arrived?)
          workflow.send("arrived_to_" + current_user_primary_role)
        end

        transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id).order(created_at: :asc)
        @last_state = transitions.all[-1]

        @from_department = nil
        if @last_state.department_id.present?
          @to_department = true
          @to_id = @last_state.department_id
        else
          @to_department = false
          @to_id = @last_state.user_id
        end
        # end

        update_redis_counter(workflow.specialty_id)

        Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "ARRIVED", appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: true })
        Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "WORKFLOW", appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: true })
      end

      def mark_as_not_arrived
        @source = params[:source]
        current_user = User.find(params[:current_user_id])
        @appointment_id = params[:appointment_id]
        @appointment =  Appointment.find_by(id: params[:appointment_id])
        workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
        @all_states = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id)

        if @all_states.all[-1].department_id.present?
          @from_department = true
          @from_id = @all_states.all[-1].department_id.to_s
        else
          @from_department = false
          @from_id = @all_states.all[-1].user_id.to_s
        end
        @to_department = nil

        if @all_states.size > 0
          @all_states.destroy_all
        end

        workflow.update(state: 'not_arrived', user_id: nil, with_user: nil, with_user_role: nil)
        @patient = Patient.find_by(id: @appointment.patient_id)
        @patient.inc(opd_visit_count: -1)

        ::Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, current_user.id.to_s, @appointment.facility_id.to_s)

        @appointment.update_attributes(visit_no: nil, arrived: false, start_time: Time.current)

        update_redis_counter(workflow.specialty_id)

        pst = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", query: { _id: @appointment.id.to_s })
        pst1 = pst.where(sub_event_name: "WORKFLOW").delete_all
        pst2 = pst.where(sub_event_name: "ARRIVED").delete_all
        pst3 = pst.where(sub_event_name: "EDITED").update_all(links: { appointment: workflow.attributes })
        pst4 = pst.where(sub_event_name: "RESCHEDULED").update_all(links: { appointment: workflow.attributes })
      end

      def patient_complete
        @source = params[:source]
        current_user = User.find(params[:current_user_id])
        @appointment_id = params[:appointment_id]
        @appointment = Appointment.find_by(id: @appointment_id)
        @workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
        @workflow.complete
        @transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @workflow.id).order(created_at: :asc)
        @workflow.update(user_id: nil, department_id: nil, in_department: false, end_time: Time.current)
        @last_transition = @transitions.all[-1]
        @second_last_transition = @transitions.all[-2]
        @last_transition.update(user_id: nil, department_id: nil)

        if @second_last_transition.present?
          if @second_last_transition.department_id.present?
            @find_department_id = @second_last_transition.department_id
            @state = @second_last_transition
            find_department_update_status
            @department_prescription.update(my_queue: false)

            @department_id = @find_department_id
            last_state_name = find_department
            @from_department = true
            @from_id = @second_last_transition.department_id
          else
            last_state_name = User.find_by(id: @second_last_transition.user_id).fullname
            @from_department = false
            @from_id = @second_last_transition.user_id
          end
        end
        @to_department = nil
        counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: params[:appointment_id])
        if counsellor_workflow != nil
          counsellor_workflow.update_attributes(end_time: Time.current)
        end

        # Update Redis Counter
        update_redis_counter(@workflow.specialty_id)

        # Stop Dilatation
        if @appointment.dilation_start_time != nil && @appointment.dilation_end_time == nil
          @appointment.update_attributes(dilation_end_time: Time.current)
        end
        Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "COMPLETED", appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: true })
      end

      def mark_as_away
        @source = params[:source]
        current_user = User.find(params[:current_user_id])
        @appointment_id = params[:appointment_id]
        @appointment =  Appointment.find_by(id: params[:appointment_id])
        workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment_id)
        current_user_role = current_user.primary_role
        workflow.send(current_user_role + "_to_away")
        workflow.update(calculate_away_time: true)

        @transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id)
        @last_transition = @transitions.all[-1]
        @second_last_transition = @transitions.all[-2]

        @last_transition.update(user_id: nil, department_id: nil)

        if @second_last_transition.department_id.present?
          @find_department_id = @second_last_transition.department_id
          @state = @second_last_transition
          find_department_update_status
          @department_prescription.update(my_queue: false)

          @department_id = @find_department_id
          last_state_name = find_department

          @from_department = true
          @from_id = @second_last_transition.department_id
        else
          last_state_name = User.find_by(id: @second_last_transition.user_id).fullname
          @from_department = false
          @from_id = @second_last_transition.user_id
        end

        @to_department = nil

        update_redis_counter(workflow.specialty_id)

        Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "AWAY", appointment_id: @appointment_id, user_id: current_user.id, user_name: current_user.fullname, workflow: true })
      end

      def undo_state
        @source = params[:source]
        @appointment = Appointment.find_by(id: params[:appointment_id])
        @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        doctor_arr = Array.new
        @all_states = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @workflow.id)

        # making last record as from_state for redis counters update
        @last_state = @all_states[-1]

        if @last_state.department_id.present?
          @find_department_id = @last_state.department_id
          @state = @last_state
          find_department_update_status
          if @department_prescription.present?
            @department_prescription.update(my_queue: false)
          end
          @from_id = @last_state.department_id
          @from_department = true
        else
          @from_id = @last_state.user_id
          @from_department = false
        end

        # making second last record as to_state for redis counters update and main opd_clinical_workflow
        @second_last_state = @all_states[-2]

        if @second_last_state.department_id.present?
          in_department = true
          @state = @second_last_state
          @find_department_id = @second_last_state.department_id
          find_department_update_status
          if @department_prescription.present?
            @department_prescription.update(my_queue: true)
          end
          @to_id = @second_last_state.department_id
          @to_department = true
        else
          in_department = false
          @to_id = @second_last_state.user_id
          @to_department = false
        end

        @last_user = User.find_by(id: @all_states[-1].user_id)
        if @last_user.present? && @last_user != nil
          if @last_user.role_ids.include? 158965000
            doctor_arr = @workflow.doctor_ids
            doctor_arr.pop unless doctor_arr.size > 0
          end
        end

        if current_user.role_ids.include? 158965000
          doctor_arr = @workflow.doctor_ids
          doctor_arr << current_user.id.to_s
        else
          doctor_arr = @workflow.doctor_ids
        end

        @workflow.update(user_id: @second_last_state.user_id, department_id: @second_last_state.department_id, in_department: in_department, doctor_ids: doctor_arr, consultant_ids: doctor_arr, with_user: current_user.fullname, with_user_role: current_user.primary_role, state: @second_last_state.to, end_time: nil)
        @last_state.delete

        # Update Redis Counter
        update_redis_counter(@workflow.specialty_id)

        SmsJob.perform_later("cancel_sms", @workflow.id.to_s, "OpdClinicalWorkflow")
        respond_to do |format|
          format.js {}
        end

        pstc = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", sub_event_name: "COMPLETED", query: { _id: @appointment.id.to_s })
        if pstc.count > 0
          pstc.delete_all
          new_pstc = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", query: { _id: @appointment.id.to_s }).order(created_at: :desc)[0]
          new_pstc.update(is_active: true) if new_pstc
        else
          pstw = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", sub_event_name: "WORKFLOW", query: { _id: @appointment.id.to_s }).order(created_at: :desc)[0]
          pstw.delete if pstw
          new_pstw = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", sub_event_name: "WORKFLOW", query: { _id: @appointment.id.to_s }).order(created_at: :desc)[0]
          new_pstw.update(is_active: true) if new_pstw
        end
      end

      def mark_as_arrived
        @facility = Facility.find_by(id: params[:current_facility_id].to_s)
        @appointment = Appointment.find_by(id: params[:appointment_id].to_s)
        @current_date = params[:current_date]
        @current_user = User.find(params[:current_user_id])
        @appointment_list_view = AppointmentListView.find_by(appointment_id: params[:appointment_id])
        workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
        if params[:patient_arrived].to_s == "true"
          @patient = Patient.find_by(id: @appointment.patient_id)
          @patient.inc(opd_visit_count: 1)
          @opd_visit_count = @patient.try(:opd_visit_count).to_i

          @appointment.update(current_state: "waiting", arrived_time: Time.current, visit_no: @opd_visit_count, arrived: true, start_time: Time.current)

          ::Analytics::Appointment::UpdateService.patient_arrived(@appointment.id.to_s, @current_user.id.to_s, @appointment.facility_id.to_s)

          @active_tab = "waiting"
          if workflow.try(:not_arrived?)
            workflow.send("arrived_to_" + @active_tab)
          end
          workflow.update_attributes(start_time: Time.current, user_id: @current_user.id.to_s, with_user: @current_user.fullname, with_user_role: @current_user.primary_role)
        else
          @patient = Patient.find_by(id: @appointment.patient_id)
          @patient.inc(opd_visit_count: -1)

          ::Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, @current_user.id.to_s, @appointment.facility_id.to_s)

          @appointment.update(current_state: "scheduled", arrived_time: nil, visit_no: nil, arrived: false, start_time: Time.current)
          @active_tab = "scheduled"
          @all_states = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
          @all_states.destroy_all
          workflow.update(state: 'not_arrived', user_id: nil, with_user: nil, with_user_role: nil)
        end

        if params[:patient_arrived].to_s == "true"
          Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "ARRIVED", appointment_id: @appointment.id, user_id: @current_user.id, user_name: @current_user.fullname })
        else
          pst = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", query: { _id: @appointment.id.to_s })
          pst1 = pst.where(sub_event_name: "ARRIVED").delete_all
          @appointment_list_view.update(current_state: "Scheduled") # Temp Hack
          pst3 = pst.where(sub_event_name: "EDITED").update_all(links: { appointment: @appointment_list_view.attributes })
          pst4 = pst.where(sub_event_name: "RESCHEDULED").update_all(links: { appointment: @appointment_list_view.attributes })
        end
      end

      def patient_engaged
        @facility = Facility.find_by(id: params[:current_facility_id].to_s)
        @appointment = Appointment.find_by(id: params[:appointment_id].to_s)
        @current_date = params[:current_date]
        @current_user = User.find(params[:current_user_id])
        @appointment_list_view = AppointmentListView.find_by(appointment_id: params[:appointment_id])
        workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
        if params[:patient_engaged].to_s == "true"
          @appointment.update(current_state: "engaged", engage_time: Time.current)
          @active_tab = "engaged"
          workflow.send("waiting_to_" + @active_tab)
          workflow.update(state: 'engaged')
        else
          @appointment.update(current_state: "waiting", engage_time: nil)
          @active_tab = "waiting"
          @all_states = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
          if @all_states.count > 0
            @last_state = @all_states[-1]
            @last_state.delete
          end
          workflow.update(state: 'waiting')
        end

        pst = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", sub_event_name: "ENGAGED", query: { _id: @appointment.id.to_s })
        if params[:patient_engaged].to_s == "true"
          Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "ENGAGED", appointment_id: @appointment.id, user_id: @current_user.id, user_name: @current_user.fullname })
        else
          pst.delete_all if pst.count > 0
        end
      end

      def patient_completed
        @facility = Facility.find_by(id: params[:current_facility_id].to_s)
        @appointment = Appointment.find_by(id: params[:appointment_id].to_s)
        @current_date = params[:current_date]
        @current_user = User.find(params[:current_user_id])
        @appointment_list_view = AppointmentListView.find_by(appointment_id: params[:appointment_id])
        @workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
        if params[:patient_completed].to_s == "true"
          @appointment.update(current_state: "seen", end_time: Time.current, seen_time: Time.current)
          @active_tab = "completed"
          SmsJob.perform_later("visit_sms", @appointment.id.to_s, @appointment.class.to_s)
          @workflow.complete
          @workflow.update(user_id: nil, end_time: Time.current)
        else
          @appointment.update(current_state: "engaged", end_time: nil, seen_time: nil)
          @active_tab = "engaged"
          SmsJob.perform_later("cancel_sms", @appointment.id.to_s, @appointment.class.to_s)
          if @appointment.engage_time.present?
            @appointment.update(current_state: "engaged", end_time: nil, seen_time: nil)
            @active_tab = "engaged"
            @all_states = @workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
            if @all_states.count > 0
              @last_state = @all_states[-1]
              @last_state.delete
            end
            @workflow.update(state: 'engaged')
          else
            @appointment.update(current_state: "waiting", end_time: nil, seen_time: nil)
            @active_tab = "waiting"
            @all_states = @workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
            if @all_states.count > 0
              @last_state = @all_states[-1]
              @last_state.delete
            end
            @workflow.update(state: 'waiting')
          end
        end

        pst = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", sub_event_name: "COMPLETED", query: { _id: @appointment.id.to_s })
        if params[:patient_completed].to_s == "true"
          Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "COMPLETED", appointment_id: @appointment.id, user_id: @current_user.id, user_name: @current_user.fullname })
        else
          pst.delete_all if pst.count > 0
        end
      end
      # def get_patient
      #   @source = params[:source]
      #   @appointment_id = params[:appointment_id]
      #   @appointment =  Appointment.find_by(id: params[:appointment_id])
      #   current_user = User.find(params[:current_user_id])
      #   workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
      #   current_state = workflow.state
      #   if current_user.role_ids.include?159561009 || current_user.role_ids.include?(106292003)
      #     current_user_state = "receptionist"
      #   elsif current_user.has_role?"doctor"
      #     current_user_state = "doctor"
      #   elsif current_user.has_role?"optometrist"
      #     current_user_state = "optometrist"
      #   end
      #   unless current_state == current_user_state
      #     workflow.send(current_state+"_to_"+current_user_state)
      #   end
      #   # doctor_arr = Array.new
      #   if current_user.has_role?"doctor"
      #     doctor_arr = workflow.doctor_ids
      #     doctor_arr << current_user.id.to_s
      #   else
      #     doctor_arr = workflow.doctor_ids
      #   end
      #   workflow.update(user_id: current_user.id,doctor_ids: doctor_arr)
      #   transitions =  OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id)
      #   last_transition = transitions[transitions.count-1]
      #   if last_transition
      #     last_transition.update(user_id: current_user.id)
      #   end
      # end

      def create_update_counsellor_workflow(workflow)
        counsellor_flow = CounsellorWorkflow.find_by(appointment_id: workflow.appointment_id.to_s)
        unless counsellor_flow
          counsellor_flow = CounsellorWorkflow.create(:patient_id => workflow.patient_id, appointment_id: workflow.appointment_id.to_s, facility_id: current_facility.id, organisation_id: current_user.organisation.id, user_id: params[:to_user], adviseddate: Date.current, patient_name: workflow.patient_name, counsellingdate: workflow.appointmentdate, start_time: Time.current, appointmentdate: workflow.appointmentdate, patient_mobilenumber: workflow.patient_mobilenumber, patient_age: workflow.patient_age, patient_gender: workflow.patient_gender, appointment_type_label: workflow.appointment_type_label, appointment_type_color: workflow.appointment_type_color, patient_identifier: workflow.patient_identifier, appointmentstatus: workflow.appointmentstatus, patient_mrno: workflow.patient_mrno, patient_type: workflow.patient_type, patient_type_color: workflow.patient_type_color)
        end
        counsellor_flow.update_attributes(user_id: params[:to_user])
      end

      def update_redis_counter(specialty_id)
        facility_id = @appointment.facility_id
        date = Date.current.strftime('%d%m%Y')

        if @from_department  != nil
          if @from_department == true
            redis_key1 = "hash_key:facility:#{facility_id}:date:#{date}:department:#{@from_id}"
          else
            redis_key1 = "hash_key:facility:#{facility_id}:date:#{date}:specialty_id:#{specialty_id}:user:#{@from_id}"
          end
        end

        if @to_department != nil
          if @to_department == true
            redis_key2 = "hash_key:facility:#{facility_id}:date:#{date}:department:#{@to_id}"
          else
            redis_key2 = "hash_key:facility:#{facility_id}:date:#{date}:specialty_id:#{specialty_id}:user:#{@to_id}"
          end
        end

        # key_count1 = $REDIS.hmget(redis_key1, :count)
        key_count1 = Redis::Master.new.hmget(redis_key1, :count)
        # key_count2 = $REDIS.hmget(redis_key2, :count)
        key_count2 = Redis::Master.new.hmget(redis_key2, :count)

        # $REDIS.pipelined do
        if key_count1.present? && !(['0', nil].include?(key_count1[0]))
          # $REDIS.hincrby(redis_key1, "count", -1)
          Redis::Master.new.hincrby(redis_key1, "count", -1)
        end
        if key_count2.present? && !([nil].include?(key_count2[0]))
          # $REDIS.hincrby(redis_key2, "count", 1)
          Redis::Master.new.hincrby(redis_key2, "count", 1)
        end
        # end
      end

      def find_department_update_status
        if ['309988001', '261904005', '309964003'].include? @find_department_id
          if @state.to == 'ophthal_investigation'
            investigation_type = 'ophthal'
          elsif @state.to == 'radiology_investigation'
            investigation_type = 'radiology'
          elsif @state.to == 'laboratory_investigation'
            investigation_type = 'laboratory'
          end

          inv = Investigation::Queue.find_by(appointment_id: @appointment.id.to_s, investigation_type: investigation_type)
        elsif @find_department_id == '50121007'
          inv = PatientOpticalPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
        elsif @find_department_id == '284748001'
          inv = PatientPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
        end
        @department_prescription = inv
      end

      def find_department
        if @department_id == '309988001'
          department_name = "ophthal_investigation"
        elsif @department_id == '309964003'
          department_name = "radiology_investigation"
        elsif @department_id == '261904005'
          department_name = "laboratory_investigation"
        elsif @department_id == '50121007'
          department_name = "optical"
        elsif @department_id == '284748001'
          department_name = "pharmacy"
        end

        @department_name = department_name
      end
    end
  end
end
