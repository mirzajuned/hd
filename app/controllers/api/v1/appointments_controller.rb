# rubocop:disable all
module Api
  module V1
    class AppointmentsController < ApiApplicationController
      before_action :authorize_token
      api :GET, '/api/v1/appointments/get_appointments_for_calendar', 'Get appointments for calendar screen on mobile and tablet'
      formats ['json']
      description <<-EOS
          == Get appointments for calendar screen on mobile and tablet
             URL: /api/v1/appointments/get_appointments_for_calendar
             No parameter has to be passed for now
      EOS
      def get_appointments_for_calendar
        users = current_user.organisation.users.only(:id).where(is_active: true).with_all_roles(:doctor).to_a.map { |o| o['id'].to_s }
        @appointments = Appointment.where(:appointmentdate.gte => Date.current - 10.days, :user_id.in => users, :appointmentstatus.in => [416774000, 58334001])
        respond_to do |format|
          format.json {}
        end
      end

      api :GET, '/api/v1/appointments/get_appointments_for_patient', 'Get appointments for a patient on mobile and tablet'
      formats ['json']
      description <<-EOS
          == Get appointments for a patient on mobile and tablet
             URL: /api/v1/appointments/get_appointments_for_patient.
             This is example json.
             Patient id has to be passed. Ex json: {"patient": {"patientid": 111111111} }
      EOS
      def get_appointments_for_patient
        @appointments = Appointment.where(patient_id: params[:patient][:patientid]).order(appointmentdate: :asc, appointmenttime: :asc)
        respond_to do |format|
          format.json { render 'get_appointments_for_patient', layout: false }
        end
      end

      api :POST, '/api/v1/appointments/create', 'Create appointment for the patient using mobile and tablet'
      formats ['json']
      description <<-EOS
          == Get appointments for a patient on mobile and tablet
             URL: /api/v1/appointments/create
             This is example json.
             Patient id has to be passed. Ex json: {'appointmentdate':'yyyy-mm-dd','start_time':'HH:mm','appointment_type_id':'id','user_id':'doctor for whom appointment is created','patient_id':'id','facility_id':'id','department_id':'dept of doctor for whom appointment is created'}
              response if created => {created:true,id:'id',display_id:'disp id'}
              response if failed=> {created:false}
      EOS
      def create
        current_user = User.find(params[:current_user_id])
        current_facility = Facility.find(params[:current_facility_id])
        if params[:appointment][:patient_id].present?
          @patient = Patients::UpdateService.call(params[:appointment][:patient_id], params, current_user) # Call Patient UpdateService
        else
          @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService
        end

        # Create New Appointment
        if @patient
          params[:appointment][:patient_id] = @patient.id.to_s
          params[:appointment][:display_id] = CommonHelper.get_opd_record_identifier(current_user)

          # if params[:appointment][:opd_referral_id].present?
          #   appointment_referral_params
          # end

          @case_sheet = CaseSheet.find_by(patient_id: @patient.id.to_s, is_active: true)
          params[:appointment][:case_sheet_id] = @case_sheet.id.to_s if @case_sheet.present?

          @appointment = Appointment.new(appointment_params)
          if @appointment.save
            if params[:patient_referral_type].present? && params[:patient_referral_type][:referral_type_id].present?
              create_patient_referral
            end

            CaseSheet::CreateAppointmentService.call(@patient, @appointment, current_user, nil)

            @opd_referral&.update(converted_to_appointment: true, converted_appointment_id: @appointment.id)
            @status_flag = true
            respond_to do |format|
              format.json { render 'create_appointment', layout: false }
            end
            Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'SCHEDULED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
          else
            format.json { render 'Appointment is not saved', layout: false }
          end
        end
      end

      api :GET, '/api/v1/appointments/get_2_weeks_appointments', 'Get appointments for 2 weeks by passing start and end date'
      formats ['json']
      description <<-EOS
          == Get appointments for 2 weeks by passing start and end date on mobile and tablet
             URL: /api/v1/appointments/get_2_weeks_appointments
             This is example json.
             Ex json: {"appointment": {"startdate": "2015-03-18", "enddate": "2015-03-18" } }
      EOS
      def get_2_weeks_appointments
        # @appointments = Appointment.where(:appointmentdate => "2015-03-18".."2015get_2_weeks_appointments-03-26").order(appointmenttime: :asc)
        @appointments = Appointment.where(appointmentdate: params[:appointment][:startdate]..params[:appointment][:enddate], appointmentstatus: [416774000, 58334001]).order(appointmenttime: :asc)
        respond_to do |format|
          format.json { render 'get_2_weeks_appointments', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/get_future_2_weeks_appointments_from_today', 'Get future 2 weeks appointments from today, means today plus(+) 14 days.'
      formats ['json']
      description <<-EOS
          == Get future 2 weeks appointments from today, means today plus(+) 14 days on mobile and tablet
             URL: /api/v1/appointments/get_future_2_weeks_appointments_from_today
             This is example json.
             Ex json: JSON will be updated later. For now, no need to pass anything.
      EOS
      def get_future_2_weeks_appointments_from_today
        @appointments = Appointment.where(appointmentdate: Date.current.strftime('%Y-%m-%d')..(Date.current + 14).strftime('%Y-%m-%d'), appointmentstatus: [416774000, 58334001]).order(appointmenttime: :asc)
        respond_to do |format|
          format.json { render 'get_future_2_weeks_appointments_from_today', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/get_past_2_weeks_appointments_from_today', 'Get past 2 weeks appointments from today, means today minus(-) 14 days.'
      formats ['json']
      description <<-EOS
          == Get past 2 weeks appointments from today, means today minus(-) 14 days on mobile and tablet
             URL: /api/v1/appointments/get_past_2_weeks_appointments_from_today
             This is example json.
             Ex json: JSON will be updated later. For now, no need to pass anything.
      EOS
      def get_past_2_weeks_appointments_from_today
        @appointments = Appointment.where(appointmentdate: (Date.current - 14).strftime('%Y-%m-%d')..Date.current.strftime('%Y-%m-%d'), appointmentstatus: [416774000, 58334001]).order(appointmenttime: :asc)
        respond_to do |format|
          format.json { render 'get_past_2_weeks_appointments_from_today', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/reschedule_appointment', 'Reschedule appointment'
      formats ['json']
      description <<-EOS
          == Reschedule appointment
             URL: /api/v1/appointments/reschedule_appointment
             This is example json.
             Ex json: {'appointment_id':'id','appointmentdate':'yyyy-mm-dd','start_time':'HH:mm'}
             response: {'rescheduled':true or false}
      EOS
      def reschedule_appointment
        @appointment = Appointment.find(params[:appointment_id])
        @appointment.update_attributes(appointmentdate: params[:appointmentdate], start_time: params[:start_time], end_time: Time.zone.parse(params['start_time']) + appointment.appointment_type.duration.to_i.minutes)
        # PatientAppointmentRescheduleSmsJob.perform_later(@appointment.id.to_s)
        # RescheduleEmailJob.perform_later(@appointment.id.to_s) #uncomment when user setting implemented
        respond_to do |format|
          format.json {}
        end
      end

      api :GET, '/api/v1/appointments/cancel_appointment', 'Cancel appointment for the patient'
      formats ['json']
      description <<-EOS
          == Cancel appiontment of patient
             URL: /api/v1/appointments/cancel_appointment
             This is example json.
             Appointment id has to be passed. Ex json: {'appointment_id':'id'}
             response: {'canceled':true or false}
      EOS
      def cancel_appointment
        @appointment = Appointment.find(params[:appointment_id])
        reset_token

        if @appointment.arrived == true # if patient was already arrived then upon cancelling it should deduct opd_visit_count.
          @patient = Patient.find_by(id: @appointment.patient_id)
          @patient.inc(opd_visit_count: -1)

          Analytics::Appointment::UpdateService.patient_not_arrived(@appointment.id.to_s, current_user.id.to_s, @appointment.facility_id.to_s)

          @appointment.update_attributes({ appointmentstatus: 89925002, token_number: nil, visit_no: nil, arrived: false, start_time: Time.current })
        else
          @appointment.update_attributes({ appointmentstatus: 89925002, token_number: nil, start_time: Time.current })
        end

        respond_to do |format|
          @datepicker_date = Date.strptime(@appointment.appointmentdate.to_s, '%Y-%m-%d').strftime('%Y-%m-%d')
          @appointmentlist = Appointment.where(appointmentdate: Date.strptime(@appointment.appointmentdate.to_s, '%Y-%m-%d').strftime('%Y-%m-%d'), appointmentstatus: [416774000, 58334001]).order(appointmenttime: :desc)
          # PatientAppointmentCancellationSmsJob.perform_later(@appointment.id.to_s)
          format.json {}
        end
        Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'CANCELLED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
      end

      api :GET, '/api/v1/appointments/get_appointments_for_nextmonth', 'Get appointments for next 1 months. The api will query all appointments for next 1 month.'
      formats ['json']
      description <<-EOS
          == Get appointments for next 1 months. The api will query all appointments for next 1 month.

             URL: /api/v1/appointments/get_appointments_for_nextmonth
             This is example json.
             Ex json: You need to pass the following {"startdate": "20/07/2015" }
      EOS
      def get_appointments_for_nextmonth
        @startdate = Date.parse(params[:startdate], '%d/%m/%YYYY')
        @enddate = @startdate.end_of_month
        @appointmenttypearray = ['Fresh', 'Follow', 'Vip', 'Elderly', 'Child', 'Men', 'Women']
        # puts params[:user_id]
        respond_to do |format|
          format.json { render 'get_appointments_for_nextmonth', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/types', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {appointment_types:{0:{id:'id',name:'full name'}},{1:{id:'id',name:'full name'}}}
      EOS
      def types
        @appointment_types = AppointmentType.where(user_id: current_user.organisation.users.where(is_active: true).with_all_roles(:doctor).first.id, is_active: true)

        respond_to do |format|
          format.json {}
        end
      end

      api :GET, '/api/v1/appointments/has_arrived', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/has_arrived
             This is example json.
             Result:
             {"status":"patient has arrived","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def has_arrived
        appointment_id = params[:appointment_id]
        @appointment = Appointment.find(appointment_id)
        @appointment.patient_arrived
        arrived_time = Time.current
        @appointment.update({ arrived: true, seen: false, arrived_time: arrived_time })
        patient_visit = PatientVisit.find_by(patient_id: @appointment.patient.id.to_s, encounter_date: Date.current)
        if !patient_visit.nil?
          patient_visit.update_attributes(encounter_date: Date.current)
        else
          PatientVisit.create(doctor: @appointment.consultant_id.to_s, encounter_date: Date.current, encounter_type: 'OPD', patient_id: @appointment.patient.id.to_s, organisation_id: current_user.organisation.id.to_s, current_facility_id: @appointment.facility.id.to_s, user_id: current_user.id.to_s)
        end
        respond_to do |format|
          format.json { render 'has_arrived', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/has_engaged', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {"status":"patient is engaged","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def has_engaged
        appointment_id = params[:appointment_id]
        @appointment = Appointment.find(appointment_id)
        @appointment.patient_engaged
        @appointment.update({ arrived_time: @appointment.start_time - 300 }) if @appointment.arrived_time.nil?
        arrived_time = @appointment.arrived_time
        engage_time = Time.current
        waiting_time_min = ((engage_time - arrived_time) / 60).ceil
        waiting_time_min = 1 if waiting_time_min <= 0
        @appointment.update({ engaged: true, arrived: true, seen: false, engage_time: engage_time, waiting_time_min: waiting_time_min })
        patient_visit = PatientVisit.find_by(patient_id: @appointment.patient.id.to_s, encounter_date: Date.current)
        if !patient_visit.nil?
          patient_visit.update_attributes(encounter_date: Date.current)
        else
          PatientVisit.create(doctor: @appointment.consultant_id.to_s, encounter_date: Date.current, encounter_type: 'OPD', patient_id: @appointment.patient.id.to_s, organisation_id: current_user.organisation.id.to_s, facility_id: @appointment.facility.id.to_s, user_id: current_user.id.to_s)
        end
        respond_to do |format|
          format.json {}
        end
      end

      api :GET, '/api/v1/appointments/has_seen', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {"status":"appointment completed","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def has_seen
        appointment_id = params[:appointment_id]
        @appointment = Appointment.find(appointment_id)
        @appointment.patient_seen
        if @appointment.arrived_time.nil?
          @appointment.update({ arrived_time: @appointment.start_time - 300, waiting_time_min: 10 })
        end
        @appointment.update({ engage_time: @appointment.start_time + 300 }) if @appointment.engage_time.nil?
        arrived_time = @appointment.arrived_time
        engage_time = @appointment.engage_time
        seen_time = Time.current
        engaged_time_min = ((seen_time - engage_time) / 60).ceil
        total_time_min = ((seen_time - arrived_time) / 60).ceil
        waiting_time_min = ((engage_time - arrived_time) / 60).ceil
        waiting_time_min = 1 if waiting_time_min <= 0
        engaged_time_min = waiting_time_min if engaged_time_min <= 0
        total_time_min = waiting_time_min if total_time_min <= 0
        @appointment.update({ engaged: false, seen: true, arrived: true, seen_time: seen_time, engaged_time_min: engaged_time_min, total_time_min: total_time_min, waiting_time_min: waiting_time_min })
        patient_visit = PatientVisit.find_by(patient_id: @appointment.patient.id.to_s, encounter_date: Date.current)
        if !patient_visit.nil?
          patient_visit.update_attributes(encounter_date: Date.current)
        else
          PatientVisit.create(doctor: @appointment.consultant_id.to_s, encounter_date: Date.current, encounter_type: 'OPD', patient_id: @appointment.patient.id.to_s, organisation_id: current_user.organisation.id.to_s, facility_id: @appointment.facility.id.to_s, user_id: current_user.id.to_s)
        end
        @patient_visit_id = PatientVisit.find_by(patient_id: @appointment.patient.id.to_s, encounter_date: Date.current).id
        @appointment.update_attributes(dilation_end_time: Time.current)
        # VisitSmsJob.set(wait: 1.hour).perform_later(@patient_visit_id.to_s)
        respond_to do |format|
          format.json {}
        end
      end

      api :GET, '/api/v1/appointments/schedule', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {"status":"patient is engaged","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def schedule
        @appointment = Appointment.where(user_id: params[:user_id].to_s, facility_id: params[:current_facility_id].to_s, current_state: 'scheduled', arrived: false)
        @patients = []
        @appointment.each do |appointment|
          details = {}
          patient = Patient.find(appointment.patient_id)
          details[:name] = patient.fullname
          details[:arrived_time] = 'not arrived'
          @patients.push(details)
        end
        respond_to do |format|
          format.json { render 'patient_list', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/waiting', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {"status":"patient is engaged","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def waiting
        @appointment = Appointment.where(user_id: params[:user_id], facility_id: params[:current_facility_id], current_state: 'waiting', arrived: true, seen: false)
        @patients = []
        @appointment.each do |appointment|
          details = {}
          patient = Patient.find(appointment.patient_id)
          details[:name] = patient.fullname
          details[:arrived_time] = appointment.arrived_time
          @patients.push(details)
        end
        respond_to do |format|
          format.json { render 'patient_list', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/seen', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {"status":"patient is engaged","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def seen
        @appointment = Appointment.where(user_id: params[:user_id], facility_id: params[:current_facility_id], current_state: 'seen')
        @patients = []
        @appointment.each do |appointment|
          details = {}
          patient = Patient.find(appointment.patient_id)
          details[:name] = patient.fullname
          details[:arrived_time] = appointment.arrived_time
          @patients.push(details)
        end
        respond_to do |format|
          format.json { render 'patient_list', layout: false }
        end
      end

      api :GET, '/api/v1/appointments/engaged', 'Get appointments types for current org'
      formats ['json']
      description <<-EOS
          == Get appointments types for current org

             URL: /api/v1/appointments/types
             This is example json.
             Result: {"status":"patient is engaged","id":"577cc8e231eb0508ff000093","display_id":"SDF-OPD-200016"}
      EOS

      def engaged
        @appointment = Appointment.where(user_id: params[:user_id], facility_id: params[:current_facility_id], current_state: 'seen', engaged: true)
        @patients = []
        @appointment.each do |appointment|
          details = {}
          patient = Patient.find_by(id: appointment.patient_id)
          details[:name] = patient.fullname
          details[:arrived_time] = appointment.arrived_time
          @patients.push(details)
        end
        respond_to do |format|
          format.json { render 'patient_list', layout: false }
        end
      end

      def get_appointment_lists
        @current_user_id = params[:current_user_id]
        @current_user = User.find_by(id: @current_user_id)
        @facility = Facility.find_by(id: params[:current_facility_id].to_s)
        @current_date = if params[:current_date].present?
                          Date.parse(params[:current_date])
                        else
                          Date.current
                        end
        if params[:active_user].present?
          @active_user = params[:active_user]
        else
          if @facility.clinical_workflow || @current_user.role_ids[0] == 158965000
            @active_user = @current_user.id.to_s
          end # doctor
        end

        if @facility.clinical_workflow
          @user = User.find_by(id: @active_user)
          @appointment_list = OpdClinicalWorkflow.where(appointmentdate: params[:current_date], facility_id: params[:current_facility_id].to_s, :state.nin => ['cancelled']).order('start_time DESC')
          @patient_params = get_patient_params(@appointment_list.pluck(:patient_id))

          unless @active_user == "all" || @active_user == nil || @active_user == ""
            if @current_date < Date.current
              @my_queue = @appointment_list.where(state: "incomplete", :user_id => @active_user)
            else
              @my_queue = @appointment_list.where(:state.in => [@user.primary_role, 'check_out'], user_id: @active_user)
            end
          else
            @my_queue = @appointment_list.where(:state.nin => ['complete', 'not_arrived'])
          end
        else

          if @active_user == 'all' || @active_user.nil? || @active_user == ''
            @appointment_list = AppointmentListView.where(appointment_date: @current_date, facility_id: @facility.id.to_s).not.where(current_state: 'Deleted').order('appointment_start_time ASC')
            @patient_params = get_patient_params(@appointment_list.pluck(:patient_id))
          else
            @appointment_list = AppointmentListView.where(appointment_date: @current_date, consulting_doctor_id: @active_user, facility_id: @facility.id.to_s).not.where(current_state: 'Deleted').order('appointment_start_time ASC')
            @patient_params = get_patient_params(@appointment_list.pluck(:patient_id))
          end
        end
      end

      def showday_appointment_details
        @facility = Facility.find_by(id: params[:current_facility_id].to_s)
        @appointment = Appointment.find_by(id: params[:appointment_id].to_s)
        @case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id.to_s)
        @current_date = params[:current_date]
        @current_user = User.find_by(id: params[:current_user_id])
        @specialty_id = @appointment.specialty_id
        organisation = Organisation.find_by(id: @current_user.organisation_id)
        @org_specialties = Specialty.where(:id.in => organisation['specialty_ids']).pluck(:id, :name)
        current_facility = @facility

        if @appointment
          @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)
          @patient = Patient.find_by(id: @appointment.patient_id)
          if @patient.occupation.present?
            occupation_list = Global.send('occupation_list').send('sets')
            occupation_hash = occupation_list.find { |x| x[:snomedcode] == @patient&.occupation }
            @occupation_name = occupation_hash.present? ? occupation_hash[:name] : @patient.occupation
          end
          if @patient.exact_age.present?
            age_year, age_month = @patient.calculate_age(true)
            age_in_months = (age_year.to_i * 12) + age_month.to_i
            if age_year.present? && (49...960).exclude?(age_in_months)
              @special_patient = 'true'
              @color = '#ff8735'
            end
          end
          if @patient.one_eyed == 'Yes'
            @one_eye = 'true'
            @eye_color = '#ff8735'
          end
          @initial_patient_referral_type = PatientReferralType.where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

          @referral = PatientReferralType.where(appointment_id: @appointment.id)
          @patient_referral_type = @referral.where(is_deleted: false)[0]
          @deleted_patient_referral_type = @referral.where(is_deleted: true)[0]

          @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current).order(appointment_date: :desc)
          @patient_note = PatientNote.where(patient_id: @patient.id).order(created_at: :desc)
          @counsellor_note = CounsellorNote.where(patient_id: @patient.id).order(created_at: :desc)
          patient_asset = @patient.patientassets
          @patient_asset = (patient_asset.last.asset_path_url if patient_asset.count > 0) || 'https://hg-user-assets.s3.amazonaws.com/profile-pics/5882e6e6666d670647000087_photo_20170121_101318.png'

          # UserState
          if current_facility.show_user_state
            @user_state = UserState.find_by(user_id: @current_user.id, facility_id: current_facility.id)
            if @user_state.active_state != 'OPD'
              @show_user_state = true
              @user_state_color = @user_state.state_color
              @active_state = @user_state.active_state
            end
          end

          # OPD Records
          if @current_user.role_ids.include?(158965000) || @current_user.role_ids.include?(106292003) || @current_user.role_ids.include?(28229004) # doctor, optometrist
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@appointment.specialty_id)
            @opd_templates = Global.send(@speciality_folder_name.downcase.to_s).send('opdtemplates')
            @show_opd_record = true
            @appointment_opd_records = OpdRecord.where(appointmentid: @appointment.id.to_s)
            @old_records = PatientTimeline.where(patient_id: @patient.id.to_s, encountertype: 'OPD').not.where(appointment_id: @appointment.id.to_s).limit(3).order(encounterdate: :desc)
          end

          # Doctor Reminder Note
          # if @current_user.role_ids.include?(158965000) #doctor
          #   @show_reminder_note = true
          #   @reminder_note = DocReminderNote.find_by(patient_id: @appointment.patient.id.to_s).try(:reminder_text)
          # end

          # Invoice Queries
          if current_facility.show_finances
            @invoices = Invoice::Opd.where(appointment_id: @appointment.id)
            @past_invoices = Invoice::Opd.where(patient_id: @patient.id)
            @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
            @advance = AdvancePayment.where(patient_id: @patient.id, type: 'OPD', advance_state: 'None')
          end

          # Admission Params
          @admission_list_view = AdmissionListView.find_by(patient_id: @patient.try(:id), :current_state.nin => ['Deleted', 'Discharged'])
          @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false)

          # @clinical_workflow_present = (true if current_facility.clinical_workflow) || false
          # if !@clinical_workflow_present
          #   # NonWorkflow TimeLine Calculations
          #   @waiting_time = @appointment_list_view.patient_time[0]
          #   @engaged_time = @appointment_list_view.patient_time[1]
          #
          #   # Doctor
          #   @consulting_doctor = @appointment_list_view.consulting_doctor
          #
          #   # For Counsellor in Non-workflow
          #   @users = User.where(facility_ids: current_facility.id, is_active: true)
          #   @counsellors = @users.where(role_ids: 499992366, is_active: true)
          # else
          #   # Workflow SendTo Users
          #   @clinical_workflows = OpdClinicalWorkflow.where(appointmentdate: Date.current)
          #   @clinical_workflow = OpdClinicalWorkflow.includes(:opd_clinical_workflow_state_transitions).find_by(appointment_id: @appointment.id.to_s)
          #   @clinical_workflow.try(:state)
          #   @clinical_workflow_timeline = @clinical_workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
          #   @clinical_workflow_timeline_count = @clinical_workflow_timeline.count
          #   @users = User.where(facility_ids: current_facility.id, is_active: true)
          #   @doctors = @users.where(role_ids: 158965000, is_active: true).not.where(id: @current_user.id)
          #   @optometrists = @users.where(role_ids: 28229004, is_active: true).not.where(id: @current_user.id)
          #   @receptionists = @users.where(role_ids: 159561009, is_active: true)
          #   @counsellors = @users.where(role_ids: 499992366, is_active: true)
          #   # Doctor
          #   @consulting_doctor = @users.find_by(id: @clinical_workflow.doctor_ids.last).fullname
          # end

          # Counsellor
          if @current_user.role_ids.include?(499992366) # counsellor
            @opd_records = OpdRecord.where(appointmentid: @appointment.id.to_s).order(created_at: :desc)
            @opd_record = @opd_records.find_by(templatetype: 'eye')
            @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @appointment.id.to_s)
            @followupdates = @counsellor_workflow.followupdates
            @all_counsellor_records = CounsellorRecord.where(patient_id: @patient.id.to_s).order(created_at: :desc)
            @counsellor_record = @all_counsellor_records.find_by(patient_id: @patient.id.to_s, appointment_id: @appointment.id.to_s)
            @investigation_appointment = Appointment.where(patient_id: @patient.id.to_s, :user_id.in => @counsellors.pluck(:id), :appointmentstatus.nin => [89925002], :appointmentdate.gte => @counsellor_workflow.try(:counsellingdate))
          end

          # # for dilation allergy
          # @eyedrop_allergy = Array.new
          # @patient_allergy_eye_drops = @patient.patient_history.patientallergyhistory.eyedrops
          # if @patient_allergy_eye_drops
          #   @patient_allergy_eye_drops.each do |eyedrops|
          #     @eyedrop_allergy.push(@patient.get_label_for_allergy("eyedrops", eyedrops ))
          #   end
          # end

          # for dilation
          @patient_dilation_list = PatientDilation.where(appointment_id: @appointment.id.to_s, is_reseted: false).order(start_time: :desc)
          @patient_dilation = @patient_dilation_list[0] if @patient_dilation_list.count > 0

          # @dilation_advised_by = User.find_by(id: @appointment.dilation_advised_by).try(:fullname).to_s.titleize

          @eyedrop_allergy = []
          @patient_allergy_eye_drops = @patient.allergy_histories.where(allergy_subtype: 'eye_drops')
          @patient_allergy_eye_drops&.each do |eyedrops|
            @eyedrop_allergy.push(@patient.get_label_for_allergy('eyedrops', eyedrops))
          end
        end

        # @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

        @patient_language = @patient.try(:primary_language).to_s +
                            if @patient.primary_language.present? && @patient.secondary_language.present?
                              ', ' + @patient.try(:secondary_language).to_s
                            else
                              @patient.try(:secondary_language).to_s
                            end

        if @facility.clinical_workflow
          @clinical_workflow = OpdClinicalWorkflow.includes(:opd_clinical_workflow_state_transitions).find_by(appointment_id: params[:appointment_id])
          states = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).pluck(:to)
          @with_user = User.find_by(id: @clinical_workflow.user_id)
          @states = states.map(&:capitalize)
          get_time_between_states unless @states.empty?

          @clinical_workflow_timeline = @clinical_workflow.opd_clinical_workflow_state_transitions.order(created_at: :asc)
          @clinical_workflow_timeline_count = @clinical_workflow_timeline.count
          @users = User.where(facility_ids: current_facility.id, is_active: true)
        else

          # NonWorkflow TimeLine Calculations
          @waiting_time = @appointment_list_view.patient_time[0]
          @engaged_time = @appointment_list_view.patient_time[1]

          # Doctor
          @consulting_doctor = @appointment_list_view.consulting_doctor

          # For Counsellor in Non-workflow
          @users = User.where(facility_ids: current_facility.id, is_active: true)
          @counsellors = @users.where(role_ids: 499992366, is_active: true)
        end

        load_current_facility_doctors
        load_current_facility_nurses
        load_current_facility_optometrists
        load_current_facility_receptionists
        load_current_facility_counsellors
        load_current_facility_departments
      end

      def dilate_patient
        @appointment = Appointment.find_by(id: params[:appointment_id])
        @patient = Patient.find_by(id: @appointment.patient_id)
        @appointment.update_attributes(dilation_start_time: Time.current)
        @appointment.update_attributes(dilation_end_time: '')
      end

      def stop_dilation
        @appointment = Appointment.find_by(id: params[:appointment_id])
        @appointment.update_attributes(dilation_end_time: Time.current)
      end

      def get_time_between_states
        appointment_id = params[:appointment_id]
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s)
        state_transitions = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow.id)
        time_array = state_transitions.pluck(:created_at)
        # get time difference
        @time_difference = []
        time_array.each_with_index do |time, i|
          time = time.to_time
          next if i + 1 == time_array.length

          @time_difference[i] = TimeDifference.between(time_array[i + 1], time_array[i]).in_minutes
          # convert time to hrs and minutes
          @time_difference[i] = if @time_difference[i] > 60
                                  (@time_difference[i] / 60).floor.to_s + ' hr ' + (@time_difference[i].round % 60).to_s + ' mins'
                                else
                                  @time_difference[i].round.to_s + ' mins'
                                end
        end
        unless @states[@states.length - 1] == 'complete'
          @last = TimeDifference.between(time_array[time_array.length - 1].to_time, Time.current).in_minutes
          @last = if @last > 60
                    (@last / 60).floor.to_s + ' hr ' + (@last.round % 60).to_s + ' mins'
                  else
                    @last.round.to_s + ' mins'
                  end
        end
      end

      def new
        @current_user = User.find_by(id: params[:current_user_id])
        @patient = Patient.find_by(id: params[:patient_id]) || Patient.new

        @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current, :current_state.nin => ['Deleted']).order(appointment_date: :desc)[0]
        @current_facility = Facility.find(params[:current_facility_id])

        @current_date = Date.parse(params[:current_date]) || Date.current
        @current_time = Time.zone.parse(params[:current_time]) || Time.current
        @selected_facility = params[:current_facility_id] || @current_facility.id

        facility = Facility.find_by(id: @selected_facility)
        @available_specialties = Specialty.where(:id.in => facility.specialty_ids & @current_user.specialty_ids).pluck(:name, :id).sort
        @selected_specialty = @available_specialties.first[1] if @available_specialties.present? || ''

        @available_doctors = User.where(facility_ids: @selected_facility, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck(:id, :fullname)
        @appointment_types = AppointmentType.where(facility_id: @selected_facility.to_s, specialty_ids: @selected_specialty, is_active: true)
        @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, specialty_ids: @selected_specialty, is_active: true)

        @selected_doctor = params[:doctor_id] || (if @current_user.role_ids.include?(158965000) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)
                                                    @current_user.id
                                                  end) || User.where(role_ids: 158965000, facility_ids: @selected_facility, is_active: true)[0].id

        @appointment_slots = if @current_date < Date.current
                               {}
                             else
                               Appointment::Slot.new(@current_date.to_s, @current_facility.id, @selected_doctor).get
                             end

        @facilities = @current_user.facilities
        respond_to do |format|
          format.json { render 'new_appointment', layout: false }
        end
      end

      def get_users_from_facility
        @current_date = Date.parse(params[:current_date]) || Date.current
        @current_time = Time.zone.parse(params[:current_time]) || Time.current
        @current_user = User.find_by(id: params[:current_user_id])
        @current_facility = Facility.find_by(id: params[:current_facility_id])
        @selected_facility = Facility.find_by(id: params[:appointment_facility_id])
        @facilities = @current_user.facilities

        @available_specialties = Specialty.where(:id.in => @selected_facility.specialty_ids & @current_user.specialty_ids).pluck(:id, :name).sort
        @selected_specialty = params[:specialty_id] || if @available_specialties.present? then @available_specialties.first[0] end || ''

        @available_doctors = User.where(facility_ids: @selected_facility.id, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck(:id, :fullname)
        @selected_doctor = params[:doctor_id] || (if @current_user.role_ids.include?(158965000) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)
                                                    @current_user.id
                                                  end) || User.where(role_ids: 158965000, facility_ids: @selected_facility.id, specialty_ids: @selected_specialty)[0].id

        @appointment_types = AppointmentType.where(facility_id: @selected_facility.id, specialty_ids: @selected_specialty, is_active: true)
        @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, specialty_ids: @selected_specialty, is_active: true)

        @appointment_date = params[:appointmentdate]

        @appointment_slots = if Date.parse(@appointment_date) < Date.current
                               {}
                             else
                               Appointment::Slot.new(@appointment_date, @selected_facility.id, @selected_doctor).get
                             end

        respond_to do |format|
          format.json { render 'get_users_from_facility', layout: false }
        end
      end

      def get_appointment_type
        @appointment_type = AppointmentType.where(user_id: params[:user_id])
        respond_to do |format|
          format.json { render 'get_appointment_type', layout: false }
        end
      end

      def edit_patient_details
        @patient = Patient.find_by(id: params[:patient_id])
        @patient_asset = @patient.patientassets
        if !@patient_asset.empty?
          @user_profile_pic_url = @patient_asset[0].asset_path_url
        else
          @user_profile_pic_url = 'https://hg-user-assets.s3.amazonaws.com/profile-pics/592fe79f666d67271794c8e1_photo_20170601_153831.png'
        end
        respond_to do |format|
          format.json {}
        end
      end

      def patient_allergy_data
        @allergy = Global.ehrcommon
      end

      def edit_appointment_details
        @appointment = Appointment.find_by(id: params[:appointment_id])
        @current_user = User.find(params[:current_user_id])
        @selected_facility = @appointment.facility
        @selected_doctor = User.find_by(id: @appointment.consultant_id)
        @facilities = @current_user.facilities
        # @current_doctors = @selected_facility.users.where(role_ids: 158965000, is_active: true).sort(fullname: :asc) relation was not working
        @current_doctors = User.where(:facility_ids.in => [@selected_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc)
        @appointment_type = AppointmentType.where(facility_id: @selected_facility.id, is_active: true)
        @appointment_category = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.try(:organisation_id), is_active: true)
        if @appointment.appointmentdate < Date.current
          @appointment_slots = {}
        else
          @appointment_slots = Appointment::Slot.new(@appointment.appointmentdate.to_s, @selected_facility.id, @selected_doctor.id).get
        end
      end

      def refresh_edit_appointment_details
        @appointment = Appointment.find_by(id: params[:appointment_id])
        @current_user = User.find(params[:current_user_id])
        @selected_facility = Facility.find_by(id: params[:appointment_facility_id])
        @selected_doctor = User.find_by(id: params[:doctor_id])
        @facilities = @current_user.facilities
        @current_doctors = @selected_facility.users.where(role_ids: 158965000, is_active: true).sort(fullname: :asc)
        @appointment_type = AppointmentType.where(facility_id: @selected_facility.id, is_active: true)
        @appointment_category = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.try(:organisation_id), is_active: true)
        @appointment_date = params[:appointmentdate]

        @appointment_slots = if Date.parse(@appointment_date) < Date.current
                               {}
                             else
                               Appointment::Slot.new(@appointment_date, @selected_facility.id, @selected_doctor.id).get
                             end
      end

      def update
        @appointment = Appointment.find_by(id: params[:id])
        params[:appointment][:patient_id] = @appointment.patient_id.to_s
        current_user = User.find(params[:current_user_id])
        current_facility = Facility.find(params[:current_facility_id])
        if @appointment.update_attributes(appointment_params)
          @status_flag = true
          update_clinical_workflow
          respond_to do |format|
            format.json {}
          end
          Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'EDITED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
        else
          respond_to do |format|
            format.json {}
          end
        end
      end

      def addfollowupappointment
        @current_user = User.find(params[:current_user_id])
        @patient = Patient.find_by(id: params[:patient_id]) || Patient.new

        @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current).order(appointment_date: :desc)[0]
        @current_facility = Facility.find_by(id: params[:current_facility_id])
        @current_date = Date.parse(params[:current_date]) || Date.current
        @current_time = Time.zone.parse(params[:current_time]) || Time.current
        @selected_facility = params[:current_facility_id] || @current_facility.id

        facility = Facility.find_by(id: @selected_facility)

        @occupation_list = Global.send('occupation_list').send('sets').pluck(:name, :snomedcode)

        final_specialties = facility.specialty_ids & @current_user.specialty_ids
        unless final_specialties.present?
          final_specialties = facility.specialty_ids
        end # finding final_specialties of selected facility if no specialty present. for eg -> TPA case
        @available_specialties = Specialty.where(:id.in => final_specialties).pluck(:id, :name).sort
        @selected_specialty = @available_specialties.first[0] if @available_specialties.present? || ''

        @available_doctors = User.where(facility_ids: @selected_facility, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck(:id, :fullname)
        @appointment_types = AppointmentType.where(facility_id: @selected_facility.to_s, specialty_ids: @selected_specialty, is_active: true)
        @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, specialty_ids: @selected_specialty, is_active: true)

        @initial_referral_type = PatientReferralType.where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]
        @referral_types = ReferralType.where(is_active: true, :id.nin => ['FS-RT-0009'])

        @patient_types = PatientType.where(is_active: true, organisation_id: @current_user.organisation_id).pluck(:label, :id)

        @selected_doctor = params[:doctor_id] || (if @current_user.role_ids.include?(158965000) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)
                                                    @current_user.id
                                                  end) || User.where(role_ids: 158965000, facility_ids: @selected_facility, is_active: true)[0].id

        @appointment_slots = if @current_date < Date.current
                               {}
                             else
                               Appointment::Slot.new(@current_date.to_s, @current_facility.id, @selected_doctor).get
                             end

        @facilities = @current_user.facilities

        respond_to do |format|
          format.json {}
        end
      end

      private

      def create_patient_referral
        # Create SubReferral, Case: Relative, Self
        if params[:sub_referral_type].present?
          params[:sub_referral_type][:referral_type_id] = params[:patient_referral_type][:referral_type_id]
          params[:sub_referral_type][:facility_ids] = Facility.where(organisation_id: current_user.organisation_id).pluck(:id)
          if params[:sub_referral_type][:referral_type_id] == 'FS-RT-0001'
            @sub_referral_type = SubReferralType.find_by(referral_type_id: 'FS-RT-0001', organisation_id: current_user.organisation_id) # Case Self
          end
          unless @sub_referral_type.present?
            @sub_referral_type = SubReferralType.new(sub_referral_type_params)
            @sub_referral_type.save!
          end
          params[:patient_referral_type][:sub_referral_type_id] = @sub_referral_type.try(:id).to_s
        end
        if params[:patient_referral_type][:sub_referral_type_id].present?
          # Create PatientReferral Params
          params[:patient_referral_type][:patient_id] = @patient.id.to_s
          params[:patient_referral_type][:appointment_id] = @appointment.id.to_s
          params[:patient_referral_type][:facility_id] = @appointment.facility_id.to_s
          params[:patient_referral_type][:organisation_id] = @appointment.organisation_id.to_s

          # Create PatientReferral
          @patient_referral_type = PatientReferralType.new(patient_referral_type_params)
          @patient_referral_type.save!
        end
      end

      def sub_referral_type_params
        params.require(:sub_referral_type).permit(:is_active, :existing_patient, :name, :mobile_number, :email, :relation, :comment, :facility_ids, :user_id, :referral_type_id, :organisation_id)
      end

      def patient_referral_type_params
        params.require(:patient_referral_type).permit(:referral_type_id, :sub_referral_type_id, :patient_id, :appointment_id, :facility_id, :organisation_id)
      end

      def load_current_facility_doctors
        @current_facility_doctors_arr = []
        @current_facility_doctors = GetUsers.workflow_users_dropdown(@facility.id, [@specialty_id], 158965000)
        @current_facility_doctors.each do |doctor|
          doctor_hash = { name: doctor[1], user_id: doctor[0], pat_count: doctor[2] }
          @current_facility_doctors_arr.push(doctor_hash)
        end
      end

      def load_current_facility_nurses
        @current_facility_nurses_arr = []
        @current_facility_nurses = GetUsers.workflow_users_dropdown(@facility.id, [@specialty_id], 106292003)
        @current_facility_nurses.each do |nurse|
          nurse_hash = { name: nurse[1], user_id: nurse[0], pat_count: nurse[2] }
          @current_facility_nurses_arr.push(nurse_hash)
        end
      end

      def load_current_facility_optometrists
        @current_facility_optometrists_arr = []
        @current_facility_optometrists = GetUsers.workflow_users_dropdown(@facility.id, [@specialty_id], 28229004)
        @current_facility_optometrists.each do |optometrist|
          optometrist_hash = { name: optometrist[1], user_id: optometrist[0], pat_count: optometrist[2] }
          @current_facility_optometrists_arr.push(optometrist_hash)
        end
      end

      def load_current_facility_receptionists
        @current_facility_receptionists_arr = []
        @current_facility_receptionists = GetUsers.workflow_users_dropdown(@facility.id, [@specialty_id], 159561009)
        @current_facility_receptionists.each do |receptionist|
          receptionist_hash = { name: receptionist[1], user_id: receptionist[0], pat_count: receptionist[2] }
          @current_facility_receptionists_arr.push(receptionist_hash)
        end
      end

      def load_current_facility_counsellors
        @current_facility_counsellors_arr = []
        @current_facility_counsellors = GetUsers.workflow_users_dropdown(@facility.id, [@specialty_id], 499992366)
        @current_facility_counsellors.each do |counsellor|
          counsellor_hash = { name: counsellor[1], user_id: counsellor[0], pat_count: counsellor[2] }
          @current_facility_counsellors_arr.push(counsellor_hash)
        end
      end

      def load_current_facility_departments
        @departments_array = GetFacilities.current_facility_departments(@facility.id)
        @departments_array = @departments_array.sort_by! { |department| department[5] }

        if @current_user.role_ids.include?(387619007) || @specialty_id != '309988001'
          @departments_array.delete_if { |department| department[0] == '50121007' }
        end

        if @current_user.role_ids.include?(46255001)
          @departments_array.delete_if { |department| department[0] == '284748001' }
        end

        # for radiology_department
        if @current_user.role_ids.include?(41904004)
          @departments_array.delete_if { |department| department[0] == '309964003' }
        end

        # for laboratory_department
        if @current_user.role_ids.include?(159282002)
          @departments_array.delete_if { |department| department[0] == '261904005' }
        end

        # for ophthal_department
        if @current_user.role_ids.include?(159282002) || @specialty_id != '309988001'
          @departments_array.delete_if { |department| department[0] == '309935007' }
        end

        # provide tpa-department only to counsellor
        unless @current_user.role_ids.include?(499992366)
          @departments_array.delete_if { |department| department[0] == '450368792' }
        end

        @current_facility_departments_arr = []
        @departments_array.each do |department|
          facility_hash = { name: department[1], department_id: department[0], pat_count: department[2] }
          @current_facility_departments_arr.push(facility_hash)
        end
      end

      def appointment_params
        params.require(:appointment).permit(:facility_id, :consultant_id, :appointmenttype, :appointment_category_id, :appointment_type_id, :appointmentdate, :start_time, :patient_id, :department_id, :organisation_id, :user_id, :display_id, :opd_referral_id, :referral, :referral_created_on, :referring_doctor, :referee_doctor, :to_facility_name, :from_facility_name, :referral_note, :case_sheet_id, :specialty_id)
      end

      def update_clinical_workflow
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        if @clinical_workflow
          consultant_id = @clinical_workflow.consultant_ids
          consultant_id[0] = @appointment.consultant_id.to_s
          @clinical_workflow.update(facility_id: @appointment.facility_id, appointmentdate: @appointment.appointmentdate, consultant_ids: consultant_id)
        end
      end

      def reset_token
        @token_setting = TokenSetting.find_by(facility_id: @appointment.facility_id)

        # @used_tokens = $REDIS.get("used_tokens:#{@appointment.facility_id.to_s}:#{Date.current.strftime('%d%m%Y')}") || "{}"
        @used_tokens = Redis::Master.new.get("used_tokens:#{@appointment.facility_id}:#{Date.current.strftime('%d%m%Y')}") || '{}'
        if @used_tokens == '{}'
          @used_tokens = @token_setting.used_tokens.to_json if @token_setting.try(:used_tokens).present?
        end
        @new_used_tokens = JSON.parse(@used_tokens)

        @new_used_tokens.delete(@appointment.token_number)

        # @appointment.update(token_number: nil) if @appointment.present?

        # $REDIS.set("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}", @new_used_tokens.to_json)
        key = "used_tokens:#{@appointment.facility_id}:#{@appointment.appointmentdate.strftime('%d%m%Y')}"
        Redis::Master.new.set(key, @new_used_tokens.to_json)
        Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

        if @token_setting.present? && @appointment.appointmentdate == Date.current
          @token_setting.update(used_tokens: @new_used_tokens)
        end
      end

      def get_patient_params(patient_ids)
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
    end
  end
end
