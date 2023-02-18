class TimingsJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    @schedule = Hash.new

    @schedule[:sunday] = ""
    @schedule[:monday] = ""
    @schedule[:tuesday] = ""
    @schedule[:wednesday] = ""
    @schedule[:thursday] = ""
    @schedule[:friday] = ""
    @schedule[:saturday] = ""
    @user = User.find_by(:id => args[0])
    @weekday_setting = Hash.new()

    if @user.try(:users_setting).try(:facility_timing).present? && @user.try(:users_setting).try(:facility_timing).count > 0
      @user.users_setting.facility_timing.each do |timing_hash| # getting timing hash for each facility
        timing_hash.each do |from_hash_facility_id, hash_of_timing| # from_hash_facility_id is the facility id and hash_of_timing is the hash of timings
          hash_of_timing.each do |key, value| # key is the day value are the slots
            @time_facility = ""
            value.each do |next_k, next_v| # next_k are the slot no. next_v contains timings number
              @time_facility = @time_facility + next_v[:from]
              @time_facility = @time_facility + "&&&"
              @time_facility = @time_facility + next_v[:to]
              @time_facility = @time_facility + "$$$"
              @time_facility = @time_facility + from_hash_facility_id.to_s
              @time_facility = @time_facility + "%%%"
            end

            if key == "404684003"
              @schedule[:sunday] = @schedule[:sunday] + @time_facility
            end

            if key == "307145004"
              @schedule[:monday] = @schedule[:monday] + @time_facility
            end

            if key == "307147007"
              @schedule[:tuesday] = @schedule[:tuesday] + @time_facility
            end

            if key == "307148002"
              @schedule[:wednesday] = @schedule[:wednesday] + @time_facility
            end

            if key == "307149005"
              @schedule[:thursday] = @schedule[:thursday] + @time_facility
            end

            if key == "307150005"
              @schedule[:friday] = @schedule[:friday] + @time_facility
            end

            if key == "307151009"
              @schedule[:saturday] = @schedule[:saturday] + @time_facility
            end
          end
        end
      end

      @user.users_setting.update_attributes(:schedule => @schedule)
    end
  end
end
