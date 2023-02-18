class Investigation::InvestigationDetailsController < ApplicationController
  before_action :authorize
  before_action :set_current_facility
  before_action :find_investigation, :update_queue_appointment_date, except: [:new, :create, :action_on_multiple_investigation, :append_ophthal_set, :append_radiology_set, :save_upload_remark, :evaluate_image]

  def new
    if @current_user.role_ids.include?(158965000)
      @ophthal_laboratory_set = OphthalLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(doctor_id: @current_user.id.to_s, specialty_id: params[:specialty_id], is_active: true)
    else
      @ophthal_laboratory_set = OphthalLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, specialty_id: params[:specialty_id].to_s, is_active: true)
    end

    if params[:flag] == 'radiology'
      specialty_id = params[:specialty_id] == '309988001' ? '309988001' : '309989009' # Remove when all Speciality have Radiology
      @custom_radiology_investigations = CustomRadiologyInvestigation.where(organisation_id: @current_user.organisation_id, specialty_id: specialty_id.to_i, is_deleted: false)
      radiology_investigations = RadiologyInvestigationData.where(specialty_id: specialty_id.to_i)
      @radiology_investigation_xray = radiology_investigations.where(investigation_type_id: 363680008)
      @radiology_investigation_mri = radiology_investigations.not.where(investigation_type_id: 363680008)

    elsif params[:flag] == 'laboratory'
      laboratory_investigations = LaboratoryInvestigationData.where(facility_id: @current_facility.id, is_deleted: false, only_sub_test: false)
      @custom_laboratory_investigations = laboratory_investigations.where(is_custom: true)
      @laboratory_investigations = laboratory_investigations.where(is_custom: false)
      @user_set_type = UsersLaboratoryList.where(user_id: @current_user.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
      @facility_set_type = FacilityLaboratoryList.where(facility_id: @current_facility.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
      @set_type = @user_set_type + @facility_set_type

    elsif params[:flag] == 'ophthal'
      @custom_ophthal_investigations = CustomOphthalInvestigation.where(organisation_id: @current_user.organisation_id, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id.to_s, level: 'facility' }], is_deleted: false)
    end
    @appointment = Appointment.find_by(id: params[:appointment_id].to_s)
  end

  def create
    @patient = Patient.find_by(id: params[:patient_id])

    if params[:appointment_id].present?
      @appointment = Appointment.find_by(id: params[:appointment_id])
      case_sheet_id = @appointment.try(:case_sheet_id).to_s
    else
      case_sheet = CaseSheet.find_by(patient_id: @patient.id.to_s, is_active: true)
      case_sheet_id = case_sheet.try(:id).to_s
    end

    @queue = Investigation::Queues::CreateService.call(params[:appointment_id], @patient, params[:flag], @current_user, @current_facility, Time.current)
    if params[:flag] == 'ophthal'
      params[:ophthal_investigation].try(:each) do |_key, value|
        @ophthal_investigation = Investigation::Ophthal.new
        @ophthal_investigation['name'] = value['investigationname']
        @ophthal_investigation['investigation_side'] = value['investigationside']
        @ophthal_investigation['investigation_id'] = value['investigation_id']
        @ophthal_investigation['investigation_full_code'] = value['investigation_id']
        @ophthal_investigation['is_custom'] = value['is_custom']
        @ophthal_investigation['investigation_type'] = (if @ophthal_investigation['is_custom']
                                                          'CustomOphthalInvestigation'
                                                        end) || 'OphthalmologyInvestigationData'
        @ophthal_investigation['requested_by'] = @current_user.id
        @ophthal_investigation['order_item_advised_id'] = value['order_item_advised_id'].to_s
        @ophthal_investigation['entered_by'] = @current_user.id
        @ophthal_investigation['entered_by_username'] = @current_user.fullname
        @ophthal_investigation['entered_at'] = Time.current
        @ophthal_investigation['entered_at_facility_id'] = @current_facility.id
        @ophthal_investigation['entered_at_facility_name'] = @current_facility.name
        @ophthal_investigation['advised_by'] = @current_user.id
        @ophthal_investigation['advised_datetime'] = Time.current
        @ophthal_investigation['advised_by_username'] = @current_user.fullname
        @ophthal_investigation['advised_at'] = Time.current
        @ophthal_investigation['advised_at_facility_id'] = @current_facility.id
        @ophthal_investigation['advised_at_facility_name'] = @current_facility.name
        @ophthal_investigation['facility_id'] = @current_facility.id
        @ophthal_investigation['organisation_id'] = @current_facility.organisation_id
        @ophthal_investigation['patient_id'] = @patient.id
        @ophthal_investigation['appointment_id'] = @appointment.try(:id)
        @ophthal_investigation['queue_id'] = @queue.id
        @ophthal_investigation['case_sheet_id'] = case_sheet_id
        @ophthal_investigation['patient_fullname'] = @patient.fullname
        @ophthal_investigation['patient_mobilenumber'] = @patient.mobilenumber
        @ophthal_investigation['patient_district'] = @patient.district
        @ophthal_investigation['patient_commune'] = @patient.commune
        @ophthal_investigation['patient_city'] = @patient.city
        @ophthal_investigation['patient_state'] = @patient.state
        @ophthal_investigation['patient_pincode'] = @patient.pincode
        @ophthal_investigation['patient_display_id'] = @patient.patient_identifier_id
        @ophthal_investigation['patient_mrno'] = @patient.patient_mrn
        @ophthal_investigation['patient_location'] = @patient.patient_full_address
        @ophthal_investigation['patient_gender'] = @patient.gender
        @ophthal_investigation['patient_age'] = @patient.age
        @ophthal_investigation['patient_exact_age'] = @patient.exact_age
        @ophthal_investigation['specialization'] =  if value['investigationside'] == '40638003'
                                                      '(B/E)'
                                                    elsif value['investigationside'] == '18944008'
                                                      '(R)'
                                                    elsif value['investigationside'] == '8966001'
                                                      '(L)'
                                                    else
                                                      ''
                                                    end
        @ophthal_investigation.save
        if @ophthal_investigation.advised_at > @queue.appointment_time
          @queue.update(appointment_date: @ophthal_investigation.advised_at, appointment_time: @ophthal_investigation.advised_at)
        end

        CaseSheet::CreateInvestigationDetailService.call(@appointment, @ophthal_investigation, @current_facility.id, current_user.id)
        Investigation::PatientOpd::CreateService.call(@ophthal_investigation, params[:flag])
      end
    elsif params[:flag] == 'laboratory'
      params[:laboratory_investigation].try(:each) do |_key, value|
        @laboratory_investigation = Investigation::Laboratory.new
        @laboratory_investigation['name'] = value['investigationname']
        @laboratory_investigation['loinc_class'] = value['loinc_class']
        @laboratory_investigation['loinc_code'] = value['loinc_code']
        @laboratory_investigation['investigation_id'] = value['investigation_id']
        @laboratory_investigation['order_item_advised_id'] = value['order_item_advised_id'].to_s
        @laboratory_investigation['investigation_full_code'] = 'N'
        @laboratory_investigation['is_custom'] = value['is_custom']
        @laboratory_investigation['investigation_type'] = 'LaboratoryInvestigationData'
        @laboratory_investigation['requested_by'] = @current_user.id
        @laboratory_investigation['entered_by'] = @current_user.id
        @laboratory_investigation['entered_by_username'] = @current_user.fullname
        @laboratory_investigation['entered_at'] = Time.current
        @laboratory_investigation['entered_at_facility_id'] = @current_facility.id
        @laboratory_investigation['entered_at_facility_name'] = @current_facility.name
        @laboratory_investigation['advised_by'] = @current_user.id
        @laboratory_investigation['advised_by_username'] = @current_user.fullname
        @laboratory_investigation['advised_at'] = Time.current
        @laboratory_investigation['advised_datetime'] = Time.current
        @laboratory_investigation['advised_at_facility_id'] = @current_facility.id
        @laboratory_investigation['advised_at_facility_name'] = @current_facility.name
        @laboratory_investigation['facility_id'] = @current_facility.id
        @laboratory_investigation['organisation_id'] = @current_facility.organisation_id
        @laboratory_investigation['patient_id'] = @patient.id
        @laboratory_investigation['appointment_id'] = @appointment.try(:id)
        @laboratory_investigation['queue_id'] = @queue.id
        @laboratory_investigation['case_sheet_id'] = case_sheet_id
        @laboratory_investigation['patient_fullname'] = @patient.fullname
        @laboratory_investigation['patient_mobilenumber'] = @patient.mobilenumber
        @laboratory_investigation['patient_district'] = @patient.district
        @laboratory_investigation['patient_commune'] = @patient.commune
        @laboratory_investigation['patient_city'] = @patient.city
        @laboratory_investigation['patient_state'] = @patient.state
        @laboratory_investigation['patient_pincode'] = @patient.pincode
        @laboratory_investigation['patient_display_id'] = @patient.patient_identifier_id
        @laboratory_investigation['patient_mrno'] = @patient.patient_mrn
        @laboratory_investigation['patient_location'] = @patient.patient_full_address
        @laboratory_investigation['patient_gender'] = @patient.gender
        @laboratory_investigation['patient_age'] = @patient.age
        @laboratory_investigation['patient_exact_age'] = @patient.exact_age
        @laboratory_investigation.save
        if @laboratory_investigation.advised_at > @queue.appointment_time
          @queue.update(appointment_date: @laboratory_investigation.advised_at, appointment_time: @laboratory_investigation.advised_at)
        end

        CaseSheet::CreateInvestigationDetailService.call(@appointment, @laboratory_investigation, @current_facility.id, current_user.id)
        Investigation::PatientOpd::CreateService.call(@laboratory_investigation, params[:flag])
      end
    elsif params[:flag] == 'radiology'
      params[:radiology_investigation].try(:each) do |_key, value|
        @radiology_investigation = Investigation::Radiology.new
        @radiology_investigation['name'] = value['investigationname']
        @radiology_investigation['investigation_id'] = value['investigation_id']
        @radiology_investigation['investigation_full_code'] = value['investigation_id'].to_s + '###' + value['laterality'].to_s + '###' + value['loinc_code'].to_s
        @radiology_investigation['has_laterality'] = 'N'
        @radiology_investigation['laterality'] = value['laterality']
        @radiology_investigation['is_spine'] = 'Y'
        @radiology_investigation['loinc_code'] = value['loinc_code']
        @radiology_investigation['radiology_options'] = value['radiologyoptions']
        @radiology_investigation['is_custom'] = value['is_custom']
        @radiology_investigation['investigation_type'] = (if @radiology_investigation['is_custom']
                                                            'CustomRadiologyInvestigation'
                                                          end) || 'RadiologyInvestigationData'
        @radiology_investigation['requested_by'] = @current_user.id
        @radiology_investigation['order_item_advised_id'] = value['order_item_advised_id'].to_s
        @radiology_investigation['entered_by'] = @current_user.id
        @radiology_investigation['entered_by_username'] = @current_user.fullname
        @radiology_investigation['entered_at'] = Time.current
        @radiology_investigation['entered_at_facility_id'] = @current_facility.id
        @radiology_investigation['entered_at_facility_name'] = @current_facility.name
        @radiology_investigation['advised_by'] = @current_user.id
        @radiology_investigation['advised_by_username'] = @current_user.fullname
        @radiology_investigation['advised_at'] = Time.current
        @radiology_investigation['advised_datetime'] = Time.current
        @radiology_investigation['advised_at_facility_id'] = @current_facility.id
        @radiology_investigation['advised_at_facility_name'] = @current_facility.name
        @radiology_investigation['facility_id'] = @current_facility.id
        @radiology_investigation['organisation_id'] = @current_facility.organisation_id
        @radiology_investigation['patient_id'] = @patient.id
        @radiology_investigation['appointment_id'] = @appointment.try(:id)
        @radiology_investigation['queue_id'] = @queue.id
        @radiology_investigation['case_sheet_id'] = case_sheet_id
        @radiology_investigation['patient_fullname'] = @patient.fullname
        @radiology_investigation['patient_mobilenumber'] = @patient.mobilenumber
        @radiology_investigation['patient_district'] = @patient.district
        @radiology_investigation['patient_commune'] = @patient.commune
        @radiology_investigation['patient_city'] = @patient.city
        @radiology_investigation['patient_state'] = @patient.state
        @radiology_investigation['patient_pincode'] = @patient.pincode
        @radiology_investigation['patient_display_id'] = @patient.patient_identifier_id
        @radiology_investigation['patient_mrno'] = @patient.patient_mrn
        @radiology_investigation['patient_location'] = @patient.patient_full_address
        @radiology_investigation['patient_gender'] = @patient.gender
        @radiology_investigation['patient_age'] = @patient.age
        @radiology_investigation['patient_exact_age'] = @patient.exact_age
        @radiology_investigation['specialization'] =  if value['radiologyoptions'] == '90084008'
                                                       'w/o contrast'
                                                      elsif value['radiologyoptions'] == '51619007'
                                                       'with contrast'
                                                      elsif value['radiologyoptions'] == '429859008'
                                                       'with complete screening'
                                                      elsif value['radiologyoptions'] == '431985004'
                                                       'screening of other region'
                                                      elsif value['radiologyoptions'] == '22400007'
                                                       '3D-reconstruction'
                                                      else
                                                       ''
                                                      end
        @radiology_investigation.save
        if @radiology_investigation.advised_at > @queue.appointment_time
          @queue.update(appointment_date: @radiology_investigation.advised_at, appointment_time: @radiology_investigation.advised_at)
        end

        CaseSheet::CreateInvestigationDetailService.call(@appointment, @radiology_investigation, @current_facility.id, current_user.id)
        Investigation::PatientOpd::CreateService.call(@radiology_investigation, params[:flag])
      end
    end

    set_investigations
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def counselling_done
    @appointment = Appointment.find_by(id: @investigation.appointment_id)
    if @investigation.update!(counselled_by: @current_user.id, counselled_by_username: @current_user.fullname, counselled_at: Time.current, counselled_at_facility_id: @current_facility.id, counselled_at_facility_name: @current_facility.name)

      @investigation.counselled if @investigation.state != 'counselled' # Change State to Counselled
      
      order_advised = Order::Advised.find_by(order_item_advised_id: @investigation.order_item_advised_id.to_s)
      if order_advised
        order_advised.update(
          is_counselled: true,
          investigationstage: 'Counselled',
          status: 'Agreed',
          counselled_by: @investigation.counselled_by_username,
          counselled_by_id: @investigation.counselled_by,
          counselled_datetime: @investigation.counselled_at,
          counselled_from: 'add_investigation_details',
          counselled_at_facility: @investigation.counselled_at_facility_name,
          counselled_at_facility_id: @investigation.counselled_at_facility_id,
          agreed_by: @investigation.counselled_by_username,
          agreed_by_id: @investigation.counselled_by,
          agreed_datetime: @investigation.counselled_at,
          agreed_from: 'add_investigation_details',
          agreed_at_facility: @investigation.counselled_at_facility_name,
          agreed_at_facility_id: @investigation.counselled_at_facility_id
        )
        counselling_record = Order::CounsellingRecord.find_by(appointment_id: @appointment.id.to_s, created_at: (Date.today.beginning_of_day..Date.today.end_of_day))
        if counselling_record
          order_data = counselling_record.orders_data.find_by(order_advised_id: order_advised.id.to_s)
          order_data.update(status: "Agreed") if order_data
        end
        Orders::Trails::CreateService.call("Agreed", order_advised)
      end
      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    end
    CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
  end

  def investigation_performed_form
    if params[:flag] == 'inside'
      @users = User.where(facility_ids: @current_facility, :role_ids.in => [158965000, 159282002, 28229004, 159561009, 2822900478, 41904004], is_active: true)
    end
  end

  def investigation_performed
    params[:investigation][:performed_outside] = true if params[:flag] != 'inside'
    params[:investigation][:date_performed_at] = params[:investigation][:performed_at]
    params[:investigation][:performed_from] = 'add_investigation_details'
    @investigation.update_attributes(investigation_params)
    @investigation.performed if @investigation.state != 'performed' # Change State to Performed

    # @investigation_queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
    @investigation_details = Investigation::InvestigationDetail.where(queue_id: @investigation.queue_id.to_s)
    if @investigation_details.pluck(:state).include? 'performed' # if one inv is performed submit for review
      @status = 'review'
    elsif @investigation_details.pluck(:state).uniq[0] == 'removed' # if all investigations removed mark status completed
      @status = 'completed'
    else
      @status = 'pending'
    end
    @investigation_queue.update(status: @status, status_updated_at: Date.current)
    @appointment = Appointment.find_by(id: @investigation.appointment_id)
    order_advised = Order::Advised.find_by(order_item_advised_id: @investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.update(
        has_declined: false,
        has_agreed: false,
        is_advised: false,
        is_performed: true,
        is_performed_outside: params[:investigation][:performed_outside],
        performed_outside_by: params[:investigation][:performed_outside_by],
        investigationstage: 'Performed',
        status: "Performed",
        performed_by: @investigation.performed_by_username,
        performed_by_id: @investigation.performed_by,
        performed_datetime: @investigation.date_performed_at,
        performed_from: 'add_investigation_details',
        performed_at_facility: @investigation.performed_at_facility_name,
        performed_at_facility_id: @investigation.performed_at_facility_id,
        active: false
      )
      counselling_record = Order::CounsellingRecord.find_by(appointment_id: @appointment.id.to_s, created_at: (Date.today.beginning_of_day..Date.today.end_of_day))
      if counselling_record
        order_data = counselling_record.orders_data.find_by(order_advised_id: order_advised.id.to_s)
        order_data.update(status: "Performed") if order_data
      end
      Orders::Trails::CreateService.call("Performed", order_advised)
    end

    if @current_facility.organisation_id.to_s == '5e21ffd6cd29ba0ce0bf5a1e' # need to update for sankara medics
      begin
        ApiJobs::OrderStatusJob.perform_later('appointment', @investigation.appointment_id.to_s, 'medics', @current_facility.id.to_s, @investigation)
        LoggerService.new.integration(@investigation.to_a, 'integration', 'investigation')
        # ApiIntegration::OrderData.update_investigation_performed('appointment', @investigation.appointment_id.to_s, 'medics', @current_facility.id.to_s, @investigation)
      rescue StandardError
        LoggerService.new.integration(@investigation.try(:id), 'integration', 'investigation rescued')
      end
    end

    set_investigations
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end

    CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
  end

  def investigation_removed_form; end

  def investigation_removed
    params[:investigation][:date_removed_at] = params[:investigation][:removed_at]
    params[:investigation][:removed_from] = 'add_investigation_details'
    if @investigation.update_attributes(investigation_params)
      @investigation.removed if @investigation.state != 'removed' # Change State to Removed

      # @investigation_queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
      @investigation_details = Investigation::InvestigationDetail.where(queue_id: @investigation.queue_id.to_s)
      @appointment = Appointment.find_by(id: @investigation.appointment_id)
      if @investigation_details.pluck(:state).include? 'performed' # if one inv is performed submit for review
        @status = 'review'
      elsif @investigation_details.pluck(:state).uniq[0] == 'removed' # if all investigations removed mark status completed
        @status = 'completed'
      else
        @status = 'pending'
      end
      @investigation_queue.update(status: @status, status_updated_at: Date.current)
      order_advised = Order::Advised.find_by(order_item_advised_id: @investigation.order_item_advised_id.to_s)
      if order_advised
        order_advised.update(
          is_removed: true,
          is_cancelled: true,
          has_declined: false,
          has_agreed: false,
          is_advised: false,
          investigationstage: 'Removed',
          removed_by: @investigation.removed_by_username,
          removed_by_id: @investigation.removed_by,
          removed_datetime: @investigation.removed_at,
          removed_from: 'add_investigation_details',
          removed_at_facility: @investigation.removed_at_facility_name,
          removed_at_facility_id: @investigation.removed_at_facility_id,
          status: 'Cancelled',
          cancelled_by: @investigation.removed_by_username,
          cancelled_by_id: @investigation.removed_by,
          cancelled_datetime: @investigation.removed_at,
          cancelled_from: 'add_investigation_details',
          cancelled_at_facility: @investigation.removed_at_facility_name,
          cancelled_at_facility_id: @investigation.removed_at_facility_id
        )
        counselling_record = Order::CounsellingRecord.find_by(appointment_id: @appointment.id.to_s, created_at: (Date.today.beginning_of_day..Date.today.end_of_day))
        if counselling_record
          order_data = counselling_record.orders_data.find_by(order_advised_id: order_advised.id.to_s)
          order_data.update(status: "Cancelled") if order_data
        end
        Orders::Trails::CreateService.call("Cancelled", order_advised)
      end
      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    end
  end

  def investigation_declined
    if @investigation.update!(declined_by: @current_user.id, declined_by_username: @current_user.fullname, declined_at: Time.current, declined_at_facility_id: @current_facility.id, declined_at_facility_name: @current_facility.name, date_declined_at: Date.current)
      @investigation.declined if @investigation.state == 'counselled' || @investigation.state == 'advised'
      @appointment = Appointment.find_by(id: @investigation.appointment_id)

      order_advised = Order::Advised.find_by(order_item_advised_id: @investigation.order_item_advised_id.to_s)
      if order_advised
        order_advised.update(
          has_declined: true,
          has_agreed: false,
          is_advised: false,
          investigationstage: 'Declined',
          status: "Declined",
          declined_by: @investigation.declined_by_username,
          declined_by_id: @investigation.declined_by,
          declined_datetime: @investigation.declined_at,
          declined_from: 'add_investigation_details',
          declined_at_facility: @investigation.declined_at_facility_name,
          declined_at_facility_id: @investigation.declined_at_facility_id
        )
        counselling_record = Order::CounsellingRecord.find_by(appointment_id: @appointment.id.to_s, created_at: (Date.today.beginning_of_day..Date.today.end_of_day))
        if counselling_record
          order_data = counselling_record.orders_data.find_by(order_advised_id: order_advised.id.to_s)
          order_data.update(status: "Declined") if order_data
        end
        Orders::Trails::CreateService.call("Declined", order_advised)
      end

      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    end
  end

  def payment_done
    if @investigation.update!(payment_done: true, collected_by: @current_user.id, collected_by_username: @current_user.fullname, collected_at: Time.current, collected_at_facility_id: @current_facility.id, collected_at_facility_name: @current_facility.name)
      @investigation.payment_taken if @investigation.state != 'payment_taken' # Change State to PaymentDone

      queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
      queue.update(payment_taken: true) if queue.present?
      @appointment = Appointment.find_by(id: @investigation.appointment_id)
      order_advised = Order::Advised.find_by(order_item_advised_id: @investigation.order_item_advised_id.to_s)
      if order_advised
        order_advised.update(
          has_declined: false,
          has_agreed: false,
          is_advised: false,
          investigationstage: 'Payment Taken',
          status: "Payment Taken",
          payment_taken: true,
          payment_taken_by: @investigation.collected_by_username,
          payment_taken_by_id: @investigation.collected_by,
          payment_taken_datetime: @investigation.collected_at,
          payment_taken_from: 'add_investigation_details',
          payment_taken_at_facility: @investigation.collected_at_facility_name,
          payment_taken_at_facility_id: @investigation.collected_at_facility_id
        )
        counselling_record = Order::CounsellingRecord.find_by(appointment_id: @appointment.id.to_s, created_at: (Date.today.beginning_of_day..Date.today.end_of_day))
        if counselling_record
          order_data = counselling_record.orders_data.find_by(order_advised_id: order_advised.id.to_s)
          order_data.update(status: "Payment Taken") if order_data
        end
        Orders::Trails::CreateService.call("Payment Taken", order_advised)
      end

      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    end
  end

  def sent_outside
    if @investigation.update!(sent_outside_by: @current_user.id, sent_outside_by_username: @current_user.fullname, sent_outside_at: Time.current, sent_outside_at_facility_id: @current_facility.id, sent_outside_at_facility_name: @current_facility.name)
      @investigation.sent_outside if @investigation.state != 'sent_outside' # Change State to SentOutside
      @appointment = Appointment.find_by(id: @investigation.appointment_id)

      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    end
  end

  def start_test
    if @investigation.update!(started_test_at: Time.current, test_started_by: @current_user.id, test_started_by_username: @current_user.fullname, test_started_at_facility_id: @current_facility.id, test_started_at_facility_name: @current_facility.name)
      @investigation.test_started if @investigation.state != 'test_started' # Change State to TestStarted
      @appointment = Appointment.find_by(id: @investigation.appointment_id)

      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    end
  end

  def reviewed
    if @investigation.update!(reviewed_by: @current_user.id, reviewed_by_username: @current_user.fullname, reviewed_at: Time.current, reviewed_at_facility_id: @current_facility.id, reviewed_at_facility_name: @current_facility.name)
      @investigation.reviewed if @investigation.state != 'reviewed' # Change State to Reviewed
      @patient_investigation = Investigation::InvestigationDetail.where(queue_id: @investigation_queue.id)
      @investigation_queue
      @lab_record = LabRecord.find_by(id: @investigation.investigation_record_id)
      if @lab_record.present?
        if @investigation.state == 'reviewed'
          @lab_record.update(state: 'reviewed', reviewed_by: @investigation.reviewed_by)
        end
      end
      @ehr_record = EhrInvestigation::LaboratoryRecord.find_by(id: @investigation.ehr_investigation_record_id)
      if @ehr_record.present?
        if @investigation.state == 'reviewed'
          @ehr_record.update(state: 'reviewed', reviewed_by: @investigation.reviewed_by)
        end
      end
      if @patient_investigation.pluck(:state).uniq[0] == 'reviewed' && @patient_investigation.pluck(:state).uniq.count == 1
        @investigation_queue.update(status: 'completed')
      end
      @appointment = Appointment.find_by(id: @investigation.appointment_id)

      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    end
  end

  def undo_state
    options = { state: @investigation.previous_state.pop, previous_state: @investigation.previous_state }
    if params[:state] == 'counselled'
      advised_options = { is_counselled: false, counselled_by: nil, counselled_by_id: nil, counselled_datetime: nil, counselled_at_facility_id: nil, counselled_at_facility: nil, agreed_by: nil, agreed_by_id: nil, has_agreed: false, agreed_at_facility: nil, agreed_at_facility_id: nil, agreed_datetime: nil }
      options = options.merge({ counselled_by: nil, counselled_by_username: nil, counselled_at: nil, counselled_at_facility_id: nil, counselled_at_facility_name: nil })
    elsif params[:state] == 'payment_taken'
      advised_options = { payment_taken: false, payment_taken_by: nil, payment_taken_by_id: nil, payment_taken_datetime: nil, payment_taken_at_facility_id: nil, payment_taken_at_facility: nil }
      options = options.merge({ payment_done: false, collected_by: nil, collected_at: nil, collected_at_facility_id: nil, collected_at_facility_name: nil })
    elsif params[:state] == 'performed'
      advised_options = { performed_outside: false, is_performed: false, performed_time: nil, performed_date: nil, performed_datetime: nil, performed_by: nil, performed_by_id: nil, performed_from: nil, performed_at_facility_id: nil, performed_at_facility: nil }
      options = options.merge({ performed_outside: false, performed_at: nil, date_performed_at: nil, performed_by: nil, performed_by_username: nil, performed_from: nil, performed_at_facility_id: nil, performed_at_facility_name: nil })
    elsif params[:state] == 'test_started'
      advised_options = { started_test_at: false, started_test_at_facility_id: nil, started_test_at_facility_name: nil }
      options = options.merge({ started_test_at: nil, started_test_at_facility_id: nil, started_test_at_facility_name: nil })
    elsif params[:state] == 'sent_outside'
      advised_options = { sent_outside: false, sent_outside_at: nil, sent_outside_at_facility_id: nil, sent_outside_at_facility_name: nil }
      options = options.merge({ sent_outside: false, sent_outside_at: nil, sent_outside_at_facility_id: nil, sent_outside_at_facility_name: nil })
    elsif params[:state] == 'removed'
      advised_options = { is_removed: false, removed_by: nil, removed_by_id: nil, removed_datetime: nil, removed_at_facility_id: nil, removed_at_facility: nil }
      options = options.merge({ removed_by: nil, removed_at: nil, date_removed_at: nil, removed_at_facility_id: nil, removed_at_facility_name: nil })
    elsif params[:state] == 'declined'
      advised_options = { has_declined: false, declined_by: nil, declined_by_id: nil, declined_datetime: nil, declined_at_facility_id: nil, declined_at_facility: nil }
      options = options.merge({ declined_by: nil, declined_by_username: nil, declined_at: nil, date_declined_at: nil, declined_at_facility_id: nil, declined_at_facility_name: nil })
    elsif params[:state] == 'reviewed'
      advised_options = {}
      options = options.merge({ reviewed_by: nil, reviewed_by_username: nil, reviewed_at: nil, reviewed_at_facility_id: nil, reviewed_at_facility_name: nil })
    end

    if @investigation.try(:update, options)
      if params[:state] == 'payment_taken'
        queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
        queue.update(payment_taken: false) if queue.present?
      end

      case @investigation.state
      when "payment_taken"
        status = "Payment Taken"
        advised_options = advised_options.merge(payment_taken: true, payment_taken_by: current_user.fullname, payment_taken_by_id: current_user.id, payment_taken_at_facility: current_facility.name, payment_taken_at_facility_id: current_facility.id, payment_taken_datetime: Time.current)
      when "counselled"
        status = "Agreed"
        advised_options = advised_options.merge(is_counselled: true, has_agreed: true, agreed_by: current_user.fullname, agreed_by_id: current_user.id, agreed_at_facility: current_facility.name, agreed_at_facility_id: current_facility.id, agreed_datetime: Time.current, counselled_by: current_user.fullname, counselled_by_id: current_user.id, counselled_at_facility: current_facility.name, counselled_at_facility_id: current_facility.id, counselled_datetime: Time.current)
      when "removed"
        status = "Removed"
        advised_options = advised_options.merge(is_removed: true, removed_by: current_user.fullname, removed_by_id: current_user.id, removed_at_facility: current_facility.name, removed_at_facility_id: current_facility.id, removed_datetime: Time.current)
      when "declined"
        status = "Declined"
        advised_options = advised_options.merge(has_declined: true, declined_by: current_user.fullname, declined_by_id: current_user.id, declined_at_facility: current_facility.name, declined_at_facility_id: current_facility.id, declined_datetime: Time.current)
      when "performed"
        status = "Performed"
        advised_options = advised_options.merge(is_performed: true, performed_by: current_user.fullname, performed_by_id: current_user.id, performed_at_facility: current_facility.name, performed_at_facility_id: current_facility.id, performed_datetime: Time.current)
      else
        status = "Advised"
        advised_options = advised_options.merge(is_advised: true, advised_by: current_user.fullname, advised_by_id: current_user.id, advised_at_facility: current_facility.name, advised_at_facility_id: current_facility.id, advised_datetime: Time.current)
      end

      advised_options = advised_options.merge(payment_taken: false) if params[:state] == 'payment_taken'

      order_advised = Order::Advised.find_by(order_item_advised_id: @investigation.order_item_advised_id.to_s)
      if order_advised
        order_advised.update(advised_options.merge(status: status))
        counselling_record = Order::CounsellingRecord.find_by(appointment_id: @investigation.appointment_id.to_s, created_at: (Date.today.beginning_of_day..Date.today.end_of_day))
        if counselling_record
          order_data = counselling_record.orders_data.find_by(order_advised_id: order_advised.id.to_s)
          order_data.update(status: status) if order_data
        end
        Orders::Trails::CreateService.call(status, order_advised)
        advised_investigation = CaseSheet.find_by(id: @investigation.case_sheet_id.to_s).send(order_advised.type).find_by(order_item_advised_id: order_advised.order_item_advised_id.to_s)
        if advised_investigation
          advised_investigation.update(advised_options.merge(investigationstage: (status == "Agreed" ? "Counselled" : status)))
        end
      end

      # @investigation_queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
      @investigation_details = Investigation::InvestigationDetail.where(queue_id: @investigation.queue_id.to_s)
      if @investigation_details.pluck(:state).any? { |i| ['performed', 'template_created'].include? i }
        # if one inv is performed submit for review
        @status = 'review'
      elsif @investigation_details.pluck(:state).uniq[0] == 'removed' && @investigation_details.pluck(:state).uniq.count == 1 # if all investigations removed mark status completed
        @status = 'completed'
      else
        @status = 'pending'
      end
      @investigation_queue.update(status: @status, status_updated_at: Date.current)
      @appointment = Appointment.find_by(id: @investigation.appointment_id)

      set_investigations
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
      @lab_record = LabRecord.find_by(id: @investigation.try(:investigation_record_id))
      if @lab_record.present?
        @lab_record.update(state: @investigation.state, reviewed_by: nil) if @investigation.state != 'reviewed'
      end
      @ehr_record = EhrInvestigation::LaboratoryRecord.find_by(id: @investigation.try(:ehr_investigation_record_id))
      if @ehr_record.present?
        @ehr_record.update(state: @investigation.state, reviewed_by: nil) if @investigation.state != 'reviewed'
      end

      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @current_facility.id, current_user.id)
    else
      head :ok
    end
  end

  def save_upload_remark
    @investigation_details = Investigation::InvestigationDetail.find_by(id: params[:investigation_detail_id])
    @investigation_details.update(upload_remark: params[:upload_remark])
    head :ok
  end

  def read_file_remote(url)
    uri = URI(url)
    data = Net::HTTP.get_response(uri)
    data.body
  end

  def evaluate_image
    eye_image_url = params[:image]
    @investigation_detail = Investigation::InvestigationDetail.find_by(id: params[:investigation_detail_id])

    image_data_extension = eye_image_url.split(".")[-1]

    image_data_binary = read_file_remote(eye_image_url)

    temp_img_file = Tempfile.new('data_uri-upload')
    temp_img_file.binmode
    temp_img_file << image_data_binary
    temp_img_file.rewind


    img_params = { filename: "data-uri-img.#{image_data_extension}", type: 'image/jpeg', tempfile: temp_img_file }
    uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

    file_name = 'test'

    api_key = 'swkSTOEIXhKemrHSaGKmeIfH4oo12z'
    url = 'https://myhealth.co.bd/api/dr-prediction'

    payload = {'api_key' => api_key,
               'file_name' => file_name,
               'eye_image' => uploaded_file
    }

    request = RestClient::Request.execute(method: :post, url: url, payload: payload, headers: { 'Content-Type' => 'application/json' })
    response = JSON.parse(request)["response"]

    if response.present? && response["code"] == "200"
      @investigation_detail.update(evaluation_data: response['data'])
    else
      head :ok
    end
  end

  def append_ophthal_set
    @ophthal_laboratory_set = OphthalLaboratorySet.find_by(id: params[:id])
    @data = (JSON.parse(@ophthal_laboratory_set.try(:data)) if @ophthal_laboratory_set.present?) || {}
  end

  def append_radiology_set
    @radiology_laboratory_set = RadiologyLaboratorySet.find_by(id: params[:id])
    @data = (JSON.parse(@radiology_laboratory_set.try(:data)) if @radiology_laboratory_set.present?) || {}
  end

  def action_on_multiple_investigation
    @task = params[:task]
    @investigation_ids = params[:investigation_ids]
    if @investigation_ids.blank?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Hurray', text: 'All caught up! No #{@task.capitalize} left  :)', type: 'info' }); notice.get().click(function(){ notice.remove() });" }
      end
      # notify('info',"No #{@task.capitalize} Pending",'Info')
    else
      @investigation_details = Investigation::InvestigationDetail.find(@investigation_ids)

      @investigation_details.map(&:counselled) if @task == 'counselling'
      if @task == 'counselling'
        @investigation_details.map { |inv| inv.update!(counselled_by: @current_user.id, counselled_by_username: @current_user.fullname, counselled_at: Time.current, counselled_at_facility_id: @current_facility.id, counselled_at_facility_name: @current_facility.name) }
      end

      @investigation_details.map(&:payment_taken) if @task == 'payments'
      if @task == 'payments'
        @investigation_details.map { |inv| inv.update!(payment_done: true, collected_by: @current_user.id, collected_by_username: @current_user.fullname, collected_at: Time.current, collected_at_facility_id: @current_facility.id, collected_at_facility_name: @current_facility.name) }
      end

      @investigation_details.each(&:reviewed) if @task == 'review'
      if @task == 'review'
        @investigation_details.map { |inv| inv.update!(reviewed_by: @current_user.id, reviewed_by_username: @current_user.fullname, reviewed_at: Time.current, reviewed_at_facility_id: @current_facility.id, reviewed_at_facility_name: @current_facility.name) }
      end
      @investigation_queue = Investigation::Queue.find_by(id: @investigation_details[0].queue_id.to_s)
      if @investigation_details.map(&:state).uniq[0] == 'reviewed' && @investigation_details.map(&:state).uniq.count == 1
        @investigation_queue.update(status: 'completed')
      end
      @investigation_details.each do |record|
        if @task == 'review'
          @lab_record = LabRecord.find_by(id: record.investigation_record_id)
          @lab_record.update(state: record.state, reviewed_by: record.reviewed_by) if @lab_record.present?
          @ehr_record = EhrInvestigation::LaboratoryRecord.find_by(id: record.ehr_investigation_record_id)
          @ehr_record.update(state: record.state, reviewed_by: record.reviewed_by) if @ehr_record.present?
        end
        @appointment = Appointment.find_by(id: record.appointment_id)
        CaseSheet::CreateInvestigationDetailService.call(@appointment, record, @current_facility.id, current_user.id)
      end
    end
  end

  private

  def set_current_facility
    @current_user = current_user
    @current_facility = current_facility
  end

  def investigation_params
    params.require(:investigation).permit(:performed_outside, :performed_outside_by, :performed_by, :performed_by_username, :performed_at, :date_performed_at, :performed_at_facility_id, :performed_at_facility_name, :performed_from, :removing_reason, :removed_by, :removed_by_username, :removed_at, :date_removed_at, :removed_at_facility_id, :removed_at_facility_name, :removed_from)
  end

  def find_investigation
    @investigation = Investigation::InvestigationDetail.find_by(id: params[:investigation_id])
    @investigation_queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
  end

  def update_queue_appointment_date
    @investigation_queue.update(appointment_date: Time.current, appointment_time: Time.current)
  end

  def notify(type, message, title)
    # p type,message,title
    respond_to do |format|
      format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: #{title}, text: #{message}, type: #{type} }); notice.get().click(function(){ notice.remove() });" }
    end
  end

  def set_investigations
    # Overview Tab - Investigations Refresh
    params[:new_ui] = true

    patient_id = @investigation&.patient_id || @patient&.id
    investigations = Investigation::InvestigationDetail.where(patient_id: patient_id, is_deleted: false)
                                                       .order(advised_at: :desc)
                                                       .group_by(&:_type)
    @ophthal_investigations = investigations['Investigation::Ophthal'].to_a
    @laboratory_investigations = investigations['Investigation::Laboratory'].to_a
    @radiology_investigations = investigations['Investigation::Radiology'].to_a
  end
end
