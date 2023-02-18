module AdmissionListViewsHelper
  def self.admission_type_insurance_state(admission)
    fa_insurance_state = admission.insurance_state == 'Not Insured' ? 'fa fa-money' : 'fa fa-medkit'

    if admission.admission_type == 'same_day'
      admission_type_hash = { abbr: 'SD', label: 'label label-pink' }
    elsif admission.admission_type == 'emergency'
      admission_type_hash = { abbr: 'ER', label: 'label label-danger' }
    elsif admission.admission_type == 'planned'
      admission_type_hash = { abbr: 'PD', label: 'label label-orange' }
    end

    admission_type_title = "#{admission.insurance_state&.titleize} - #{admission.admission_type&.titleize}"

    [fa_insurance_state, admission_type_hash[:abbr], admission_type_hash[:label], admission_type_title]
  end

  def self.next_milestone(admission, last_milestone)
    admission_milestones = Global.admission_milestones
    all_milestones = admission_milestones['milestones']

    milestone_request = admission.insurance_state != 'Not Insured' ? 'all_milestones' : 'ot_milestones'
    milestone_sequence = admission_milestones[milestone_request]

    last_position = milestone_sequence.index(last_milestone&.position.to_i) || -1
    next_position = milestone_sequence[last_position.to_i + 1]
    next_milestone = all_milestones.find { |m| m[:position] == next_position }

    next_milestone.present? ? next_milestone[:name] : ''
  end

  def self.update_redis_counter(facility_id, specialty_id, user_id, action = 'inc')
    date = Date.current.strftime('%d%m%Y')
    redis_key = "hash_key:facility:#{facility_id}:date:#{date}:specialty_id:#{specialty_id}:user:#{user_id}"
    # key_count = $REDIS.hmget(redis_key, :ipd_count)
    key_count = Redis::Master.new.hmget(redis_key, :ipd_count)
    inc_value = action == 'inc' ? 1 : -1
    # $REDIS.pipelined do
    # $REDIS.hincrby(redis_key, 'ipd_count', inc_value) unless key_count[0].nil?
    Redis::Master.new.hincrby(redis_key, 'ipd_count', inc_value) unless key_count.to_a[0].nil?
    # end
  end
end
