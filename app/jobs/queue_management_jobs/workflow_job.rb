class QueueManagementJobs::WorkflowJob < ActiveJob::Base
  queue_as :urgent

  QMLOGGER = Logger.new("#{Rails.root}/log/queue_management.log")

  def perform(workflow_id, facility_id)
    return unless queue_management_enabled?(facility_id)

    @workflow = OpdClinicalWorkflow.find_by(id: workflow_id)
    raise NoMethodError, "Invalid WorkflowId: #{workflow_id}." if @workflow.nil?

    update_redis_keys(facility_id, @workflow.patient_id, @workflow.area_id)

    return unless status
    channel_options = { patient_name: @workflow.patient_name, patient_token: @workflow.token_number&.to_i || '',
                        station_code: station_code, status: status, workflow_id: @workflow.id.to_s }

    ActionCable.server.broadcast("queue_#{@workflow.station_id}_channel", channel_options)
    ActionCable.server.broadcast("queue_#{@workflow.area_id}_channel", channel_options)
  rescue StandardError => e
    QMLOGGER.info("WorkflowJob: #{e}")
  end

  private

  def update_redis_keys(facility_id, patient_id, area_id)
    date = Date.today.strftime('%d%m%Y')
    expire_at = ((Date.today + 1).to_time + 2.hours).to_i

    # Reference Key for ZADD & HMSET
    patient_key = "qm:facility:#{facility_id}:date:#{date}:patient_id:#{patient_id}"

    # HMSET Patient Key
    hash_patient_key = "hash_key:#{patient_key}"
    $REDIS.hmset(hash_patient_key, :patient_name, @workflow.patient_name, :patient_token, @workflow.token_number,
                 :station_code, station_code, :station_id, station_id, :status, status, :area_name, area&.name,
                 :area_id, area_id, :workflow_id, @workflow.id.to_s)
    $REDIS.expireat hash_patient_key, expire_at

    # ZADD Area Key
    zadd_area_key = "qm:facility:#{facility_id}:date:#{date}:area_id:#{area_id}"
    $REDIS.zadd zadd_area_key, 1, patient_key
    $REDIS.expireat zadd_area_key, expire_at

    # ZADD Station Key
    zadd_station_key = "qm:facility:#{facility_id}:date:#{date}:station_id:#{@workflow.station_id}"
    $REDIS.zadd zadd_station_key, 1, patient_key
    $REDIS.expireat zadd_station_key, expire_at
  end

  def queue_management_enabled?(facility_id)
    facility_setting = FacilitySetting.find_by(facility_id: facility_id)
    facility_setting.queue_management
  end

  def station_code
    if @workflow.in_sub_station
      @workflow.sub_station_code
    elsif @workflow.in_station
      @workflow.station_code
    end
  end

  def station_id
    if @workflow.in_sub_station
      @workflow.sub_station_id
    elsif @workflow.in_station
      @workflow.station_id
    end
  end

  def area
    QueueManagement::Area.find_by(id: @workflow.area_id)
  end

  def status
    state = @workflow.state
    if state == 'check_out'
      'Waiting'
    elsif state == 'call'
      'Call'
    elsif ['complete', 'away', 'not_arrived', 'incomplete', 'cancelled'].exclude?(state)
      'Engaged'
    end
  end
end
