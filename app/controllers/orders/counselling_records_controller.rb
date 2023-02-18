class Orders::CounsellingRecordsController < ApplicationController
  before_action :authorize
  before_action :set_initial_data, only: [:new, :edit]

  def new
    @counselling_record = Order::CounsellingRecord.new(case_sheet_id: @case_sheet.id,appointment_id: @appointment.id)
    @order_procedures.each do |op|
      @counselling_record.orders_data.build(order_advised_id: op.id.to_s, type: 'procedures', status: op.status)
    end

    @order_investigations.each do |op|
      @counselling_record.orders_data.build(order_advised_id: op.id.to_s, type: op.type, status: op.status)
    end
    @orders_data = @counselling_record.orders_data.where.not(status: { "$in" => ["Performed", "Cancelled"] }).sort_by{|od| od.status == "Declined" ? 1 : (od.status == "No Action Taken" ? 0 : 2) }
    @counsellors = User.where(is_active: true, role_ids: 499992366, facility_ids: current_facility.id)
  end

  def edit
    @counselling_record = Order::CounsellingRecord.find(params[:id])
    @order_procedures.each do |op|
      @counselling_record.orders_data.find_or_initialize_by(order_advised_id: op.id.to_s, type: 'procedures')
    end
    @order_investigations.each do |op|
      @counselling_record.orders_data.find_or_initialize_by(order_advised_id: op.id.to_s, type: op.type)
    end
    @orders_data = @counselling_record.orders_data.where.not(status: { "$in" => ["Performed", "Cancelled"] }).sort_by{|od| od.status == "Declined" ? 1 : (od.status == "No Action Taken" ? 0 : 2) }
    @counsellors = User.where(is_active: true, role_ids: 499992366, facility_ids: current_facility.id)
  end

  def create
    @case_sheet = CaseSheet.find_by(id: counselling_record_params[:case_sheet_id])
    counselling_params = counselling_record_params
    if params[:order_counselling_record][:order_attributes].present?
      Orders::Advised::CreateService.call(params[:order_counselling_record][:order_attributes], @case_sheet.id.to_s, counselling_params[:appointment_id], current_user, current_facility)
    end
    if counselling_params[:orders_data_attributes].present?
      counselling_params[:orders_data_attributes].delete_if{ |a,b| b[:status].blank? }
    end
    counselling_params[:display_id] = CommonHelper.get_counselling_record_identifier
    @counselling_record = Order::CounsellingRecord.new(counselling_params)
    if @counselling_record.save
      Orders::Advised::UpdateService.call(@counselling_record.id.to_s, @case_sheet.id.to_s, current_facility)

      Patients::Summary::TimelineWorker.call({ event_name: "COUNSELLING_RECORD", sub_event_name: "CREATED", counselling_record_id: @counselling_record.id, user_id: current_user.id, user_name: current_user.fullname })


    end
    Orders::Advised::CreateService.update_active_order(@case_sheet.organisation.organisations_setting.active_advise_order_rule, @case_sheet.id.to_s)
  end

  def update
    @counselling_record = Order::CounsellingRecord.find(params[:id])
    counselling_params = counselling_record_params
    @case_sheet = CaseSheet.find_by(id: counselling_params[:case_sheet_id])
    if params[:order_counselling_record][:order_attributes].present?
      Orders::Advised::CreateService.call(params[:order_counselling_record][:order_attributes], @case_sheet.id.to_s, counselling_params[:appointment_id], current_user, current_facility)
    end
    if counselling_params[:orders_data_attributes].present?
      counselling_params[:orders_data_attributes].delete_if{ |a,b| b[:status].blank? && b[:id].blank? }
      Orders::CounsellingRecords::RemoveService.call(@counselling_record, counselling_params[:orders_data_attributes])
    end
    if @counselling_record.update(counselling_params)
      Orders::Advised::UpdateService.call(@counselling_record.id.to_s, @case_sheet.id.to_s, current_facility)

      Patients::Summary::TimelineWorker.call({ event_name: "COUNSELLING_RECORD", sub_event_name: "UPDATED", counselling_record_id: @counselling_record.id, user_id: current_user.id, user_name: current_user.fullname })

    end
    Orders::Advised::CreateService.update_active_order(@case_sheet.organisation.organisations_setting.active_advise_order_rule, @case_sheet.id.to_s)
  end

  def show
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @counselling_record = Order::CounsellingRecord.find(params[:id])
    @order_procedures = Order::Advised.where(case_sheet_id: params[:case_sheet_id], type: 'procedures', active: true)
    @order_investigations = Order::Advised.where(case_sheet_id: params[:case_sheet_id], type: { "$in": ["ophthal_investigations", "radiology_investigations", "laboratory_investigations"] }, active: true)
    @orders_data = @counselling_record.orders_data.sort_by{|od| od.status == "Declined" ? 1 : (od.status == "No Action Taken" ? 0 : 2) }
  end

  def add_orders_data
    @counselling_record = Order::CounsellingRecord.find_by(id: params[:id])
    @order_advised = Order::Advised.find(params[:order_advised_id])
    if @counselling_record
      @counselling_record.orders_data.build(order_advised_id: params[:order_advised_id], type: @order_advised.type)
    else
      @counselling_record = Order::CounsellingRecord.build(case_sheet_id: params[:case_sheet_id],appointment_id: params[:appointment_id], order_advised_id: params[:order_advised_id], type: @order_advised.type)
    end
  end

  def get_investigation_details
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    if params[:investigation_type] == "RadiologyInvestigationData"
      investigation_id = params[:investigation_id].to_i
    else
      investigation_id = params[:investigation_id]
    end
    @investigation = params[:investigation_type].constantize.find_by(investigation_id: investigation_id)
    order_advised_params = {
      investigationname: @investigation.investigation_name,
      investigation_id: @investigation.investigation_id,
      investigationfullcode: @investigation.investigation_id,
      investigationstage: "Advised",
      investigation_type: params[:investigation_type],
      entered_by_id: current_user.id,
      entered_by: current_user.fullname,
      entered_from: "counselling_record",
      entered_at_facility_id: current_facility.id,
      entered_at_facility: current_facility.name,
      entered_datetime: Time.current,
      advised_by_id: current_user.id,
      advised_by: current_user.fullname,
      advised_from: "counselling_record",
      advised_at_facility_id: current_facility.id,
      advised_at_facility: current_facility.name,
      advised_datetime: Time.current,
      type: get_investigation_type,
      status: "Advised",
      quantity: 1,
      case_sheet_id: @case_sheet.id
    }
    if params[:investigation_type] == "RadiologyInvestigationData"
      order_advised_params[:haslaterality] = @investigation.has_laterality
    elsif params[:investigation_type] == "OphthalmologyInvestigationData" || params[:investigation_type] == "CustomOphthalInvestigation"
      order_advised_params[:investigationside] = "40638003"
      order_advised_params[:quantity] = 2
    elsif params[:investigation_type] == "LaboratoryInvestigationData"
      order_advised_params[:loinc_class] = @investigation.loinc_class
      order_advised_params[:loinc_code] =  @investigation.loinc_code
    else
    end

    @order_advised = Order::Advised.new(order_advised_params)
    @counselling_record = Order::CounsellingRecord.build({order_advised_id: @order_advised.id.to_s})
    @from = "counselling_record"
    respond_to do |format|
      format.html { render partial: "orders/counselling_records/add_orders_data_form.html.erb" }
    end
  end

  private

  def set_initial_data
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @order_investigations = Order::Advised.where(case_sheet_id: params[:case_sheet_id], type: { "$in": ["ophthal_investigations", "radiology_investigations", "laboratory_investigations"] }, active: true).where.not(status: { "$in" => ["Performed", "Cancelled"] })
    @order_investigations = @order_investigations.sort_by{|od| od.status == "Declined" ? 1 : (od.status == "Advised" ? 0 : 2) }
    @order_procedures = Order::Advised.where(case_sheet_id: params[:case_sheet_id], type: 'procedures', active: true).where.not(status: { "$in" => ["Performed", "Cancelled"] })
    @order_procedures = @order_procedures.sort_by{|od| od.status == "Declined" ? 1 : (od.status.blank? ? 0 : 2) }
  end

  def get_investigation_type
    case params[:investigation_type]
    when "CustomOphthalInvestigation"
      "ophthal_investigations"
    when "OphthalmologyInvestigationData"
      "ophthal_investigations"
    when "LaboratoryInvestigationData"
      "laboratory_investigations"
    when "CustomRadiologyInvestigation"
      "radiology_investigations"
    when "RadiologyInvestigationData"
      "radiology_investigations"
    end
  end

  def counselling_record_params
    params.require(:order_counselling_record).permit(
        :id, :type, :case_sheet_id, :appointment_id, :counselled_by, :counselled_by_id, :counselled_on, :entered_by,
        :entered_by_id, :entered_on, :comment, :display_id, :user_id, :facility_id, :organisation_id, :patient_id,
        orders_data_attributes: [:id, :patient_comment, :counsellor_comment, :status, :recounselled, :type,
                                 :order_advised_id])
  end
end