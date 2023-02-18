class PatientManagementMailer < ActionMailer::Base
  default from: Global.send('default_email_address').try('email_address')
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.patient_management_mailer.birthday_notification.subject
  #
  def birthday_notification(patient, organisation_id)
    @organisation = Organisation.find_by(id: organisation_id)
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: organisation_id)
    @patient = patient
    subject_body = @organisation_setting.birthday_email_subject
    mail to: patient.email.to_s, subject: subject_body.to_s
  end

  def followup_notification(followup)
    @user_setting = followup.user.users_setting
    @doctor = User.find_by(id: followup.doctor)
    @followup = followup
    subject_body = @user_setting.followup_email_subject
                                .gsub('%organisation_name%', @doctor.organisation.name.capitalize)
    mail to: followup.patient.email, subject: subject_body
  end

  def followup_long_overdue_notification(patient_overdue)
    @user_setting = patient_overdue.user.users_setting
    @doctor = User.find_by(id: patient_overdue.doctor)
    @patient_overdue = patient_overdue
    mail to: patient_overdue.patient.email, subject: @user_setting.long_overdue_email_subject
  end

  def appointment_cancellation_notification(appointment)
    @appointment = appointment
    @user_setting = appointment.user.users_setting
    patient = appointment.patient
    mail to: patient.email, subject: 'Appointment Cancelled'
  end

  def rescheduled_appointment_notification(appointment)
    @appointment = appointment
    @user_setting = appointment.user.users_setting
    patient = appointment.patient
    mail to: patient.email, subject: 'Appointment Rescheduled'
  end

  def appointment_reminder_notification(appointment)
    @appointment = appointment
    @user_setting = appointment.user.users_setting
    patient = appointment.patient_id
    mail to: patient.email, subject: @user_setting.appointment_email_subject
  end

  def appointment_confirmation_notification(appointment)
    @appointment = appointment
    @user_setting = appointment.user.users_setting
    patient = appointment.patient
    mail to: patient.email, subject: "Appointment Confirmed on #{appointment.appointmentdate}"
  end
end
