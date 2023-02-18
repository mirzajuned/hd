class AppointmentGcmJob < ActiveJob::Base
  queue_as :delayed
  def perform(*args)
    appointment = Appointment.find_by(id: args[0])
    entity = args[1].nil? ? "" : args[1]
    action = args[2].nil? ? "" : args[2]
    organisation_id = args[3].nil? ? "" : args[3]
    options_params = define_appointment_params({ :appointment => appointment, :entity => entity, :action => action })
    GoogleCloudMessaging.send_message(options_params, organisation_id)
  end

  private

  def define_appointment_params(params = {})
    appointment_params = {}
    appointment_params[:entity] = params[:entity]
    appointment_params[:action] = params[:action]
    appointment_params[:appointment_id] = params[:appointment].id.to_s
    appointment_params[:doctor] = params[:appointment].consultant_id
    appointment_params[:appointment_date] = params[:appointment].appointmentdate
    appointment_params[:start_time] = params[:appointment].start_time
    appointment_params[:end_time] = params[:appointment].end_time
    appointment_params[:display_id] = params[:appointment].display_id
    appointment_params[:patient_id] = params[:appointment].patient_id
    appointment_params[:patient_name] = params[:appointment].patient.fullname
    appointment_params[:appointmentstatus] = params[:appointment].appointmentstatus
    appointment_params[:department_id] = params[:appointment].department_id
    appointment_params[:facility_id] = params[:appointment].facility_id
    appointment_params[:user_id] = params[:appointment].user_id
    ### ADD MORE IF NECESSARY
    return appointment_params
  end
end
