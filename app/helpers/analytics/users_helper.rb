module Analytics::UsersHelper
  def self.time_in_hrs_minutes(value)
    hrs = (value / 60).to_i
    minutes = (value % 60).to_i
    time = "#{hrs} H #{minutes} M"

    time
  end
end
