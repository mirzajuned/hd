class Investigation::RedisService
  def initialize(queue_id)
    @investigation_queue_id = queue_id
  end

  def get_investigation_status
    # investigation_in_queue = $REDIS.get("investigation_queue:#{@investigation_queue_id}")
    investigation_in_queue = Redis::Master.new.get("investigation_queue:#{@investigation_queue_id}")
    if investigation_in_queue.nil?
      investigation_details = Investigation::InvestigationDetail.where(queue_id: @investigation_queue_id)
      if investigation_details.size > 0
        investigation_queue = investigation_details.pluck(:name, :state).map { |i| i[0].to_s + ": " + i[1].to_s.split('_').join(' ').camelcase }.join(' , ')
      end
      # $REDIS.set("investigation_queue:#{@investigation_queue_id}", investigation_queue)
      Redis::Master.new.set("investigation_queue:#{@investigation_queue_id}", investigation_queue)
      # investigation_in_queue = $REDIS.get("investigation_queue:#{@investigation_queue_id}")
      investigation_in_queue = Redis::Master.new.get("investigation_queue:#{@investigation_queue_id}")
    end
    investigation_in_queue
  end
end
