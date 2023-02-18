module Patients
  module Summary
    module OpdAppointment
      APPOINTMENT_EDIT_LINK = ["edit_appointment_path", "btn btn-xs btn-primary btn-primary-transparent", "edit-appointment", true, "fa fa-edit", "Edit", "Edit Appointment", "E", "#appointment-modal"]
      APPOINTMENT_RESCHEDULE_LINK = ["opd_appointments_rescheduleappointment_path", "btn btn-xs btn-primary btn-primary-transparent", "reschedule-appointment", true, "fa fa-edit", "Reschedule", "Reschedule Appointment", "R", "#appointment-modal"]
      APPOINTMENT_CANCEL_LINK = ["opd_appointments_cancelappointmentform_path", "btn btn-xs btn-danger btn-danger-transparent", "cancel-appointment", true, "fa fa-trash-alt", "Cancel", "Cancel Appointment", "E", "#appointment-modal"]
    end
  end
end
