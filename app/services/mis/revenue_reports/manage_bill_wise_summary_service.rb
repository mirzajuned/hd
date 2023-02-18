# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/ClassLength
module Mis::RevenueReports
  class ManageBillWiseSummaryService
    class << self
      def call(invoice_id, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        invoice = Invoice.find_by(id: invoice_id)
        department_id = invoice.try(:department_id)
        mis_logger.info(" @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ invoice id: #{invoice_id}")
        mis_logger.info(" @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ department_id: #{department_id}")
        return unless invoice.present? || department_id.present?
        
        organisation_id = invoice.organisation_id.to_s
        facility_id = invoice.facility_id.to_s
        facilty = Facility.find_by(id: facility_id)
        facility_name = facilty.try(:name)
        facility_timezone = facilty.try(:time_zone)
        specialty_id = invoice.specialty_id
        specialty_name = Specialty.find_by(id: specialty_id).try(:name)
        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        receipt_created_at = invoice.created_at
        # receipt_display_fields
        invoice_status = invoice.payment_pending <= invoice.total ? 'Pending' : 'Paid'
        invoice_type = invoice._type
        is_deleted = invoice.try(:is_deleted)
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
        is_cancelled = invoice.is_canceled
        is_refunded = invoice.is_refunded
        invoice_hash = {
          'bill_no': bill_no, 'bill_date': receipt_created_at.to_date, 'bill_date_time': receipt_created_at, 'bill_type': bill_type,
          'total': invoice.try(:total).round(2), 'tax': tax, 'additional_discount': invoice.additional_discount || 0,
          'services_discount': invoice.services_discount || 0, 'total_discount': invoice.total_discount || 0,
          'additional_discount_comment': invoice.additional_discount_comment || 0,
          'round': invoice.try(:round).round(2), 'status': invoice_status, 'advance_payment': advance_amount.round(2),
          'amount_remaining': invoice.try(:amount_remaining).round(2), 'payment_pending': invoice.try(:payment_pending).round(2),
          'payment_received': payment_received.round(2), 'comments': invoice.comments, 'mode_of_payment': mode_of_payment,
          'no_of_servies': invoice.services.count, 'currency_id': currency_id, 'currency': currency,
          'specialty_id': specialty_id, 'specialty_name': specialty_name, 'department_id': department_id, 
          'department_name': department_name, 'department_order': department_order,
          'facility_name': facility_name, 'facility_timezone': facility_timezone, 'type': i_type,
          'has_pending': (pending_from.count > 0), 'pending_received_from': pending_from, 'has_received': has_received_from,
          'gross_amount': gross_amount.round(2), 'non_taxable_amount': invoice.try(:non_taxable_amount).round(2),
          'amount_adjusted': invoice.try(:round).round(2), 'no_of_receipts': payment_received_brkups.count,
          'created_at': receipt_created_at, 'updated_at': invoice.updated_at, 'state': state,
          'customer_comments': customer_comments, 'internal_comments': internal_comments,
          'is_cancelled': is_cancelled, 'canceled_by_id': invoice.canceled_by_id, 'canceled_by': invoice.canceled_by,
          'cancel_date': invoice.cancel_date, 'is_refunded': invoice.is_refunded, 'refund_reason': invoice.refund_reason,
          'refunded_by': invoice.refunded_by, 'refunded_by_id': invoice.refunded_by_id, 'refund_date': invoice.refund_date,
          'refund_time': invoice.refund_time, 'refund_amount': invoice.try(:refund_amount).round(2)
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
              invoice_type: invoice_log.invoice_type, receipt_date: invoice_log.invoice_date,
              old_total: invoice_log.old_total, new_total: invoice_log.new_total,
              user_id: invoice_log.user_id.to_s, updated_at: invoice_log.updated_at,
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
        user_id = user.try(:id).to_s
        user_name = user.try(:fullname)
        user_hash = { 'id': user_id, 'name': user_name, 'designation': user.try(:designation) }
        # EOF user_display_fields

        # common_display_fields
        appointment = invoice.appointment
        admission = invoice.admission

        appointment_type = reason = ''; appointment_admission_id = nil
        display_id = bill_no; consultant_name = nil
        has_appointment = has_admission = false

        if invoice_type == 'Invoice::Opd'
          display_id = appointment.display_id
          appointment_admission_id = appointment.id
          clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
          if clinical_workflow.present?
            users = User.where(facility_ids: facility_id, is_active: true).order('fullname ASC')
            consultant_name = users.find_by(id: clinical_workflow.doctor_ids.last).try(:fullname)
          else
            appointment_list_view = AppointmentListView.find_by(appointment_id: appointment.id)
            consultant_name = appointment_list_view.try(:consulting_doctor)
          end
          has_appointment = true if appointment.present?
        elsif invoice_type == 'Invoice::Ipd'
          display_id = admission.display_id
          appointment_admission_id = admission.id
          consultant_name = User.find_by(id: admission.doctor)&.fullname
          has_admission = true if admission.present?
        end

        display_id =
          if invoice_type == 'Invoice::Opd'
            appointment.display_id
          elsif invoice_type == 'Invoice::Ipd'
            admission.display_id
          else
            bill_no
          end

        appointment_hash = admission_hash = nil

        if appointment.present?
          appointment_registration_type = appointment.try(:appointmenttype)
          appointment_type_id = appointment.try(:appointment_type_id)
          appointment_type_label = AppointmentType.find_by(id: appointment_type_id).try(:label).to_s
          reason = appointment.try(:reason)
          appointment_hash = {
            'appointment_id': appointment.id, display_id: appointment.display_id, 'appointment_registration_type': appointment_registration_type,
            'appointment_type_label': appointment_type_label, 'reason': reason, 'consultant_name': consultant_name
          }
        end

        if admission.present?
          admission_hash = {
            'admission_id': admission.id, 'display_id': admission.display_id, 'consultant_name': consultant_name
          }
        end

        common_hash = {
          'display_id': display_id, 'appointment_registration_type': appointment_registration_type,
          'appointment_type_label': appointment_type_label, 'reason': reason,
          'has_appointment': has_appointment, 'has_admission': has_admission,
          'consultant_name': consultant_name
        }
        # EOF common_display_fields

        # filter_fields
        filter_fields_hash = { organisation_id: organisation_id, facility_id: facility_id, department_id: department_id,
                               bill_type: bill_type, invoice_status: invoice_status, user_id: user_id, currency_id: currency_id }
        # EOF filter_fields

        # search_fields
        search_fields_hash = { patient_name: patient_name, user_name: user_name }
        # EOF search_fields

        f_mis_revenue = Finance::ReportData.find_or_create_by(
          invoice_id: invoice.id.to_s, organisation_id: organisation_id, facility_id: facility_id
        )
        
        f_mis_revenue.is_advance = false
        f_mis_revenue.is_cancelled = is_cancelled
        f_mis_revenue.is_refunded = is_refunded
        f_mis_revenue.receipt_created_at = receipt_created_at
        f_mis_revenue.receipt_updated_at = invoice.updated_at
        f_mis_revenue.patient_display_fields = patient_hash
        f_mis_revenue.payer_display_fields = payer_hash
        f_mis_revenue.receipt_display_fields = invoice_hash
        f_mis_revenue.user_display_fields = user_hash
        f_mis_revenue.common_display_fields = common_hash
        f_mis_revenue.filter_fields = filter_fields_hash
        f_mis_revenue.search_fields = search_fields_hash

        f_mis_revenue.appointment_display_fields = appointment_hash
        f_mis_revenue.admission_display_fields = admission_hash

        f_mis_revenue.has_logs = has_logs
        f_mis_revenue.receipt_logs = receipt_logs

        f_mis_revenue.services = invoice.services.map(&:attributes)
        f_mis_revenue.advance_payment_breakups = invoice.advance_payment_breakups.map(&:attributes)
        f_mis_revenue.payment_received_breakups = invoice.payment_received_breakups.map(&:attributes)
        f_mis_revenue.payment_pending_breakups = invoice.payment_pending_breakups.map(&:attributes)
        f_mis_revenue.is_deleted = is_deleted
        f_mis_revenue.save!
        mis_logger.info(" @@@@@@@@@@@@@@ EOF #{invoice_id} with report id: #{f_mis_revenue.id}")
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManageRevenueService :: #{e.inspect}")
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
