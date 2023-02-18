class UserState
  include Mongoid::Document
  include Mongoid::Timestamps
  after_save :clear_redis_cache
  field :states, type: Array, default: [["OPD", "#008000"], ["OT", "#f0ad4e"], ["Offline", "#ff0000"]]
  field :active_state, type: String, default: "OPD"
  field :state_color, type: String, default: "#008000"
  field :inactive_states, type: Array, default: [["OT", "#f0ad4e"], ["Offline", "#ff0000"]]

  belongs_to :user
  belongs_to :facility

  def clear_redis_cache
    # $REDIS.del("user_state:#{self.user_id}#{self.facility_id}")
    Redis::Master.new.del("user_state:#{user_id}#{facility_id}")
  end
end
