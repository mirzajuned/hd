# rubocop:disable all
class OpdClinicalWorkflowController < ApplicationController
  before_action :authorize
  after_action :prepare_sms, only: [:patient_complete]
  before_action :set_organisation, only: [:patient_arrived, :get_patient, :change_state]
  after_action :prepare_mis_job, only: [:checkout, :change_state, :get_patient, :patient_arrived, :undo_state, :mark_as_not_arrived, :patient_complete, :mark_as_away]

  def checkout
    workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
    unless workflow.state == 'complete'
      transitions = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
      appointment_id = workflow.appointment_id.to_s
      @appointment = Appointment.find_by(id: appointment_id)
      transition_type = params[:transition_type] == 'get_patient' ? 'get_patient' : 'check_out'
      to_user = User.find_by(id: params[:to_user])
      if params[:to] == 'station'
        remove_redis_workflow_qm(workflow) # Place it before workflow update.
        station = QueueManagement::Station.find_by(id: params[:to_station])
        userless_station = if current_facility_setting&.user_set_station
                             station.sub_stations.where(:active_user_id.ne => nil).count == 0
                           else
                             station.sub_stations.where(:user_id.ne => nil).count == 0
                           end
        workflow.update!(station_id: station&.id, station_code: station&.display_code, station_name: station&.name,
                         in_station: true, user_id: nil, with_user: nil, with_user_role: nil, department_id: nil,
                         with_department: nil, in_department: false, sub_station_id: nil, sub_station_code: nil,
                         in_sub_station: false, userless_station: userless_station, area_id: station&.area_id,
                         transition_type: transition_type, state_type: 'station')
        workflow.check_out
        update_redis_pst = true
      else
        # Auto Offline Feature - check if the user has just gone Offline or in OT. Show popup and do not transition if user has just gone Offline / OT. Implemented using OpenStruct, check User::StatusManagement.check_user_state_before_transition method.
        os_check_before_transition_obj = User::StatusManagement.check_user_state_before_transition(current_organisation, current_facility.id.to_s, to_user.id.to_s) # check using "to_user.id.to_s"
        if (os_check_before_transition_obj[:user_state_active_state] == 'OT' && os_check_before_transition_obj[:assign_patients_to_ot_user])
          respond_to do |format|
            format.js { render 'user_in_ot_or_offline_stop_change_state' }
          end
          return
        elsif (os_check_before_transition_obj[:user_state_active_state] == 'Offline' && os_check_before_transition_obj[:assign_patients_to_offline_user])
          respond_to do |format|
            format.js { render 'user_in_ot_or_offline_stop_change_state' }
          end
          return
        end

        # QueueManagement
        primary_department_id = to_user.department_ids[0]
        if ['50121007', '284748001', '261904005', '309935007', '309964003'].include? primary_department_id
          params[:department_id] = primary_department_id
          case primary_department_id
          when '50121007'
            params[:department_model] = params[:type] = 'PatientOpticalPrescription'
            to = 'optician'
          when '284748001'
            params[:department_model] = params[:type] = 'PatientPrescription'
            to = 'pharmacist'
          when '261904005'
            params[:department_model] = 'Investigation::Queue'
            params[:type] = 'laboratory'
            to = 'technician'
          when '309935007'
            params[:department_model] = 'Investigation::Queue'
            params[:type] = 'ophthal'
            to = 'ophthalmology_technician'
          when '309964003'
            params[:department_model] = 'Investigation::Queue'
            params[:type] = 'radiology'
            to = 'radiologist'
          end
        end

        department = Department.find_by(id: params[:department_id])
        @queue_management_present = current_facility_setting.queue_management
        sub_station = QueueManagement::SubStation.find_by(id: params[:to_station])
        department = Department.find_by(id: params[:department_id])

        workflow_options = { user_id: to_user.id, with_user: to_user.fullname, with_user_role: to_user.primary_role,
                             department_id: department&.id, with_department: nil, in_department: false, sub_station_id: sub_station&.id,
                             sub_station_code: sub_station&.display_code, in_sub_station: true, userless_station: false,
                             area_id: sub_station&.area_id, station_id: sub_station&.station_id, station_code: nil,
                             in_station: false, user_note: params[:get_patient_note], transition_type: transition_type,
                             state_type: 'user' }
        if params[:department_model].present? && params[:type].present?
          # is_user_deparment = false
          if params[:department_model] == 'Investigation::Queue'
            record = Investigation::Queue.find_by(patient_id: @appointment.patient_id, investigation_type: params[:type])
            record&.update(appointment_id: appointment_id, appointment_date: Date.current, appointment_time: Time.current)
            is_user_deparment = true
            text = "Record not found in #{department&.name}, Kindly advise prescription first."
          else
            record = params[:department_model].constantize.find_by(appointment_id: appointment_id)
            store_id = record&.store_id
            store = Inventory::Store.find_by(id: store_id)
            store_user_ids = store&.user_ids || []
            if store_user_ids.include? to_user.id
              is_user_deparment = true
              text = "Record not found in #{department&.name}, Kindly advise prescription first."
            else
              is_user_deparment = false
              text = "Record not found. #{to_user&.fullname} is not linked to #{store&.name}"
            end
          end
          unless record.present?
            is_user_deparment = false
            text = "Record not found in #{department&.name}, Kindly advise prescription first."
          end
          if record.present? && params[:transition_type] == 'get_patient'
            is_user_deparment = true
          end
          if record.present? && is_user_deparment
            remove_redis_workflow_qm(workflow) # Place it before workflow update.
            update_redis_pst = true
            record.update(my_queue: true, user_id: to_user.id, with_user: to_user.fullname,
                          with_user_role: to_user.primary_role)
            update_department_user_ids(workflow.appointment_id, [to_user.id.to_s])
            workflow.update!(workflow_options)
            workflow.check_out
          else
            respond_to do |format|
              format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Notice', text: '#{text}', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
            end
          end
        elsif params[:department_id] == '450368792' # TPA department
          department = Department.find_by(id: params[:department_id])
          remove_redis_workflow_qm(workflow) # Place it before workflow update.
          update_redis_pst = true
          workflow_options = { user_id: to_user.id, with_user: to_user.fullname, with_user_role: to_user.primary_role,
                               department_id: department&.id, with_department: nil, in_department: false, sub_station_id: sub_station&.id,
                               sub_station_code: sub_station&.display_code, in_sub_station: true, userless_station: false,
                               area_id: sub_station&.area_id, station_id: sub_station&.station_id, station_code: nil,
                               in_station: false, user_note: params[:get_patient_note], transition_type: transition_type,
                               state_type: 'user' }
          workflow.update!(workflow_options)
          workflow.check_out
        else
          remove_redis_workflow_qm(workflow) # Place it before workflow update.
          update_redis_pst = true
          workflow.update!(workflow_options)
          workflow.check_out
        end

        @to_department = false
        @to_id = params[:to_user]
      end
      second_last_state = transitions.all[-2]
      @last_state = transitions.all[-1]
      if second_last_state.present? && second_last_state.department_id.present?
        @find_department_id = second_last_state.department_id
        @state = second_last_state
        find_department_update_status
        if @department_prescription.present? && second_last_state.event != 'check_out'
          @department_prescription.update(my_queue: false)
        end
        if @department_prescription.present? && second_last_state.event == @last_state.event
          @department_prescription.update(my_queue: false)
        end
        if @department_prescription.present? && @last_state.department_id == @find_department_id
          @department_prescription.update(my_queue: true)
        end
      end

      @from_id = second_last_state&.user_id
      @from_station = second_last_state&.station_id if second_last_state&.to != 'away'
      @to_station = @last_state&.station_id

      if params[:referral] == 'true'
        ref_details = if workflow.referral_details
                        workflow.referral_details.clone
                      else
                        {}
                      end
        ref_details[current_user.id.to_s + '_' + ref_details.size.to_s] = [current_user.fullname, params[:referralnote], Time.current, to_user.fullname]
        reverse_hash = Hash[ref_details.to_a.reverse]
        workflow.update(referral: true, referral_details: reverse_hash)
      end

      if params[:to] == 'station' && params[:department_ids].present?
        update_department_status
      end

      if params[:transition_type] == 'get_patient'
        update_department_user_ids(appointment_id, [to_user.id.to_s])
      end

      update_station_redis_counter

      if update_redis_pst == true
        update_redis_counter(workflow.specialty_id)
        Patients::Summary::TimelineWorker.call(
          event_name: 'OPD_APPOINTMENT', sub_event_name: 'CHECKOUT', appointment_id: workflow.appointment_id,
          user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true
        )
      end
    end
  end

  def change_state
    workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
    return if params[:call_patient] == 'true' && workflow.state == 'call'
    @appointment = Appointment.find_by(id: workflow.appointment_id)
    consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
    from = workflow.state
    to = params[:to].to_s

    remove_redis_workflow_qm(workflow) # Place it before workflow update.
    if params[:send_to_department]
      department_id = params[:to_department]
      department = Department.find_by(id: department_id)
      @all_appointments = Appointment.where(patient_id: params[:patient_id], appointmentdate: Date.current, arrived: true).order(created_at: :desc)

      if params[:department_model].present? && params[:type].present?
        # updating latest appointment_id
        if params[:department_model] == 'Investigation::Queue'
          if @all_appointments.count > 0
            @precription = Investigation::Queue.find_by(patient_id: params[:patient_id], investigation_type: params[:type])
            if @precription.present?
              @precription.update(appointment_id: @all_appointments[0].id.to_s, appointment_date: Date.current, appointment_time: Time.current)
            end
          end
          record = Investigation::Queue.find_by(appointment_id: workflow.appointment_id.to_s, investigation_type: params[:type])
        elsif params[:department_model] == 'PatientPrescription'
          record = PatientPrescription.find_by(appointment_id: workflow.appointment_id)
        elsif params[:department_model] == 'PatientOpticalPrescription'
          record = PatientOpticalPrescription.find_by(appointment_id: workflow.appointment_id)
        end

        if record.nil?
          respond_to do |format|
            format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Notice', text: 'Record not found in #{params[:department_name]}, Kindly advise prescription first.', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
          end
        else
          update_redis_pst = true
          doctor_arr = workflow.doctor_ids.uniq
          consultant_arr = workflow.consultant_ids.uniq
          optometrist_arr = workflow.optometrist_ids.uniq
          ar_nct_arr = workflow.ar_nct_ids
          record.update(my_queue: true, user_id: to_user.id, with_user: to_user.fullname,
                                with_user_role: to_user.primary_role)

          workflow.update(department_id: department_id, with_department: department.name, user_id: nil, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr, ar_nct_ids: ar_nct_arr, in_department: true, consultant_ids: consultant_arr)
          if workflow.state == 'check_out'
            workflow.send("check_in_#{to}")
          else
            unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:department_id) == workflow.try(:department_id)) && (workflow.state != 'away')) && (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
              workflow.send(from + '_to_' + to)
            end
          end
        end
      elsif params[:to_department] == '450368792' # sending patient to TPA department
        update_redis_pst = true
        workflow.update(department_id: department_id, with_department: department.name, user_id: nil, in_department: true, with_user: nil, with_user_role: nil)
        if workflow.state == 'check_out'
          workflow.send("check_in_#{to}")
        else
          workflow.send(from + '_to_' + to)
        end
      end
    else
      to_user = params[:to_user].to_s
      to_user_name = User.find_by(id: to_user)
      update_redis_pst = true

      # Auto Offline Feature - check if the user has just gone Offline or in OT. Show popup and do not transition if user has just gone Offline / OT. Implemented using OpenStruct, check User::StatusManagement.check_user_state_before_transition method.
      os_check_before_transition_obj = User::StatusManagement.check_user_state_before_transition(current_organisation, current_facility.id.to_s, to_user_name.id.to_s) # check using "to_user_name.id.to_s"
      if (os_check_before_transition_obj[:user_state_active_state] == 'OT' && os_check_before_transition_obj[:assign_patients_to_ot_user])
        respond_to do |format|
          format.js { render 'user_in_ot_or_offline_stop_change_state' }
        end
        return
      elsif (os_check_before_transition_obj[:user_state_active_state] == 'Offline' && os_check_before_transition_obj[:assign_patients_to_offline_user])
        respond_to do |format|
          format.js { render 'user_in_ot_or_offline_stop_change_state' }
        end
        return
      end

      if to_user_name.role_ids.include? 158965000
        doctor_arr = workflow.doctor_ids
        if (doctor_arr.size == 1) && !workflow.opd_clinical_workflow_state_transitions.pluck(:to).include?('doctor')
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
      optometrist_arr = optometrist_arr.uniq

      if to_user_name.role_ids.include? 28221005
        ar_nct_arr = workflow.ar_nct_ids

        if ar_nct_arr.blank?
          ar_nct_arr = []
        end
        ar_nct_arr << to_user_name.id.to_s
      else
        ar_nct_arr = workflow.ar_nct_ids
      end

      if consultant_id_role_ids.include? 28229004
        consultant_arr = optometrist_arr
      else
        consultant_arr = doctor_arr
      end
      consultant_arr = consultant_arr.uniq

      primary_department_id = to_user_name.department_ids[0]
      if ['50121007', '284748001', '261904005', '309935007', '309964003'].include? primary_department_id
        params[:department_id] = primary_department_id
        case primary_department_id
        when '50121007'
          params[:department_model] = params[:type] = 'PatientOpticalPrescription'
          to = 'optician'
        when '284748001'
          params[:department_model] = params[:type] = 'PatientPrescription'
          to = 'pharmacist'
        when '261904005'
          params[:department_model] = 'Investigation::Queue'
          params[:type] = 'laboratory'
          to = 'technician'
        when '309935007'
          params[:department_model] = 'Investigation::Queue'
          params[:type] = 'ophthal'
          to = 'ophthalmology_technician'
        when '309964003'
          params[:department_model] = 'Investigation::Queue'
          params[:type] = 'radiology'
          to = 'radiologist'
        end
      end

      if params[:department_model].present? && params[:type].present?
        department = Department.find_by(id: params[:department_id])
        # is_user_deparment = false
        @all_appointments = Appointment.where(patient_id: params[:patient_id], appointmentdate: Date.current, arrived: true).order(created_at: :desc)
        if params[:department_model] == 'Investigation::Queue'
          if @all_appointments.count > 0
            @precription = Investigation::Queue.find_by(patient_id: params[:patient_id], investigation_type: params[:type])
            if @precription.present?
              @precription.update(appointment_id: @all_appointments[0].id.to_s, appointment_date: Date.current, appointment_time: Time.current)
            end
          end
          record = Investigation::Queue.find_by(appointment_id: workflow.appointment_id.to_s, investigation_type: params[:type])
          text = "Record not found in #{department&.name}, Kindly advise prescription first."
          is_user_deparment = true
        else
          record = params[:department_model].constantize.find_by(appointment_id: workflow.appointment_id)
          store_id = record&.store_id
          store = Inventory::Store.find_by(id: store_id)
          store_user_ids = store&.user_ids || []
          if store_user_ids.include? to_user_name.id
            is_user_deparment = true
            text = "Record not found in #{department&.name}, Kindly advise prescription first."
          else
            is_user_deparment = false
            text = "Record not found. #{to_user_name&.fullname} is not linked to #{store&.name}"
          end
          # record = eval(params[:department_model]).find_by(appointment_id: workflow.appointment_id)
        end
        unless record.present?
          is_user_deparment = false
          text = "Record not found in #{department&.name}, Kindly advise prescription first."
        end
        if record.present? && is_user_deparment
          record.update(my_queue: true, user_id: to_user_name.id, with_user: to_user_name.fullname,
                        with_user_role: to_user_name.primary_role)
        end
      end
      # QueueManagement
      @queue_management_present = current_facility_setting.queue_management
      sub_station = QueueManagement::SubStation.find_by(id: params[:to_station])
      workflow_options = { user_id: to_user, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role,
                           department_id: department&.id, with_department: nil, in_department: false, sub_station_id: sub_station&.id,
                           sub_station_code: sub_station&.display_code, in_sub_station: true, userless_station: false,
                           area_id: sub_station&.area_id, station_id: sub_station&.station_id, station_code: nil,
                           in_station: false, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr,
                           ar_nct_ids: ar_nct_arr, consultant_ids: consultant_arr }

      if params[:department_model] == 'PatientPrescription' || params[:department_model] == 'PatientOpticalPrescription'
        inventory_records = params[:department_model].constantize.where(appointment_id: workflow.appointment_id)
        if @organisation.workflow_waiting_disable == false && (record.present? && inventory_records.size > 1)
          is_user_deparment = true
        end
      end
      if is_user_deparment == false || record.nil? && params[:department_model].present?
        department_name = Department.find_by(id: params[:department_id])&.name
        update_redis_pst = false
        respond_to do |format|
          format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Notice', text: '#{text}', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
        end
      elsif params[:department_id] == '450368792' # sending patient to TPA department
        department_id = params[:department_id]
        department = Department.find_by(id: department_id)
        update_redis_pst = true
        workflow.update(department_id: department_id, with_department: department.name, user_id: to_user_name.id, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role)
        if workflow.state == 'check_out'
          workflow.send("check_in_#{to}")
        else
          workflow.send(from + '_to_' + to)
        end
      else
        workflow.update!(workflow_options)
        if (workflow.state == 'check_out' || workflow.state == 'waiting') && @queue_management_present
          workflow.call_patient
        elsif ['call', 'check_out', 'waiting'].include?(workflow.state)
          workflow.send("check_in_#{to}")
        else
          unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:user_id) == workflow.try(:user_id)) && workflow.state != 'away') && (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
            workflow.send(from + '_to_' + to)
          end
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
        last_department_id = @find_department_id
        find_department_update_status
        if @department_prescription.present?
          @department_prescription.update(my_queue: true)
        end
      end
      if @second_last_state.present? && @second_last_state.with_user.nil? && @last_state.with_user.present?
        @to_id = @last_state.user_id
      end
      @to_id = @last_state.user_id if @organisation.workflow_waiting_disable
      @to_station = @last_state.station_id
    end

    if @second_last_state.present?
      if @second_last_state.department_id.present?
        @state = @second_last_state
        @find_department_id = @second_last_state.department_id
        second_last_department_id = @find_department_id
        find_department_update_status
        if @organisation.workflow_waiting_disable && @department_prescription.present? && last_department_id != second_last_department_id
          @department_prescription.update(my_queue: false)
        else
          unless @last_state.department_id.present?
            if @department_prescription.present? && @second_last_state.event != 'check_out'
              @department_prescription.update(my_queue: false)
            end
          end
        end
      end
      @from_id = @second_last_state.user_id if @organisation.workflow_waiting_disable
      @from_station = @second_last_state.station_id
    end

    create_update_counsellor_workflow(workflow) if params[:to] == 'counsellor'

    if params[:referral] == 'true'
      ref_details = if workflow.referral_details
                      workflow.referral_details.clone
                    else
                      {}
                    end
      ref_details[current_user.id.to_s + '_' + ref_details.size.to_s] = [current_user.fullname, params[:referralnote], Time.current, to_user_name.fullname]
      reverse_hash = Hash[ref_details.to_a.reverse]
      workflow.update(referral: true, referral_details: reverse_hash)
    end

    update_department_user_ids(workflow.appointment_id, [to_user_name.id.to_s])

    if update_redis_pst == true
      update_redis_counter(workflow.specialty_id)
      update_station_redis_counter
      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'WORKFLOW', appointment_id: workflow.appointment_id, user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true })
    end
  end

  def get_patient
    workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
    @appointment = Appointment.find_by(id: workflow.appointment_id)
    consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
    from = workflow.state
    to =  if params[:to].to_s == 'floormanager'
            'floormanager'
          elsif params[:to].to_s == 'cashier'
            'cashier'
          elsif params[:to].to_s == 'nurse'
            'nurse'
          elsif params[:to].to_s == 'doctor'
            'doctor'
          elsif params[:to].to_s == 'optometrist'
            'optometrist'
          elsif params[:to].to_s == 'ar_nct'
            'ar_nct'
          elsif params[:to].to_s == 'counsellor'
            'counsellor'
          elsif params[:to].to_s == 'waiting'
            'waiting'
          elsif params[:to].to_s == 'investigator'
            'investigator'
          elsif params[:to].to_s == 'optical'
            'optical'
          elsif params[:to].to_s == 'pharmacy'
            'pharmacy'
          elsif params[:to].to_s == 'ophthal_investigation'
            'ophthal_investigation'
          elsif params[:to].to_s == 'laboratory_investigation'
            'laboratory_investigation'
          elsif params[:to].to_s == 'radiology_investigation'
            'radiology_investigation'
          elsif params[:to].to_s == 'incomplete'
            'incomplete'
          elsif params[:to].to_s == 'receptionist'
            'receptionist'
          elsif params[:to].to_s == 'pharmacist'
            'pharmacist'
          elsif params[:to].to_s == 'optician'
            'optician'
          elsif params[:to].to_s == 'technician'
            'technician'
          elsif params[:to].to_s == 'radiologist'
            'radiologist'
          elsif params[:to].to_s == 'ophthalmology_technician'
            'ophthalmology_technician'
          end

    remove_redis_workflow_qm(workflow) # Place it before workflow update.

    if params[:to_user].present?
      to_user = params[:to_user].to_s
      to_user_name = User.find_by(id: to_user)

      if to_user_name.role_ids.include? 158965000
        doctor_arr = workflow.doctor_ids
        if (doctor_arr.size == 1) && !workflow.opd_clinical_workflow_state_transitions.pluck(:to).include?('doctor')
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
      optometrist_arr = optometrist_arr.uniq

      if to_user_name.role_ids.include? 28221005
        ar_nct_arr = workflow.ar_nct_ids

        if ar_nct_arr.blank?
          ar_nct_arr = []
        end
        ar_nct_arr << to_user_name.id.to_s
      else
        ar_nct_arr = workflow.ar_nct_ids
      end

      if consultant_id_role_ids.include? 28229004
        consultant_arr = optometrist_arr
      else
        consultant_arr = doctor_arr
      end
      consultant_arr = consultant_arr.uniq
      if params[:department_model].present? && params[:type].present?
        department = Department.find_by(id: params[:department_id])
        @all_appointments = Appointment.where(patient_id: params[:patient_id], appointmentdate: Date.current, arrived: true).order(created_at: :desc)
        if params[:department_model] == 'Investigation::Queue'
          if @all_appointments.count > 0
            @precription = Investigation::Queue.find_by(patient_id: params[:patient_id], investigation_type: params[:type])
            if @precription.present?
              @precription.update(appointment_id: @all_appointments[0].id.to_s, appointment_date: Date.current, appointment_time: Time.current)
            end
          end
          record = Investigation::Queue.find_by(appointment_id: workflow.appointment_id.to_s, investigation_type: params[:type])
        else
          record = eval(params[:department_model]).find_by(appointment_id: workflow.appointment_id)
        end
        record.update(my_queue: true, user_id: to_user_name.id, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role) if record.present?
          update_department_user_ids(workflow.appointment_id, [to_user_name.id.to_s])
      end

      # QueueManagement
      @queue_management_present = current_facility_setting.queue_management
      sub_station = QueueManagement::SubStation.find_by(id: params[:to_station])
      department = Department.find_by(id: params[:department_id])

      workflow.update(user_id: to_user, with_user: to_user_name.fullname, with_user_role: to_user_name.primary_role,
                      department_id: department&.id, with_department: nil, in_department: false, sub_station_id: sub_station&.id,
                      sub_station_code: sub_station&.display_code, in_sub_station: true, userless_station: false,
                      area_id: sub_station&.area_id, station_id: sub_station&.station_id, station_code: nil,
                      in_station: false, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr,
                      ar_nct_ids: ar_nct_arr, consultant_ids: consultant_arr)
      if workflow.state == 'check_out' && @queue_management_present && to_user != current_user.id.to_s
        workflow.call_patient
      elsif ['call', 'check_out'].include?(workflow.state)
        workflow.send("check_in_#{to}")
      else
        unless ((workflow.opd_clinical_workflow_state_transitions[-1].try(:user_id) ==  workflow.try(:user_id)) and workflow.state != 'away') and (workflow.opd_clinical_workflow_state_transitions[-1].to == workflow.state)
          if @organisation.workflow_waiting_disable
            workflow.send("#{from}_to_#{to}")
          else
            workflow.check_out
          end
        end
      end

      create_update_counsellor_workflow(workflow) if current_user.role_ids.include? 499992366

    elsif params[:to_department].present?
      @department_id = params[:to_department]
      @department = Department.find_by(id: @department_id)
      to = find_department
      doctor_arr = workflow.doctor_ids.uniq
      optometrist_arr = workflow.optometrist_ids.uniq
      ar_nct_arr = workflow.ar_nct_ids
      consultant_array = workflow.consultant_ids.uniq

      workflow.update(department_id: @department_id, with_department: @department.name, user_id: nil, doctor_ids: doctor_arr, optometrist_ids: optometrist_arr, ar_nct_ids: ar_nct_arr, in_department: true, consultant_ids: consultant_array)
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

    if @last_state.present?
      if @last_state.department_id.present?
        last_department_id = @last_state.department_id
        @state = @last_state
        @find_department_id = @last_state.department_id
        find_department_update_status
        @department_prescription.update(my_queue: true) if @department_prescription.present?
        @to_department = true
      else
        @to_department = false
      end
      @to_id = @last_state.user_id
    end

    if @second_last_state.present?
      if @second_last_state.department_id.present?
        second_last_department_id = @second_last_state.department_id
        @state = @second_last_state
        @find_department_id = @second_last_state.department_id
        find_department_update_status
        if last_department_id != second_last_department_id
          @department_prescription.update(my_queue: false) if @department_prescription.present?
        end
        @from_department = true
        update_department_user_ids(workflow.appointment_id, [to_user_name.id.to_s])
      else
        @from_department = false
      end
      @from_id = @second_last_state.user_id
    end

    if @second_last_state.present? && @second_last_state.to == 'away'
      away_time_hash = {}
      away_time_seconds = 0
      away_transitions = transitions.where(to: 'away', :transition_end.ne => nil)
      away_transitions.each do |transition|
        away_time_general = TimeDifference.between(transition.transition_end, transition.transition_start).in_general
        away_time_hash = away_time_hash.merge(away_time_general) { |_unit, value1, value2| value1 + value2 }
        away_time_seconds += TimeDifference.between(transition.transition_end, transition.transition_start).in_seconds
      end
      if away_time_hash[:minutes].to_i > 60
        away_time_hash[:hours] += 1
        away_time_hash[:minutes] -= 60
      end
      workflow.away_time_general = away_time_hash.delete_if { |unit, value| (value == 0 || ['hours', 'minutes'].exclude?(unit.to_s)) }
      workflow.away_time_seconds = away_time_seconds
      workflow.save!
    end

    update_redis_counter(workflow.specialty_id)

    Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'WORKFLOW', appointment_id: workflow.appointment_id, user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true })
  end

  def patient_arrived
    @source = params[:source]
    @current_user = current_user
    @appointment_id = params[:appointment_id]
    @appointment = Appointment.find_by(id: @appointment_id)
    workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment_id)
    if workflow.state == 'not_arrived'
      @appointment = Appointment.find_by(id: @appointment_id)
      consultant_id_role_ids = User.find_by(id: @appointment.consultant_id.to_s).role_ids
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
      optometrist_arr = optometrist_arr.uniq

      if @current_user.role_ids.include? 28221005
        ar_nct_arr = workflow.ar_nct_ids
        ar_nct_arr << @current_user.id.to_s
      else
        ar_nct_arr = workflow.ar_nct_ids
      end

      if consultant_id_role_ids.include? 28229004
        consultant_arr = optometrist_arr
      else
        consultant_arr = doctor_arr
      end
      consultant_arr = consultant_arr.uniq

      create_update_counsellor_workflow(workflow) if @current_user.role_ids.include? 499992366

      # QueueManagement
      @queue_management_present = current_facility_setting.queue_management
      sub_station = QueueManagement::SubStation.find_by(id: params[:to_station])
      station = sub_station&.station
      userless_station = if station
                           if current_facility_setting&.user_set_station
                             station.sub_stations.where(:active_user_id.ne => nil).count == 0
                           else
                             station.sub_stations.where(:user_id.ne => nil).count == 0
                           end
                         else
                           false
                         end
      if params[:assigned_as] == 'my_station'
        workflow.update!(station_id: station&.id, station_code: station&.display_code, station_name: station&.name,
                         in_station: true, user_id: nil, with_user: nil, with_user_role: nil, department_id: nil,
                         with_department: nil, in_department: false, sub_station_id: nil, sub_station_code: nil,
                         in_sub_station: false, userless_station: userless_station, area_id: station&.area_id,
                         state_type: 'station')
      else
        workflow.update!(start_time: Time.current, user_id: @current_user.id.to_s, with_user: @current_user.fullname,
                         with_user_role: @current_user.primary_role, department_id: nil, with_department: nil,
                         in_department: false, sub_station_id: sub_station&.id, sub_station_code: sub_station&.display_code,
                         in_sub_station: true, userless_station: false, area_id: sub_station&.area_id, state_type: 'user',
                         station_id: sub_station&.station_id, station_code: nil, station_name: nil, in_station: false,
                         doctor_ids: doctor_arr, optometrist_ids: optometrist_arr, ar_nct_ids: ar_nct_arr,
                         consultant_ids: consultant_arr)
      end
      if @organisation.workflow_waiting_disable
        workflow.send('arrived_to_' + current_user_primary_role)
      else
        workflow.check_out
      end

      @patient = Patient.find_by(id: @appointment.patient_id)
      @patient.inc(opd_visit_count: 1)
      if (@patient.try(:reg_status) == false)
        @patient.update(reg_status: true, reg_date: Date.current, reg_time: Time.current, reg_facility_id: @appointment.facility_id.to_s)
        create_patient_identifier(@patient, @current_user, current_facility)
        create_patient_search(@patient)
      end
      @opd_visit_count = @patient.try(:opd_visit_count).to_i
      @appointment.update_attributes(visit_no: @opd_visit_count, arrived: true, start_time: Time.current)

      Analytics::Appointment::UpdateService.patient_arrived(@appointment.id.to_s, @current_user.id.to_s, @appointment.facility_id.to_s)
      Analytics::Appointment::CreateService.create_appointment_type_record(@appointment)
      Analytics::Appointment::CreateService.create_appointment_category_type_record(@appointment)
      Analytics::Appointment::CreateService.create_walkin_appointment_type_record(@appointment)
      # if workflow.try(:not_arrived?)
      #   workflow.send("waiting_to_" + current_user_primary_role)
      # end
      CommunicationNotificationJob.perform_now('patient_arrived', @appointment.id.to_s, @appointment.class.to_s)

      transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id).order(created_at: :asc)
      @last_state = transitions.all[-1]
      @to_station = @last_state&.station_id

      @from_department = nil
      if @last_state.present?
        if @last_state.in_department.present?
          @to_department = true
        else
          @to_department = false
        end
        @to_id = @last_state.user_id
      end

      update_station_redis_counter
      update_redis_counter(workflow.specialty_id)

      @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      if @organisations_setting.try(:mandatory_invoice) && (@appointment.try(:appointmenttype) == 'walkin')
        @url = '/invoice/opd/new'
      end
      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'ARRIVED', appointment_id: @appointment.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: true })

      Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "WORKFLOW", appointment_id: @appointment.id, user_id: workflow.user_id, user_name: workflow.with_user, department_id: workflow.department_id, workflow: true })
    end
  end

  def undo_state
    # before changing any things please understand all logic.
    @source = params[:source]
    @appointment_id = params[:appointment_id]
    @appointment =  Appointment.find_by(id: params[:appointment_id])
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
    @all_states = @workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
    doctor_arr = []
    if @all_states.count > 0
      # making last record as from_state for redis counters update
      @last_state = @all_states[-1]
      if @last_state.department_id.present?
        @find_department_id = @last_state.department_id
        @state = @last_state
        find_department_update_status
        @department_prescription.update(my_queue: false) if @department_prescription.present?
        # @from_id = @last_state.department_id
        @from_department = true
      else
        @from_department = false
      end
      @from_id = @last_state.user_id
      @from_station = @last_state&.station_id
      if @all_states[-2].present? && @all_states[-2].department_id.nil? && @department_prescription.present? && @department_prescription.my_queue == false && @all_states[-2].state_type == 'station'
        @department_prescription.update(my_queue: true)
      end
      # making second last record as to_state for redis counters update and main opd_clinical_workflow
      @second_last_state = @all_states[-2]
      if @second_last_state.present?
        area_id = @second_last_state.area_id
        userless_station = @second_last_state.userless_station

        station_id = @second_last_state&.station_id
        @to_station = station_id
        station_code = @second_last_state.station_code
        in_station = @second_last_state&.station_id.present?
        sub_station_id = @second_last_state.sub_station_id
        sub_station_code = @second_last_state.sub_station_code
        in_sub_station = @second_last_state.sub_station_id.present?
        if @second_last_state.department_id.present?
          # since now we are doing by user not department. I am saving as nil
          in_department = nil
          @state = @second_last_state
          @find_department_id = @second_last_state.department_id
          # @department_prescription.update(my_queue: true) if @department_prescription.present?
          user = User.find_by(id: @second_last_state.user_id)
          Investigation::Queue.where(patient_id: @appointment.patient_id).update_all(user_ids: [])
          PatientOpticalPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)&.update(user_ids: [])
          PatientPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)&.update(user_ids: [])
          find_department_update_status
          @department_prescription.update(my_queue: true, user_id: user.id, with_user: user.fullname,
                                          with_user_role: user.primary_role, user_ids: [current_user.id.to_s]) if @department_prescription.present?
          # @to_id = @second_last_state.user_id
          @to_department = true
        elsif @second_last_state&.station_id.nil?
          in_sub_station = true
          sub_station_id = @second_last_state.sub_station_id
          sub_station_code = @second_last_state.sub_station_code

          in_department = false
          # @to_id = @second_last_state.user_id
          @to_department = false
        elsif in_station.present? && @second_last_state.department_id.nil?
          investigations = Investigation::Queue.where(patient_id: @appointment.patient_id)
          previous_user_ids = investigations.pluck(:previous_user_ids)&.uniq&.flatten
          investigations.update_all(my_queue: true, user_ids: previous_user_ids) if investigations.present?
          optical_pres = PatientOpticalPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
          optical_pres&.update(my_queue: true, user_ids: optical_pres.previous_user_ids)
          pharmacy_pres = PatientPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
          pharmacy_pres&.update(my_queue: true, user_ids: pharmacy_pres.previous_user_ids )
        elsif @workflow.in_station && @second_last_state.department_id.nil?
          Investigation::Queue.where(patient_id: @appointment.patient_id)&.update_all(my_queue: false)
          PatientOpticalPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)&.update(my_queue: false)
          PatientPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)&.update(my_queue: false)
        end
        @to_id = @second_last_state.user_id
      end

      @last_user = User.find_by(id: @all_states[-1].user_id)
      if @last_user.present? && !@last_user.nil?
        if @last_user.role_ids.include? 158965000
          doctor_arr = @workflow.doctor_ids
          doctor_arr.pop if doctor_arr.empty?
        end
      end

      remove_redis_workflow_qm(@workflow) # Place it before workflow update

      if @second_last_state.present?
        @workflow.update(user_id: @second_last_state.user_id, department_id: @second_last_state.department_id,
                         in_department: in_department, in_station: in_station, station_id: station_id,
                         station_code: station_code, in_sub_station: in_sub_station, sub_station_id: sub_station_id,
                         sub_station_code: sub_station_code, userless_station: userless_station, area_id: area_id,
                         with_user: @second_last_state.with_user, with_user_role: current_user.primary_role,
                         state: @second_last_state.to, end_time: nil)
      end
      @last_state.delete
      @second_last_state&.update(transition_end: nil)

      # Update Redis Counter
      update_redis_counter(@workflow.specialty_id)
      update_station_redis_counter

      hide_counsellor_workflow
      SmsJob.perform_later('cancel_sms', @workflow.id.to_s, 'OpdClinicalWorkflow', request.host_with_port)
      respond_to do |format|
        format.js {}
      end

      pstc = PatientSummaryTimeline.where(event_name: 'OPD APPOINTMENT', sub_event_name: 'COMPLETED', query: { _id: @appointment.id.to_s })
      if pstc.count > 0
        pstc.delete_all
        new_pstc = PatientSummaryTimeline.where(event_name: 'OPD APPOINTMENT', query: { _id: @appointment.id.to_s }).order(created_at: :desc)[0]
        new_pstc&.update(is_active: true)
      else
        pstw = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", :sub_event_name.in => ["WORKFLOW", "CHECKOUT"], query: { _id: @appointment.id.to_s }).order(created_at: :desc)[0]
        pstw.delete if pstw
        new_pstw = PatientSummaryTimeline.where(event_name: "OPD APPOINTMENT", sub_event_name: "WORKFLOW", query: { _id: @appointment.id.to_s }).order(created_at: :desc)[0]
        new_pstw.update(is_active: true) if new_pstw
      end
      QueueManagementJobs::WorkflowJob.perform_later(@workflow.id.to_s, @workflow.facility_id.to_s)
    end
  end

  def mark_as_not_arrived
    @source = params[:source]
    @appointment_id = params[:appointment_id]
    @appointment =  Appointment.find_by(id: params[:appointment_id])
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
    @from_station = @workflow&.station_id
    @all_states = @workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
    @token_setting = TokenSetting.find_by(facility_id: @appointment.facility_id)

    if @all_states.count > 0
      if @all_states.all[-1].department_id.present?
        @from_department = true
        @from_id = @all_states.all[-1].user_id.to_s
      else
        @from_department = false
        @from_id = @all_states.all[-1].user_id.to_s
      end
      @to_department = nil

      remove_redis_workflow_qm(@workflow) # Place it before workflow update

      @all_states.destroy_all

      @workflow.update(state: 'not_arrived', user_id: nil, with_user: nil, with_user_role: nil)

      @patient = Patient.find_by(id: @appointment.patient_id)
      @patient.inc(opd_visit_count: -1)
      Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, current_user.id.to_s, @appointment.facility_id.to_s)
      Analytics::Appointment::UpdateService.decrement_walkin_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.decrement_appointment_category_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.decrement_appointment_type_count(@appointment.id.to_s)

      @appointment.update_attributes(visit_no: nil, arrived: false, start_time: Time.current)

      # Update Redis Counter
      update_redis_counter(@workflow.specialty_id)
      update_station_redis_counter

      remove_assigned_token if @token_setting.try(:token_enabled)
      hide_counsellor_workflow
      respond_to do |format|
        format.js {}
      end
      pst = PatientSummaryTimeline.where(event_name: 'OPD APPOINTMENT', query: { _id: @appointment.id.to_s })
      pst1 = pst.where(sub_event_name: 'WORKFLOW').delete_all
      pst2 = pst.where(sub_event_name: 'ARRIVED').delete_all
      pst3 = pst.where(sub_event_name: 'EDITED').update_all(links: { appointment: @workflow.attributes })
      pst4 = pst.where(sub_event_name: 'RESCHEDULED').update_all(links: { appointment: @workflow.attributes })
      pst5 = pst.order(created_at: :desc)[0]&.update(is_active: true)
    end
  end

  def patient_complete
    @source = params[:source]
    @appointment_id = params[:appointment_id]
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])
    @appointment = Appointment.find_by(id: @appointment_id)
    unless @workflow.state == 'complete'
      remove_redis_workflow_qm(@workflow) # Place it before workflow update
      @workflow.complete
      @workflow.update(user_id: nil, department_id: nil, in_department: false, end_time: Time.current)

      @transitions = @workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
      if @transitions.count > 0
        @last_transition = @transitions.all[-1]
        @second_last_transition = @transitions.all[-2]
        if @last_transition.present?
          @last_transition.update(user_id: nil, department_id: nil, station_code: nil, station_name: nil, station_id: nil,
                                  sub_station_code: nil, sub_station_id: nil, userless_station: false, area_id: nil)
        end

        @last_state = @last_transition
        if @second_last_transition.present?
          if @second_last_transition.department_id.present?
            @find_department_id = @second_last_transition.department_id
            @state = @second_last_transition
            find_department_update_status
            @department_prescription.update(my_queue: false) if @department_prescription.present?

            @department_id = @find_department_id
            last_state_name = find_department
            @from_department = true
            # @from_id = @second_last_transition.user_id
          elsif @second_last_transition&.station_id.present?
            # TODO: Do Something Here if Needed
          else
            user = User.find_by(id: @second_last_transition.user_id)
            last_state_name = user&.fullname.to_s
            @from_department = false
          end
          @from_id = @second_last_transition.user_id
          @from_station = @second_last_transition&.station_id
        end

        @to_department = nil
        counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: params[:appointment_id])
        counsellor_workflow&.update_attributes(end_time: Time.current)

        # Update Redis Counter
        update_redis_counter(@workflow.specialty_id)
        update_station_redis_counter

        # Stop Dilatation
        if !@appointment.dilation_start_time.nil? && @appointment.dilation_end_time.nil?
          @appointment.update_attributes(dilation_end_time: Time.current)
        end

        Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "COMPLETED", appointment_id: @workflow.appointment_id, last_state_name: last_state_name, workflow: true })
      end
    end
    CommunicationNotificationJob.perform_now('mark_as_completed', @appointment.id.to_s, @appointment.class.to_s)

    object_config = {}
    object_config["class_name"] = "opd_clinical_workflow"
    object_config["method_name"] = "patient_complete"
    mandatory = {}
    mandatory["organisation_id"] = current_user["organisation_id"].to_s
    optional = {}
    others = {}
    mandatory["appointment_id"] = @appointment_id
    ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, optional, others)
  end

  def mark_as_away
    @source = params[:source]
    @appointment_id = params[:appointment_id]
    @appointment =  Appointment.find_by(id: @appointment_id)
    workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment_id)
    @transitions = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)

    remove_redis_workflow_qm(workflow) # Place it before workflow update.

    if @transitions.count > 0
      from = workflow.state
      workflow.send(from + '_to_away')
      workflow.update(calculate_away_time: true, department_id: nil, in_department: false)

      @last_transition = @transitions.all[-1]
      @second_last_transition = @transitions.all[-2]
      @last_transition.update(user_id: nil, department_id: nil)
      @last_state = @last_transition
      if @second_last_transition.department_id.present?
        @find_department_id = @second_last_transition.department_id
        @state = @second_last_transition
        find_department_update_status
        @department_prescription.update(my_queue: false) if @department_prescription.present?
        @department_id = @find_department_id
        last_state_name = find_department

        @from_department = true
        # @from_id = @second_last_transition.user_id
      elsif @second_last_transition&.station_id.present?
        # TODO: Do Something Here if Needed
      else
        last_state_name = User.find_by(id: @second_last_transition.user_id).try(:fullname)
        @from_department = false
        # @from_id = @second_last_transition.user_id
      end
      @from_id = @second_last_transition.user_id
      @from_station = @second_last_transition&.station_id

      @to_department = nil
      update_redis_counter(workflow.specialty_id)
      update_station_redis_counter
      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'AWAY', appointment_id: @appointment_id, last_state_name: last_state_name, workflow: true })
    end
  end

  def change_state_counsellor
    @appointment_id = params[:appointment_id]
    workflow = CounsellorWorkflow.find_by(appointment_id: params[:appointment_id])
    @patient = Patient.find_by(id: workflow.patient_id)
    if params[:state] == 'arrived'
      workflow.arrived
    elsif params[:state] == 'done'
      workflow.arrived_to_counselling_done
    elsif params[:state] == 'cancelled'
      workflow.cancelled
      workflow.update(counsellingdate: Date.current)
    end
  end

  def counsellor_undo_cancel
    @appointment_id = params[:appointment_id]
    counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @appointment_id)
    counsellor_workflow.undo_cancel
  end

  def counsellor_followup
    current_facility_array
    @appointment_id = params[:appointment_id]
    @appointment_date = params[:appointment_date]
    @patient = Patient.find(params[:searchresultselect][:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def create_followup
    facility = Facility.find_by(id: params[:appointment_facility])
    date = params[:opdfollowupdate]
    time = params[:opdfollowuptime]
    @appointment_id = params[:appointment_id]
    @appointment = Appointment.find_by(id: params[:appointment_id])
    con_workflow = CounsellorWorkflow.find_by(appointment_id: @appointment.id.to_s)
    clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    followupdates = con_workflow.followupdates << Date.parse(date)
    con_workflow.update(followupdates: followupdates, start_time: time, facility_id: facility.id.to_s, counsellingdate: Date.parse(date))
    con_workflow.followup
    respond_to do |format|
      format.js {}
    end
  end

  def create_appointment
    current_facility_array
    @appointment_id = params[:appointment_id]
    doctors_array = User.where(organisation_id: current_user.organisation_id, role_ids: 158965000, :facility_ids.in => [current_facility.id.to_s])
    @appointment_types = AppointmentType.where(user_id: doctors_array[0].id, is_active: true)
    @patient = Patient.find(params[:patientid])
    @counselling_date = CounsellorWorkflow.find_by(appointment_id: @appointment_id).counsellingdate
  end

  def open_counsellor_reports
    todays_appointments = CounsellorWorkflow.where(
      organisation_id: current_user.organisation_id, appointmentdate: params[:current_date],
      facility_id: current_facility.id.to_s
    ).pluck(:appointmentid)
    today_opd_record = OpdRecord.where(:appointmentid.in => todays_appointments)
    @advised_investigations = 0
    @counselled_investigations = 0
    @performed_investigations = 0
    today_opd_record.each do |record|
      next if record.ophthalinvestigationlist.count == 0

      @advised_investigations += 1
      record.ophthalinvestigationlist.each do |inv|
        @counselled_investigations += 1 if inv.counselling
        @performed_investigations += 1 if inv.investigationstage == 'P'
      end
    end
  end

  def counsellor_report_data
    @find_for = params[:find_for]
    dates = Date.parse(params[:start_date])..Date.parse(params[:end_date])

    @todays_appointments = CounsellorWorkflow.where(
      organisation_id: current_user.organisation_id, appointmentdate: dates,
      facility_id: current_facility.id.to_s
    )
    today_appointment_ids = @todays_appointments.pluck(:appointment_id)

    @case_sheets = CaseSheet.where(:appointment_ids.in => today_appointment_ids.map(&:to_s))

    @patients = Patient.where(:id.in => @case_sheets.pluck(:patient_id))
    @patients_data = @patients.map do |patient|
      { id: patient.id, fullname: patient.fullname, patient_identifier: patient.patient_identifier_id,
        patient_mrn: patient.patient_mrn }
    end

    if @find_for == 'investigation'
      @ophthal_investigations = @case_sheets.pluck(:ophthal_investigations).reject(&:nil?).flatten
      @advised_count = @ophthal_investigations.count { |k| k[:is_advised] if k[:is_advised] == true }
      @counselled_count = @ophthal_investigations.count { |k| k[:is_counselled] if k[:is_counselled] == true }
      @agreed_count = @ophthal_investigations.count { |k| k[:has_agreed] if k[:has_agreed] == true }
      @performed_count = @ophthal_investigations.count { |k| k[:is_performed] if k[:is_performed] == true }
      @declined_count = @ophthal_investigations.count { |k| k[:has_declined] if k[:has_declined] == true }
    elsif @find_for == 'procedure'
      @procedures = @case_sheets.pluck(:procedures).reject(&:nil?).flatten
      @advised_count = @procedures.count { |k| k[:is_advised] if k[:is_advised] == true }
      @counselled_count = @procedures.count { |k| k[:is_counselled] if k[:is_counselled] == true }
      @agreed_count = @procedures.count { |k| k[:has_agreed] if k[:has_agreed] == true }
      @performed_count = @procedures.count { |k| k[:is_performed] if k[:is_performed] == true }
      @declined_count = @procedures.count { |k| k[:has_declined] if k[:has_declined] == true }
    end
  end

  def mark_as_arrived
    @appointment_id = params[:appointment_id]
    @appointment = Appointment.find_by(id: @appointment_id)
    @current_user = current_user
    @appointment_list_view = AppointmentListView.find_by(appointment_id: params[:appointment_id])
    workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment_id)
    facility_id = @appointment.facility_id
    sub_station_options = if current_facility_setting&.user_set_station
                            { active_user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                          else
                            { user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                          end
    user_station = QueueManagement::SubStation.find_by(sub_station_options)
    if params[:patient_arrived].to_s == 'true'

      @patient = Patient.find_by(id: @appointment.patient_id)
      @patient.inc(opd_visit_count: 1)
      if (@patient.try(:reg_status) == false)
        @patient.update(reg_status: true, reg_date: Date.current, reg_time: Time.current, reg_facility_id: facility_id.to_s)
        create_patient_identifier(@patient, @current_user, current_facility)
        create_patient_search(@patient)
      end
      @opd_visit_count = @patient.try(:opd_visit_count).to_i

      @appointment.update(current_state: 'waiting', arrived_time: Time.current, visit_no: @opd_visit_count, arrived: true, start_time: Time.current)
      @active_tab = "waiting"
      if workflow.try(:not_arrived?)
        workflow.send("arrived_to_" + @active_tab)
      end
      workflow.update_attributes(start_time: Time.current, user_id: @current_user.id.to_s,
                                 with_user: @current_user.fullname, with_user_role: @current_user.primary_role,
                                 sub_station_id: user_station&.id, sub_station_code: user_station&.display_code,
                                 in_sub_station: true, userless_station: false, area_id: user_station&.area_id)

      Analytics::Appointment::UpdateService.patient_arrived(@appointment.id.to_s, current_user.id.to_s, facility_id.to_s)
      Analytics::Appointment::CreateService.create_appointment_type_record(@appointment)
      Analytics::Appointment::CreateService.create_appointment_category_type_record(@appointment)
      Analytics::Appointment::CreateService.create_walkin_appointment_type_record(@appointment)
      CommunicationNotificationJob.perform_now('patient_arrived', @appointment.id.to_s, @appointment.class.to_s)
    else
      @token_setting = TokenSetting.find_by(facility_id: facility_id)
      remove_assigned_token if @token_setting.try(:token_enabled)

      @patient = Patient.find_by(id: @appointment.patient_id)
      @patient.inc(opd_visit_count: -1)

      Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, current_user.id.to_s, facility_id.to_s)

      @appointment.update(current_state: 'scheduled', arrived_time: nil, token_number: nil, visit_no: nil, arrived: false, start_time: Time.current)
      @active_tab = 'scheduled'

      @all_states = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
      @all_states.destroy_all
      workflow.update(state: 'not_arrived', user_id: nil, with_user: nil, with_user_role: nil)

      Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, current_user.id.to_s, facility_id.to_s)
      Analytics::Appointment::UpdateService.decrement_appointment_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.decrement_appointment_category_type_count(@appointment.id.to_s)
      Analytics::Appointment::UpdateService.decrement_walkin_type_count(@appointment.id.to_s)
    end
    respond_to do |format|
      format.js { render 'appointments/state' }
    end
    if params[:patient_arrived].to_s == 'true'
      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'ARRIVED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname })
    else
      pst = PatientSummaryTimeline.where(event_name: 'OPD APPOINTMENT', query: { _id: @appointment.id.to_s })
      pst1 = pst.where(sub_event_name: 'ARRIVED').delete_all
      @appointment_list_view.update(current_state: 'Scheduled') # Temp Hack
      pst3 = pst.where(sub_event_name: 'EDITED').update_all(links: { appointment: @appointment_list_view.attributes })
      pst4 = pst.where(sub_event_name: 'RESCHEDULED').update_all(links: { appointment: @appointment_list_view.attributes })
    end
  end

  def patient_engaged
    @appointment_id = params[:appointment_id]
    @appointment = Appointment.find_by(id: @appointment_id)
    @current_user = current_user
    workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment_id)

    if params[:patient_engaged].to_s == "true"
      @appointment.update(current_state: "engaged", engage_time: Time.current)
      @active_tab = "engaged"
      workflow.send("waiting_to_" + @active_tab)
      workflow.update(state: 'engaged')
    else
      @appointment.update(current_state: 'waiting', engage_time: nil)
      @active_tab = 'waiting'

      @all_states = workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
      if @all_states.count > 0
        @last_state = @all_states[-1]
        @last_state.delete
      end
      workflow.update(state: 'waiting')
    end
    respond_to do |format|
      format.js { render 'appointments/state' }
    end
    pst = PatientSummaryTimeline.where(event_name: 'OPD APPOINTMENT', sub_event_name: 'ENGAGED', query: { _id: @appointment.id.to_s })
    if params[:patient_engaged].to_s == 'true'
      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'ENGAGED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname })
    else
      pst.delete_all if pst.count > 0
    end
  end

  def patient_completed
    @appointment_id = params[:appointment_id]
    @appointment = Appointment.find_by(id: @appointment_id)
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointment_id])

    if params[:patient_completed].to_s == "true"
      @appointment.update(current_state: "seen", end_time: Time.current, seen_time: Time.current)
      @active_tab = "completed"
      SmsJob.perform_later("visit_sms", @appointment.id.to_s, @appointment.class.to_s)
      CommunicationNotificationJob.perform_now('mark_as_completed', @appointment.id.to_s, @appointment.class.to_s)
      @workflow.complete
      @workflow.update(user_id: nil, end_time: Time.current)
    else
      @active_tab = 'engaged'
      SmsJob.perform_later('cancel_sms', @appointment.id.to_s, @appointment.class.to_s)
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
    respond_to do |format|
      format.js { render 'appointments/state' }
    end
    pst = PatientSummaryTimeline.where(event_name: 'OPD APPOINTMENT', sub_event_name: 'COMPLETED', query: { _id: @appointment.id.to_s })
    if params[:patient_completed].to_s == 'true'
      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'COMPLETED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname })
    else
      pst.delete_all if pst.count > 0
    end
  end

  def print_counsellor_summary
    @organisation = current_user.organisation
    @record = CounsellorRecord.find_by(id: params[:record_id])
    @patient = Patient.find_by(id: @record.patient_id)
    @appointment = Appointment.find_by(id: @record.appointment_id)
    @print_procedure = params[:print_procedure].delete('[]').split(',')
    @print_investigation = params[:print_investigation].delete('[]').split(',')
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'opd_clinical_workflow/print_counsellor_summary', pdf: 'CounsellorRecord', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_i * 10, right: @print_settings[0]['right_margin'].to_i * 10, top: @print_settings[0]['header_height'].to_i * 10, bottom: @print_settings[0]['footer_height'].to_i * 10 } }
    end
    Patients::Summary::TimelineWorker.call({ event_name: 'COUNSELLOR_RECORD', sub_event_name: 'PRINTED', counsellor_record_id: @record.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
  end

  def prepare_mis_job
    Mis::ClinicalReportsHelper.prepare_mis_job(@appointment.id.to_s) if @appointment.present?
  end

  private

  def set_organisation
    @organisation = Organisation.find_by(id: current_user.organisation_id)
  end

  def create_patient_identifier(patient, current_user, current_facility)
    patient_identifier = PatientIdentifier.find_by(patient_id: patient.id, organisation_id: current_user.organisation_id)
    if patient_identifier.blank?
      patient_identifier = PatientIdentifier.create!(patient_id: patient.id, organisation_id: current_user.organisation_id, bkp_patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
      patient_org_id = SequenceManagers::GenerateSequenceService.call('patient', patient.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id.to_s, region_id: current_facility.try(:region_master_id).to_s})
        patient_identifier.update(patient_org_id: patient_org_id)
    end
  end

  def create_patient_search(patient)
    patient_search = PatientSearch.find_by(patient_id: patient.id, organisation_id: current_user.organisation_id)
    if patient_search.blank?
      patient_name = "#{patient.firstname} #{patient.middlename} #{patient.lastname}".strip
      patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
      mobile_number = patient.mobilenumber
      mr_no = patient.patient_mrn
      mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
      reg_hosp_ids = patient.reg_hosp_ids
      patient_identifier_id = patient.patient_identifier_id
      patient_identifier_id_search = patient_identifier_id.to_s.split('').map { |x| x[/\d+/] }.join('')

      search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name}"
      search += "#{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search}"
      search += "#{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search}"
      search += "#{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}"

      PatientSearch.create(search: search.downcase, patient_id: patient.id, patient_name: patient_name,
                           mobile_number: mobile_number, mr_no: patient.patient_mrn,
                           patient_identifier_id: patient_identifier_id, reg_hosp_ids: reg_hosp_ids,
                           patient_identifier_id_search: patient_identifier_id_search,
                           mr_no_search: mr_no_search.downcase, patient_name_search: patient_name_search)
    end
  end

  def prepare_sms
    SmsJob.perform_later("visit_sms", @workflow.id.to_s, @workflow.class.to_s)
  end

  def summary_parms
    params.require(:counsellor_record).permit!
  end

  def current_facility_array
    @facilities = Common.new.fetch_facilities(user: current_user)
    @current_facility_array = []
    @facilities_array = @facilities.map { |facility| [facility.name, facility.id] }

    if current_user.facilities.count > 1
      get_schedule_time_for_current_user
      @facilities_array.each do |facility|
        next unless facility[1].to_s == @current_facility_id.to_s

        @current_facility_array = []
        @current_facility_array.push(facility)
        break
      end
    end

    unless @current_facility_array.present?
      @current_facility_array = []
      @current_facility_array.push(@facilities_array[0])
    end
  end

  def create_update_counsellor_workflow(workflow)
    counsellor_flow = CounsellorWorkflow.find_by(appointment_id: workflow.appointment_id.to_s)
    counsellor_flow ||= CounsellorWorkflow.create(patient_id: workflow.patient_id, appointment_id: workflow.appointment_id.to_s, facility_id: current_facility.id, organisation_id: current_user.organisation.id, user_id: params[:to_user], adviseddate: Date.current, patient_name: workflow.patient_name, counsellingdate: workflow.appointmentdate, start_time: Time.current, appointmentdate: workflow.appointmentdate, patient_mobilenumber: workflow.patient_mobilenumber, patient_age: workflow.patient_age, patient_gender: workflow.patient_gender, appointment_type_label: workflow.appointment_type_label, appointment_type_color: workflow.appointment_type_color, patient_identifier: workflow.patient_identifier, appointmentstatus: workflow.appointmentstatus, patient_mrno: workflow.patient_mrno, patient_type: workflow.patient_type, patient_type_color: workflow.patient_type_color, token_number: workflow.try(:token_number), appointment_type_comment: workflow.try(:appointment_type_comment))
    counsellor_flow.update_attributes(user_id: params[:to_user], appointmentdate: workflow.appointmentdate, state: 'advised') if workflow.state == 'counsellor'
  end

  def remove_assigned_token
    key = "used_tokens:#{@appointment.facility_id}:#{@appointment.appointmentdate.strftime('%d%m%Y')}"
    # @used_tokens = $REDIS.get("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}") || "{}"
    @used_tokens = Redis::Master.new.get(key) || '{}'
    @new_used_tokens = JSON.parse(@used_tokens)
    @new_used_tokens.delete(@appointment.token_number)

    # $REDIS.set("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}", @new_used_tokens.to_json)
    Redis::Master.new.set(key, @new_used_tokens.to_json)
    Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

    if @appointment.appointmentdate == Date.current
      @token_setting.update(used_tokens: @new_used_tokens)
    end # If Old Appointment is Marked Not Arrived
    @appointment.update(token_number: nil)
  end

  def counsellor_convereted
    if @record.try(:procedure).present?
      @counsellor_workflow.converted
      converted_state_array = @counsellor_workflow.converted_state
      converted_state_array << 'Surgery'
      @counsellor_workflow.update(converted_state: converted_state_array)
      @record.procedure.each_value do |proc|
        agreed_procedure = @last_opdrecord.procedure.find_by(id: proc['id'])
        if agreed_procedure.present?
          agreed_procedure.update_attributes(counselling: true)
          @print_procedure << agreed_procedure.procedurename + '(' + @last_opdrecord.get_label_for_procedure_side(agreed_procedure.procedureside) + ')'
        end
      end
    else
      @record.update(procedure: {})
    end
    if @record.try(:investigation).present?
      @counsellor_workflow.converted
      converted_state_array = @counsellor_workflow.converted_state
      converted_state_array << 'Investigation'
      @counsellor_workflow.update(converted_state: converted_state_array)
      @record.investigation.each_value do |inv|
        agreed_inv = @last_opdrecord.ophthalinvestigationlist.find_by(id: inv['id'])
        if agreed_inv.present?
          agreed_inv.update_attributes(counselling: true)
          @print_investigation << agreed_inv.investigationname + '(' + @last_opdrecord.get_label_for_ophthalinvestigations_side(agreed_inv.investigationside) + ')'
          @patient_ophthal_investigation = PatientOphthalAssessment.find_by(record_id: @last_opdrecord.id)
        end
        next unless @patient_ophthal_investigation

        ophthal_investigations = @patient_ophthal_investigation.ophthal_investigations
        @patient_ophthal_investigation.ophthal_investigations.each_with_index do |j, index|
          if agreed_inv.investigationfullcode == j['investigationfullcode']
            ophthal_investigations[index].update(counselling: true)
          end
        end

        update_ophthal_investigations = ophthal_investigations
        @patient_ophthal_investigation.update_attributes(ophthal_investigations: update_ophthal_investigations)
      end
    else
      @record.update(investigation: {})
    end

    if !@record.try(:investigation).present? && !@record.try(:procedure).present?
      @counsellor_workflow.undo_converted if @counsellor_workflow.state == 'converted'
    end
  end

  def hide_counsellor_workflow
    @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @workflow.appointment_id)
    if @counsellor_workflow.present?
      unless @workflow.opd_clinical_workflow_state_transitions.pluck(:to).include? 'counsellor'
        @counsellor_workflow.deleted
      end
    end
  end

  def update_station_redis_counter
    from_station = QueueManagement::Station.find_by(id: @from_station)
    to_station = QueueManagement::Station.find_by(id: @to_station)
    date = Date.current.strftime('%d%m%Y')
    if from_station.present?
      redis_key1 = 'hash_key:facility:' + @current_facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':station:' + from_station&.id
      key_count1 = Redis::Master.new.hmget(redis_key1, :count)
      if key_count1.present? && !['0', nil].include?(key_count1[0])
        Redis::Master.new.hincrby(redis_key1, 'count', -1)
      end
    end
    if to_station.present?
      redis_key2 = 'hash_key:facility:' + @current_facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':station:' + to_station&.id
      key_count2 = Redis::Master.new.hmget(redis_key2, :count)

      if key_count2.present? && ![nil].include?(key_count2[0])
        # $REDIS.hincrby(redis_key2, "count", 1)
        Redis::Master.new.hincrby(redis_key2, 'count', 1)
      end
    end
  end

  def update_redis_counter(specialty_id)
    @current_facility = current_facility
    from_user = User.find_by(id: @from_id)
    to_user = User.find_by(id: @to_id)
    if from_user.present?
      if from_user&.specialty_ids.present?
        redis_key1 = 'hash_key:facility:' + @current_facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + @from_id.to_s
      else
        redis_key1 = 'hash_key:facility:' + @current_facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':user:' + @from_id.to_s
      end
    end

    if to_user.present?
      if to_user&.specialty_ids.present?
        redis_key2 = 'hash_key:facility:' + @current_facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + @to_id.to_s
      else
        redis_key2 = 'hash_key:facility:' + @current_facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':user:' + @to_id.to_s
      end
    end
    key_count1 = Redis::Master.new.hmget(redis_key1, :count)
    key_count2 = Redis::Master.new.hmget(redis_key2, :count)

    # $REDIS.pipelined do
    if key_count1.present? && !['0', nil].include?(key_count1[0])
      # $REDIS.hincrby(redis_key1, "count", -1)
      Redis::Master.new.hincrby(redis_key1, 'count', -1)
    end
    if key_count2.present? && ![nil].include?(key_count2[0])
      # $REDIS.hincrby(redis_key2, "count", 1)
      Redis::Master.new.hincrby(redis_key2, 'count', 1)
    end
  end

  def find_department_update_status
    if ['309935007', '261904005', '309964003'].include? @find_department_id
      if (params[:action] == 'mark_as_away' && @state.to == 'call') || (@last_state.present? && @state.to == @last_state.to) || (params[:action] == 'undo_state' && @state.department_id == @last_state.department_id) || @last_state.department_id.nil? && @state.department_id.present?
        if @find_department_id == '261904005'
          investigation_type = 'laboratory'
        elsif @find_department_id == '309935007'
          investigation_type = 'ophthal'
        elsif @find_department_id == '309964003'
          investigation_type = 'radiology'
        end
      else
        if @state.to == 'ophthalmology_technician'
          investigation_type = 'ophthal'
        elsif @state.to == 'radiologist'
          investigation_type = 'radiology'
        elsif @state.to == 'technician'
          investigation_type = 'laboratory'
        end
      end

      inv = Investigation::Queue.find_by(appointment_id: @appointment.id.to_s, investigation_type: investigation_type)
    elsif @find_department_id == '50121007'
      inv = PatientOpticalPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
    elsif @find_department_id == '284748001'
      inv = PatientPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
    end
    @department_prescription = inv
  end

  def update_department_status
    department_ids = params[:department_ids]
    user_ids = params[:user_ids]
    if department_ids.include? '309935007'
      ophthal_investigation = Investigation::Queue.find_by(patient_id: @appointment.patient_id, investigation_type: 'ophthal')
      previous_user_ids = ophthal_investigation&.user_ids
      ophthal_investigation&.update(my_queue: true, user_ids: user_ids, previous_user_ids: previous_user_ids)
    end
    if department_ids.include? '309964003'
      radiology_investigation = Investigation::Queue.find_by(patient_id: @appointment.patient_id, investigation_type: 'radiology')
      previous_user_ids = radiology_investigation&.user_ids
      radiology_investigation&.update(my_queue: true, user_ids: user_ids, previous_user_ids: previous_user_ids)
    end
    if department_ids.include? '261904005'
      laboratory_investigation = Investigation::Queue.find_by(patient_id: @appointment.patient_id, investigation_type: 'laboratory')
      previous_user_ids = laboratory_investigation&.user_ids
      laboratory_investigation&.update(my_queue: true, user_ids: user_ids, previous_user_ids: previous_user_ids)
    end
    if department_ids.include? '50121007'
      optical_pres = PatientOpticalPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
      optical_pres&.update(my_queue: true, user_ids: user_ids, previous_user_ids: optical_pres.previous_user_ids)
    end
    if department_ids.include? '284748001'
      pharmacy_pres = PatientPrescription.find_by(appointment_id: @appointment.id.to_s, patient_id: @appointment.patient_id)
      pharmacy_pres&.update(my_queue: true, user_ids: user_ids, previous_user_ids: pharmacy_pres.previous_user_ids)
    end
  end

  def find_department
    if @department_id == '309935007'
      department_name = 'ophthalmology_technician'
    elsif @department_id == '309964003'
      department_name = 'radiologist'
    elsif @department_id == '261904005'
      department_name = 'technician'
    elsif @department_id == '50121007'
      department_name = 'optical'
    elsif @department_id == '284748001'
      department_name = 'pharmacy'
    elsif @department_id == '450368792'
      department_name = 'tpa_department'
    end

    @department_name = department_name
  end

  def update_department_user_ids(appointment_id, user_ids)
    investigations = Investigation::Queue.where(appointment_id: appointment_id)
    previous_user_ids = investigations.pluck(:user_ids)&.uniq&.flatten
    investigations.update_all(user_ids: user_ids, previous_user_ids: previous_user_ids)
    optical_pres = PatientOpticalPrescription.find_by(appointment_id: appointment_id)
    optical_pres&.update(user_ids: user_ids, previous_user_ids: optical_pres.user_ids)
    pharmacy_pres = PatientPrescription.find_by(appointment_id: appointment_id)
    pharmacy_pres&.update(user_ids: user_ids, previous_user_ids: pharmacy_pres.user_ids)
  end

  def remove_redis_workflow_qm(workflow)
    date = Date.today.strftime('%d%m%Y')
    facility_id = workflow.facility_id

    # Reference Key for ZADD & HMSET
    patient_key = "qm:facility:#{facility_id}:date:#{date}:patient_id:#{workflow.patient_id}"

    # ZADD Area Key
    zadd_area_key = "qm:facility:#{facility_id}:date:#{date}:area_id:#{workflow.area_id}"
    $REDIS.zrem zadd_area_key, patient_key

    # ZADD Station Key
    zadd_station_key = "qm:facility:#{facility_id}:date:#{date}:station_id:#{workflow.station_id}"
    $REDIS.zrem zadd_station_key, patient_key

    ActionCable.server.broadcast("remove_queue_#{workflow.station_id}_channel", workflow_id: workflow.id.to_s)
    ActionCable.server.broadcast("remove_queue_#{workflow.area_id}_channel", workflow_id: workflow.id.to_s)
  end
end
