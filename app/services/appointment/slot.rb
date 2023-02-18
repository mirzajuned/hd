class Appointment::Slot
  def initialize(appointment_date, facility_id, doctor_id)
    @slots = get_slots(appointment_date)

    @appointments = Appointment.includes(:patient).where(appointmentdate: Date.parse(appointment_date), consultant_id: doctor_id, facility_id: facility_id)
  end

  def get
    @appointments.each_with_index do |appointment, i|
      hour = appointment.start_time.strftime('%I')
      meridian = appointment.start_time.strftime('%p')
      time = appointment.start_time.try(:strftime, '%I:%M %p')
      if hour == '00' || hour == '12'
        slot = '12 - 01 ' + meridian
      else
        slot = hour + ' - ' + (hour.to_i + 1).to_s.rjust(2, '0') + ' ' + meridian
      end
      if @slots[slot]
        @slots[slot] << [time, appointment.patient.fullname]
      end
    end

    return @slots
  end

  def get_slots(appointment_date)
    if Date.parse(appointment_date) == Date.current
      @current_hour = Time.current.strftime('%I')
      @current_meridian = Time.current.strftime('%p')
    else
      @current_hour = "06"
      @current_meridian = "AM"
    end

    @slots = {}
    if @current_meridian == 'AM' and @current_hour != '12'
      for i in @current_hour.to_i..11
        key = i.to_s.rjust(2, '0') + ' - ' + (i.to_i + 1).to_s.rjust(2, '0') + ' ' + @current_meridian
        @slots[key] = []
      end
      @slots['12 - 01 PM'] = []
      for i in 1..11
        key = i.to_s.rjust(2, '0') + ' - ' + (i.to_i + 1).to_s.rjust(2, '0') + ' PM'
        @slots[key] = []
      end
    elsif @current_meridian == 'AM' and @current_hour == '12'
      @slots['12 - 01 PM'] = []
      for i in 1..11
        key = i.to_s.rjust(2, '0') + ' - ' + (i.to_i + 1).to_s.rjust(2, '0') + ' PM'
        @slots[key] = []
      end
    elsif @current_meridian == 'PM' and @current_hour == '12'
      @slots['12 - 01 AM'] = []
      for i in 1..11
        key = i.to_s.rjust(2, '0') + ' - ' + (i.to_i + 1).to_s.rjust(2, '0') + ' PM'
        @slots[key] = []
      end
    elsif @current_meridian == 'PM'
      for i in @current_hour.to_i..11
        key = i.to_s.rjust(2, '0') + ' - ' + (i.to_i + 1).to_s.rjust(2, '0') + ' ' + @current_meridian
        @slots[key] = []
      end
    end
    return @slots
  end
end
