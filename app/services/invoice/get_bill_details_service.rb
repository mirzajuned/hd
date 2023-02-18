class Invoice::GetBillDetailsService
  class << self
    def call(invoice_id, mis_logger=nil)
      mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
      invoice = Invoice.find_by(id: invoice_id)
      mis_logger.info(" @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ invoice id: #{invoice.id}")
      mis_logger.info(" @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ department_id: #{invoice.department_id}")
      return unless invoice.department_id.present?

      organisation_id = invoice.organisation_id.to_s
      facility_id = invoice.facility_id.to_s
      facilty = Facility.find_by(id: facility_id)
      facility_name = facilty.try(:name)
      facility_timezone = facilty.try(:time_zone)
      specialty_id = invoice.specialty_id
      specialty_name = Specialty.find_by(id: specialty_id).try(:name)
      department_id = invoice.department_id
      department = Department.find_by(id: department_id)
      department_name = department.try(:display_name)
      department_order = department.try(:order)
      receipt_created_at = invoice.created_at

      invoice_status = invoice.payment_pending <= invoice.total ? 'Pending' : 'Paid'
      invoice_type = invoice._type
      payment_received_brkups = invoice.payment_received_breakups
      if invoice_type.in?(['Invoice::Opd', 'Invoice::Ipd'])
        currency = payment_received_brkups.pluck(:currency_symbol).uniq.last
        currency_id = payment_received_brkups.pluck(:currency_id).uniq.last
      else
        currency = invoice.currency_symbol
        currency_id = invoice.currency_id
      end
      customer_comments = invoice.patient_comment
      internal_comments = invoice.comments
      state = invoice.try(:state)
      mode_of_payment = begin
                          invoice.mode_of_payment || payment_received_brkups.pluck(
                            :mode_of_payment
                          ).uniq.join(',')
                        rescue StandardError
                          nil
                        end
      bill_no = invoice.bill_number
      tax = begin
              invoice.tax_breakup.map { |h| h[:amount].to_f }.sum
            rescue StandardError
              0.00
            end

      pending_from = invoice.payment_pending_breakups.pluck(:received_from).uniq
      has_received_from = (payment_received_brkups.count > 0)

      payment_received = invoice.payment_received
      gross_amount = invoice.net_amount
      advance_amount = invoice.advance_payment
      if department_id == '50121007'
        if payment_received == gross_amount
          advance_amount = 0.0
        else
          payment_received = 0.0
        end
      end

      bill_type = invoice.invoice_type
      i_type = invoice_type.to_s.split(':')[-1].underscore
      invoice_hash = {
        'bill_no': bill_no, 'bill_date': receipt_created_at, 'bill_type': bill_type,
        'total': invoice.total, 'tax': tax, 'discount': invoice.discount || 0, 'round': invoice.round,
        'status': invoice_status, 'advance_payment': advance_amount,
        'amount_remaining': invoice.amount_remaining, 'payment_pending': invoice.payment_pending,
        'payment_received': payment_received,
        'comments': invoice.comments, 'mode_of_payment': mode_of_payment,
        'no_of_servies': invoice.services.count, 'currency_id': currency_id, 'currency': currency,
        'specialty_id': specialty_id, 'specialty_name': specialty_name,
        'department_id': department_id, 'department_name': department_name, 'department_order': department_order,
        'facility_name': facility_name, 'facility_timezone': facility_timezone, 'type': i_type,
        'has_pending': (pending_from.count > 0), 'pending_received_from': pending_from, 'has_received': has_received_from,
        'gross_amount': gross_amount, 'non_taxable_amount': invoice.non_taxable_amount,
        'amount_adjusted': invoice.round, 'no_of_receipts': payment_received_brkups.count,
        'created_at': receipt_created_at, 'updated_at': invoice.updated_at, 'state': state,
        'customer_comments': customer_comments, 'internal_comments': internal_comments,
        'is_cancelled': invoice.is_canceled, 'canceled_by_id': invoice.canceled_by_id, 'canceled_by': invoice.canceled_by,
        'cancel_date': invoice.cancel_date, 'is_refunded': invoice.is_refunded, 'refund_reason': invoice.refund_reason,
        'refunded_by': invoice.refunded_by, 'refunded_by_id': invoice.refunded_by_id, 'refund_date': invoice.refund_date,
        'refund_time': invoice.refund_time, 'refund_amount': invoice.refund_amount
      }

      # Last modified invoice comments
      receipt_logs = []
      has_logs = false
      invoicelogs = InvoiceLog.where(invoice_id: invoice.id.to_s)
      if invoicelogs.count > 0
        has_logs = true
        invoicelogs.each do |invoice_log|
          receipt_logs << {
            log_id: invoice_log.id.to_s, invoice_id: invoice_log.invoice_id.to_s, username: invoice_log.username,
            comment: invoice_log.comment, bill_number: invoice_log.bill_number, created_at: invoice_log.created_at, 
            invoice_type: invoice_log.invoice_type, receipt_date: invoice_log.invoice_date, old_total: invoice_log.old_total, 
            new_total: invoice_log.new_total, user_id: invoice_log.user_id.to_s, updated_at: invoice_log.updated_at,
            organisation_id: invoice_log.organisation_id.to_s, facility_id: invoice_log.facility_id.to_s
          }
        end
      end
      # EOF Last modified invoice comments

      # patient_payer_display_fields
      patient = invoice.patient
      patient_id = patient.id.to_s
      patient_name = patient.fullname
      age = (patient.age.present? && patient.age > 0) ? patient.age : patient.exact_age
      patient_hash = {
        'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 'gender': patient.gender,
        'patient_identifier_id': patient.patient_identifier_id, 'patient_mrn': patient.patient_mrn
      }

      if invoice.payer_master_id.present?
        payer = PayerMaster.find_by(id: invoice.payer_master_id)
        payer_hash = { 'payer_id': payer.id.to_s, 'payer_name': payer.display_name }
      end
      # EOF patient_payer_display_fields

      # user_display_fields
      user = invoice.user
      user_id = user.id.to_s
      user_name = user.fullname
      user_hash = { 'id': user_id, 'name': user_name, 'designation': user.designation }
      # EOF user_display_fields

      # common_display_fields
      appointment = invoice.appointment
      admission = invoice.admission

      appointment_type = reason = ''
      display_id =
        if invoice_type == 'Invoice::Opd'
          appointment.display_id
        elsif invoice_type == 'Invoice::Ipd'
          admission.display_id
        else
          bill_no
        end

      if invoice_type == 'Invoice::Opd'
        appointment_registration_type = appointment.try(:appointmenttype)
        appointment_type_id = appointment.try(:appointment_type_id)
        appointment_type_label = AppointmentType.find_by(id: appointment_type_id).try(:label).to_s
        reason = appointment.reason
      end

      common_hash = {
        'display_id': display_id, 'appointment_registration_type': appointment_registration_type,
        'appointment_type_label': appointment_type_label, 'reason': reason
      }
      # EOF common_display_fields
    end
  end
end