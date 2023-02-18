# rubocop:disable all
class TokenSettingsController < ApplicationController
  before_action :authorize
  before_action :find_appointment, only: [:show_tokens, :save_token, :skip_token, :remove_token]
  before_action :find_token_setting, only: [:show_tokens, :save_token, :remove_token]
  before_action :used_tokens, only: [:show_tokens, :save_token, :remove_token]

  def save
    if params[:facility_id].to_s == '0'
      @facilities = current_user.facilities.pluck(:id)
      @facilities.each do |facility_id|
        save_token_setting(facility_id)
      end
    else
      save_token_setting(params[:facility_id])
    end

    render json: { "success": true }
  end

  def show_tokens
    if params[:existing_token]
      @existing_token = params[:existing_token].to_i
    else
      @last_token_used = @new_used_tokens.keys.map(&:to_i)[-1]
    end
  end

  def save_token
    # Save/Update Tokens in Redis
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    if params[:from] == 'appointment_action' && @workflow.state != 'not_arrived'
      respond_to do |format|
        format.js { render js: '$("#btn-appointment-management-refresh").trigger("click")' }
      end
    else
      @new_used_tokens.delete(@appointment.token_number)
      @new_used_tokens[params[:token_number]] = @appointment.id.to_s

      @appointment.update(token_number: params[:token_number]) if @appointment.present?
      # $REDIS.set("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}", @new_used_tokens.to_json)
      key = "used_tokens:#{@appointment.facility_id}:#{@appointment.appointmentdate.strftime('%d%m%Y')}"
      Redis::Master.new.set(key, @new_used_tokens.to_json)
      Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

      if @token_setting.present? && @appointment.appointmentdate == Date.current
        @token_setting.update(used_tokens: @new_used_tokens)
      end
      if params[:existing_token].present? || @workflow.state != 'not_arrived'
        QueueManagementJobs::WorkflowJob.perform_later(@workflow.id.to_s, @workflow.facility_id.to_s)
        respond_to do |format|
          format.js { render js: '$("#btn-appointment-management-refresh").trigger("click")' }
        end
      else
        if current_facility.clinical_workflow # Workflow
          redirect_to opd_clinical_workflow_patient_arrived_path(appointment_id: @appointment.id,
                                                                 to_station: params[:to_station],
                                                                 assigned_as: params[:assigned_as])
        else # Non-Workflow
          redirect_to opd_clinical_workflow_mark_as_arrived_path(id: @appointment.id.to_s, appointment_id: @appointment.id.to_s, patient_arrived: true)
        end
      end
    end
  end

  def skip_token
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    if @workflow.state == 'not_arrived'
      if current_facility.clinical_workflow # Workflow
        redirect_to opd_clinical_workflow_patient_arrived_path(appointment_id: @appointment.id,
                                                               to_station: params[:to_station],
                                                               assigned_as: params[:assigned_as])
      else # Non-Workflow
        redirect_to opd_clinical_workflow_mark_as_arrived_path(id: @appointment.id.to_s, appointment_id: @appointment.id.to_s, patient_arrived: true)
      end
    else
      respond_to do |format|
        format.js { render js: '$("#btn-appointment-management-refresh").trigger("click")' }
      end
    end
  end

  def remove_token
    @new_used_tokens.delete(@appointment.token_number)

    @appointment.update(token_number: nil) if @appointment.present?

    # $REDIS.set("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}", @new_used_tokens.to_json)
    key = "used_tokens:#{@appointment.facility_id}:#{@appointment.appointmentdate.strftime('%d%m%Y')}"
    Redis::Master.new.set(key, @new_used_tokens.to_json)
    Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

    if @token_setting.present? && @appointment.appointmentdate == Date.current
      @token_setting.update(used_tokens: @new_used_tokens)
    end

    @workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    QueueManagementJobs::WorkflowJob.perform_later(@workflow.id.to_s, @workflow.facility_id.to_s)

    respond_to do |format|
      format.js { render js: '$("#btn-appointment-management-refresh").trigger("click")' }
    end
  end

  private

  def save_token_setting(facility_id)
    @token_setting = TokenSetting.find_by(facility_id: facility_id)
    if @token_setting.present?
      @token_setting.update(token_enabled: params[:token_enabled], sort_list_by_token: params[:sort_list_by_token])
    else
      TokenSetting.create(token_enabled: params[:token_enabled], sort_list_by_token: params[:sort_list_by_token], facility_id: facility_id)
    end
  end

  def find_appointment
    @appointment = Appointment.find_by(id: params[:appointment_id])
  end

  def find_token_setting
    @token_setting = TokenSetting.find_by(facility_id: @appointment.facility_id)
    return if @token_setting.nil? || @token_setting&.used_tokens_date == Date.current

    @token_setting&.update!(used_tokens: {}, used_tokens_date: Date.current)
  end

  def used_tokens
    # @used_tokens = $REDIS.get("used_tokens:#{@appointment.facility_id.to_s}:#{Date.current.strftime('%d%m%Y')}") || "{}"
    @used_tokens = Redis::Master.new.get("used_tokens:#{@appointment.facility_id}:#{Date.current.strftime('%d%m%Y')}") || '{}'
    if @used_tokens == '{}' && @token_setting&.used_tokens_date == Date.current
      @used_tokens = (@token_setting&.used_tokens || {}).to_json
    end
    @new_used_tokens = JSON.parse(@used_tokens)
  end
end
