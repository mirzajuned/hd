class Orders::FollowupsController < ApplicationController
  before_action :authorize

  before_action :set_initial_data, only: [:new, :edit]

  def new
    @order_followup = Order::Followup.new
  end

  def edit
    @order_followup = Order::Followup.find_by(id: params[:id])
  end

  def create
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @appointment = Appointment.find_by(id: params[:order_followup][:appointment_id])
    if params[:order_followup][:followup_date].present? && params[:order_followup][:followup_time].present?
      Orders::Followups::CreateService.call(@appointment.id.to_s, order_followup_params, current_facility.id.to_s)
    else
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Invalid Data', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  def update
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @appointment = Appointment.find_by(id: params[:order_followup][:appointment_id])
    if params[:order_followup][:followup_date].present? && params[:order_followup][:followup_time].present?
      Orders::Followups::UpdateService.call(@appointment.id.to_s, order_followup_params, current_facility.id.to_s)
    else
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Invalid Data', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  def show
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @followup = Order::Followup.find_by(id: params[:id])
    @order_procedures = Order::Advised.where(id: { "$in": @followup.order_advised_ids })
  end

  private

  def set_initial_data
    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @order_procedures = Order::Advised.where(case_sheet_id: params[:case_sheet_id], type: 'procedures', active: true)
    @counsellors = User.where(is_active: true, role_ids: 499992366, facility_ids: current_facility.id)
    @followups = Order::Followup.where(appointment_id: @appointment.id.to_s)
  end

  def order_followup_params
    if params[:order_followup].present? && params[:order_followup][:order_advised_ids].present?
      params[:order_followup][:order_advised_ids] = params[:order_followup][:order_advised_ids][0].is_a?(String) ? params[:order_followup][:order_advised_ids][0].split(',') : params[:order_followup][:order_advised_ids][0]
    end
    params[:order_followup][:create_appointment] = params[:order_followup][:create_appointment].is_a?(String) ? (params[:order_followup][:create_appointment] == 'true') : params[:order_followup][:create_appointment]
    params.require(:order_followup).permit(:id, :create_appointment, :followup_date, :followup_time, :followup_for_id, :counselling_date, :counselled_by_id, :appointment_id, :followup_notes, :followup_type, :created_by, :created_by_id, order_advised_ids: [], followup_reasons: [])
  end
end