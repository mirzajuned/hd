class UserTimeSlots::EventsDataService
  attr_accessor :events, :start_date, :end_date, :date_range, :user_id, :facility_id, :department_id,
                :user_time_slot, :sessions, :exception_sessions, :booked_events

  def initialize(params)
    @events = []


    if ['emergency', 'same_day'].include?(params[:admission_type])
      @start_date = Date.current
      @end_date = @start_date.end_of_day
    else
      @start_date = Date.parse(params[:start])
      @end_date = Date.parse(params[:end]) - 1.days # As the response date is a day ahead
    end
    @date_range = start_date..end_date

    @user_id = params[:user_id]
    @facility_id = params[:facility_id]
    @department_id = params[:department_id]

    @user_time_slot = UserTimeSlot.find_by('$or': [{ id: params[:id] }, { user_id: params[:user_id] }])
    @holiday_plans = HolidayPlan.where(user_id: user_id, start_date: start_date..end_date).or(user_id: user_id, end_date: start_date..end_date).order('start_time Asc').to_a
    
    return unless @user_time_slot

    @sessions = find_sessions
    @exception_sessions = find_exception_sessions

    @booked_events = find_booked_events
  end

  def start
    return if end_date < Date.today || user_time_slot.nil?

    # Create Events
    date_range.to_a.each do |date|
      fes = filter_exception_session(date)
      if fes.present?
        # If exception is present but not for current facility and department. Skip that date.
        # The idea here is to not create the normal session as well.
        next if fes.facility_id.to_s != facility_id || fes.department_id != department_id

        session_loop(date, fes)
      else
        filtered_session = filter_sessions(date)
        next if filtered_session.empty?

        filtered_session.each do |session|
          session_loop(date, session)
        end
      end
    end
    put_holiday_events if @holiday_plans.present?
    events
  end

  private

  def find_sessions
    user_time_slot.sessions.where(facility_id: facility_id, department_id: department_id).to_a
  end

  def find_exception_sessions
    user_time_slot.exception_sessions.where(
      '$or' => [
        { start_date: date_range },
        { end_date: date_range },
        { :start_date.lt => start_date, :end_date.gt => end_date }
      ]
    ).to_a
  end

  def filter_sessions(date)
    sessions.select { |s| s.days.include?(date.strftime('%A')) }
  end

  def filter_exception_session(date)
    exception_sessions.find { |es| date.between?(es.start_date, es.end_date) && es.days.include?(date.strftime('%A')) }
  end

  def find_booked_events
    department_id == '485396012' ? appointments : admissions
  end

  def appointments
    AppointmentListView.where(facility_id: facility_id, appointment_date: date_range, appointmenttype: 'appointment',
                              consulting_doctor_id: user_id, :current_state.ne => 'Deleted').to_a
  end

  def admissions
    AdmissionListView.where(facility_id: facility_id, admission_date: date_range,
                            admitting_doctor_id: user_id, :current_state.ne => 'Deleted').to_a
  end

  def session_loop(date, session)
    time_duration = session.time_duration.to_i.minutes

    start_time = Time.zone.parse(date.strftime('%d/%m/%Y ') + military_time(session.start_time))
    loop_time = start_time + time_duration
    end_time = Time.zone.parse(date.strftime('%d/%m/%Y ') + military_time(session.end_time))

    while loop_time <= end_time
      if !@holiday_plans.present? #&& true
        events << new_event(start_time, loop_time, session.max_bookings)
      else
        # reference |||||||||| -> Green Slot    ||||-||||-||||-|||| A chain of green slots
        # search for holiday Plan which are completely overlapping my green slot    |||||-(      PLAN      )-||||| - a chain of green slots
        if @holiday_plans.filter{ |plan| plan.start_time <= start_time && plan.end_time >= loop_time}.count > 0
        # search for plan that has both start and end in b/w the green slot   ||||||PLAN|||||| - 1 slot
        elsif @holiday_plans.filter{ |plan| plan.start_time > start_time && plan.end_time < loop_time}.count > 0
          # here comes a complication that when two breaks are inside one slots then we have to calculat for that as well hence we use for each   ||(PLAN)|||||(PLAN)||||| -> one green slot
          plan_list = @holiday_plans.filter{ |plan| plan.start_time > start_time && plan.end_time < loop_time}
          if plan_list.count == 1
            events << new_event(start_time, plan_list[0][:start_time],( (plan_list[0][:start_time] - start_time)/60).abs.to_i/session.slot_duration )
            events << new_event(plan_list[0][:end_time], loop_time,( (loop_time - plan_list[0][:end_time])/60).abs.to_i/session.slot_duration )
          else
            plan_list.each_with_index do |plan, i|
              if  i == 0 
                events << new_event(start_time, plan_list[i][:start_time],( (plan_list[i][:start_time] - start_time)/60).abs.to_i/session.slot_duration )
                if plan_list.length == 2 # if there are 2 holidays then we create in b/w slot (an exception cases)
                  events << new_event(plan_list[0][:end_time], plan_list[1][:start_time],( (plan_list[0][:end_time] - plan_list[1][:start_time])/60).abs.to_i/session.slot_duration )
                end
              elsif i == (plan_list.length - 1)
                events << new_event(plan_list[i][:end_time], loop_time,( (loop_time - plan_list[i][:end_time])/60).abs.to_i/session.slot_duration )
              else
                events << new_event(plan_list[i-1][:end_time], plan_list[i][:start_time],( (plan_list[i][:start_time] - plan_list[i-1][:end_time])/60).abs.to_i/session.slot_duration )
                events << new_event(plan_list[i][:end_time], plan_list[i+1][:start_time],( (plan_list[i+1][:start_time] - plan_list[i][:end_time])/60).abs.to_i/session.slot_duration )
              end
            end 
          end
        # now we search fo slots that have  holdayplan.start_time inside them |||(          PLAN                      )||| -> inside a chain of green slots
        elsif @holiday_plans.filter{ |plan| plan.start_time.between?(start_time, loop_time) && loop_time <= plan.end_time }.count > 0
          plan_list = @holiday_plans.filter{ |plan| plan.start_time.between?(start_time, loop_time) && loop_time <= plan.end_time }
          events << new_event(start_time, plan_list[0][:start_time],( (plan_list[0][:start_time] - start_time)/60).abs.to_i/session.slot_duration )
        # now we search for those slots which have holiday_plan.end_time inside them ||||-||||-(        PLAN           )||-||| -> inside a chain of green slots
        elsif @holiday_plans.filter{ |plan| plan.end_time.between?(start_time, loop_time) && start_time >= plan.start_time }.count > 0
          plan_list = @holiday_plans.filter{ |plan| plan.end_time.between?(start_time, loop_time) && start_time >= plan.start_time }
          events << new_event(plan_list[0][:end_time], loop_time,( (loop_time - plan_list[0][:end_time])/60).abs.to_i/session.slot_duration )
        else
        events << new_event(start_time, loop_time, session.max_bookings)

        end

      end
      start_time += time_duration
      loop_time += time_duration
    end
  end

  def new_event(start_time, loop_time, max_bookings)
    bec = booked_events_count(start_time, loop_time)
    color = find_color(start_time, bec, max_bookings)

    {
      title: "#{bec} #{department_id == '485396012' ? 'Appointments' : 'Admissions'}",
      start: "#{start_time.try(:strftime, '%F')}T#{start_time.try(:strftime, '%H:%M:%S.%L%:z')}",
      end: "#{loop_time.try(:strftime, '%F')}T#{loop_time.try(:strftime, '%H:%M:%S.%L%:z')}",
      borderColor: '#fff',
      backgroundColor: color,
      textColor: '#fff',
      full: color == '#dc3545'
    }
  end

  def find_color(start_time, bec, max_bookings)
    if (start_time < Time.current) && (bec == 0)
      '#c1c1c1'
    elsif bec == 0
      # Empty
      '#28a745'
    elsif bec < max_bookings
      # Semi Filled
      '#ff8735'
    else
      # Full
      '#dc3545'
    end
  end

  def booked_events_count(start_time, loop_time)
    booked_events.count do |a|
      if department_id == '485396012'
        a.appointment_start_time.in_time_zone(Time.zone).between?(start_time, loop_time - 1.second)
      else
        a.admission_time.in_time_zone(Time.zone).between?(start_time, loop_time - 1.second)
      end
    end
  end

  def military_time(time)
    Time.strptime(time, '%I:%M %P').strftime('%H:%M')
  end

  def put_holiday_events
    @holiday_plans.each do |plan|
      events << {:title=>plan.plan, :start => plan.start_time, :end=> plan.end_time, :borderColor=>"#D09CFA", :backgroundColor=>"#D09CFA", :textColor=>"#000000", :full=>false, :className=>"holiday_slot"}
    end
  end

end