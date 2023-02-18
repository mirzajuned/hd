class Analytics::UpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    puts *args
    # args[0] contains id of corresponding table
    # args[1] contains current_user
    # args[2] contains current_facility
    # args[3] contains type of service

    # Analytics::CreateService.call(args[0],args[1],args[2],args[3]).call

    type = args[3]

    case type

    when "appointment"
      Analytics::Appointment::UpdateService.call(args[0], args[1], args[2])

      # when "walkin_appointment_type"
      #   Analytics::Appointment::UpdateService.call(args[0], args[1] , args[2])

    when "patient"
      # create Patient type records
      Analytics::Patient::UpdateService.update_patient_type_record(args[0]) # args[0] here is analytics_params hash

    when "patient_referral_type"
      # create Patient referral records
      Analytics::Patient::UpdateService.update_referral_type_record(args[0], args[2]) # args[0] here is hash of analytics_params and args[2] is facility_id

    when "admission"
      Analytics::Admission::UpdateService.call(args[0], args[1], args[2])

    when "ot"
      Analytics::Ot::UpdateService.call(args[0], args[1], args[2])

    when "patients_history"
      Analytics::PatientsHistory::UpdateService.call(args[0])
    when "patient_outcome_ophthal"
      Analytics::PatientOutcomes::UpdateService.call(args[0])
    else

    end
  end
end
