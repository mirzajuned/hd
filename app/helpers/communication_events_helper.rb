module CommunicationEventsHelper
  def get_features_type(params, communication_event)
    if params[:module_type] == '0' || communication_event.try(:module_name) == 'opd'
      [
        ['Appointment Scheduled', 'appointment_scheduled'],
        ['Appointment Cancellation', 'appointment_cancellation'],
        ['Reschedule Appointment', 'reschedule_appointment'],
        ['Walk-In/Patient Arrived', 'patient_arrived'],
        ['Mark As Completed', 'mark_as_completed'],
        ['Missed Appointment', 'missed_appointment'],
        ['Follow Up Appointment', 'follow_up_appointment']
      ]
    elsif params[:module_type] == '1' || communication_event.try(:module_name) == 'ipd'
      [
        ['Same Day /Emergency Admission schedule', 'same_day_or_emergency'],
        ['Planned Admission', 'planned_admission'],
        ['Admission Rescheduled', 'admission_rescheduled'],
        ['Admission Cancelled', 'admission_cancelled'],
        ['Discharge Message', 'discharge_message']
      ]
    elsif params[:module_type] == '2' || communication_event.try(:module_name) == 'optical'
      [
        ['Glass Prescription Advised Patient', 'optical_glass_prescription_advised_patient'],
        ['Glass Prescription Advised Store', 'optical_glass_prescription_advised_store'],
        ['Optical Order Placed', 'optical_order_placed'],
        ['Fitting', 'optical_fitting'],
        ['Ready', 'optical_ready'],
        ['Delivered', 'optical_delivered'],
        ['Cancelled', 'optical_order_cancelled'],
        ['Optical Return', 'optical_return'],
        ['Bill Cancelled', 'optical_bill_cancelled'],
        ['Bill Creation', 'optical_bill_creation']
      ]
    elsif params[:module_type] == '3' || communication_event.try(:module_name) == 'pharmacy'
      [
        ['Medication Prescriptin Advised (Patient)', 'pharmacy_patient'],
        ['Medication Prescriptin Advised (Store)', 'pharmacy_store'],
        # ['Sales Invoice', 'pharmacy_sale_invoice'],
        ['Pharmacy Return', 'pharmacy_return'],
        ['Bill Cancelled', 'pharmacy_bill_cancel'],
        ['Bill Creation', 'pharmacy_bill_creation'],
        ['Pharmacy Order Placed', 'pharmacy_order_placed']

      ]
    end
  end

  def communication_event_module_type(params)
    CommunicationEvent.module_name.values[params[:module_type].to_i].upcase
  end
end
