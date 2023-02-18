class Analytics::CreateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    # puts *args
    # args[0] contains hash of extra details
    # args[1] contains current_user
    # args[2] contains current_facility
    # args[3] contains type of service

    # Analytics::CreateService.call(args[0],args[1],args[2],args[3]).call

    type = args[3]

    case type
    when "appointment"
      Analytics::Appointment::CreateService.call(args[0], args[1], args[2])

    # # create appointment category type records
    # Analytics::Appointment::CreateService.create_walkin_appointment_type_record(args[0])

    # # create appointment type records
    # Analytics::Appointment::CreateService.create_appointment_type_record(args[0])

    # # create appointment category type records
    # Analytics::Appointment::CreateService.create_appointment_category_type_record(args[0])

    when "patient"
      # create Patient type records
      Analytics::Patient::CreateService.create_patient_type_record(args[0]) # args[0] here is analytics_params hash

    when "patient_referral_type"
      # create Patient type records
      Analytics::Patient::CreateService.create_referral_type_record(args[0], args[2]) # args[0] here is hash of appointment_id, pat_referral_id and args[2] is facility_id

    when "admission"
      Analytics::Admission::CreateService.call(args[0], args[1], args[2], args[3])

    when "admitted"
      Analytics::Admission::CreateService.call(args[0], args[1], args[2], args[3])

    when "not_admitted"
      Analytics::Admission::CreateService.call(args[0], args[1], args[2], args[3])

    when "ot"
      Analytics::Ot::CreateService.call(args[0], args[1], args[2])

    when "clinical_data"
      Analytics::ClinicalData::CreateUpdateService.call(args[0], args[1], args[2])

    when "patients_history"
      Analytics::PatientsHistory::CreateService.call(args[0])

    when "feedback"
      Analytics::PatientsFeedback::CreateFeedback.call(args[0], args[2])
    when "patient_outcome_ophthal"
      Analytics::PatientOutcomes::CreateService.call(args[0])
    else
    end
  end
end
