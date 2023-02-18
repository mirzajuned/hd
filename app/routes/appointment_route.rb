class AppointmentRoute
  def self.matches?(request)
    appointment_day = request.params[:appointmentday]
    appointment_day.eql?('today') || appointment_day.eql?(Date.parse(appointment_day, '%d-%b-%Y').strftime('%d-%b-%Y'))
  end
end
