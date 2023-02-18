class Reports::Opd::Appointments
  def initialize(appointment)
    @appointment = appointment
  end

  def call
    set_appointment_count
    find_daily_report
    if @daily_report.blank?
      DailyReport.create(create_params)
    else
      @daily_report.update_attributes(update_params)
    end
  end

  private

  def set_appointment_count
    @appointment_count = Appointment.where(:appointmentdate => @appointment.appointmentdate, facility_id: @appointment.facility_id, :appointmentstatus => 416774000).size
  end

  def find_daily_report
    @daily_report = DailyReport.find_by(date: Date.current, facility_id: @appointment.facility_id, specialty_id: @appointment.specialty_id)
  end

  def update_params
    {
      appointment_count: @appointment_count,
      facility_id: @appointment.facility_id
    }
  end

  def create_params
    {
      date: @appointment.appointmentdate,
      appointment_count: @appointment_count,
      month: @appointment.appointmentdate.month,
      year: @appointment.appointmentdate.year,
      organisation_id: @appointment.user.organisation_id.to_s,
      facility_id: @appointment.facility_id.to_s,
      specialty_id: @appointment.specialty_id.to_s
    }
  end

  # Logic to calculate New Old Patient , not required for now

  # def calculte_new_old_patients
  #   opd_patient_ids = Appointment.where(appointmentdate: Date.current,facility_id: current_facility.id).pluck(:patient_id)
  #   opd_new_patient_count = 0
  #   opd_old_patient_count = 0
  #   opd_patient_ids.each do |pat_id|
  #     pat=Patient.find_by(id: pat_id)
  #     unless Appointment.where(patient_id: pat_id).count > 1
  #       opd_new_patient_count = opd_new_patient_count+1
  #     else
  #       opd_old_patient_count = opd_old_patient_count+1
  #     end
  #   end
  # end
end
