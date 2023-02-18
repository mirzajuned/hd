# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/ClassLength
module Mis::RevenueReports
  class ManageRevenueService
    class << self
      def call(invoice_id, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        invoice = Invoice.find_by(id: invoice_id)
        department_id = invoice.try(:department_id)

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
        is_deleted = invoice.try(:is_deleted)
        # receipt_display_fields
        invoice_status = invoice.try(:payment_pending).to_f > invoice.try(:total).to_f ? 'Pending' : 'Paid'
        invoice_type = invoice.try(:_type)
        payment_received_brkups = invoice.payment_received_breakups
        if invoice_type.in?(['Invoice::Opd', 'Invoice::Ipd'])
          currency = payment_received_brkups.pluck(:currency_symbol).uniq.last
          currency_id = payment_received_brkups.pluck(:currency_id).uniq.last
        else
          currency = invoice.try(:currency_symbol)
          currency_id = invoice.try(:currency_id)
        end
        customer_comments = invoice.try(:patient_comment)
        internal_comments = invoice.try(:comments)
        state = invoice.try(:state)
        mode_of_payment = begin
                            invoice.try(:mode_of_payment) || payment_received_brkups.pluck(
                              :mode_of_payment
                            ).uniq.join(',')
                          rescue StandardError
                            nil
                          end
        bill_no = invoice.try(:bill_number)
        # bill_no = invoice.try(:bkp_bill_number)
        tax = begin
                invoice.tax_breakup.map { |h| h[:amount].to_f }.sum.round(2)
              rescue StandardError
                0.00
              end

        pending_from = invoice.payment_pending_breakups.pluck(:received_from).uniq
        has_received_from = (payment_received_brkups.count > 0)

        payment_received = invoice.try(:payment_received)
        gross_amount = invoice.try(:net_amount)
        advance_amount = invoice.try(:advance_payment)

        bill_type = invoice.try(:invoice_type)
        fresh_booking = home_delivery = false
        is_refunded = invoice.try(:is_refunded)
        if department_id.in?(['485396012', '486546481'])
          i_type = invoice_type&.to_s.split(':')[-1]&.underscore
          is_cancelled = invoice.try(:is_canceled)
        elsif department_id == '50121007'
          i_type = 'optical'
          fresh_booking = invoice.try(:fresh_booking)
          home_delivery = invoice.try(:home_delivery)
        elsif department_id == '284748001'
          i_type = 'pharmacy'
          fresh_booking = invoice.try(:fresh_booking)
          home_delivery = invoice.try(:home_delivery)
        end

        payment_pending = invoice.try(:payment_pending).to_f
        refund_against_cancel = invoice.try(:refund_against_cancel).to_f
        # invoice_refund_amount = invoice.try(:refund_amount).to_f
        invoice_refund_amount = amount_received = 0
        refund_history = []; has_refund_history = false;
        if department_id.in?(['50121007', '284748001'])
          all_refunds = Inventory::Transaction::Return.where(invoice_id: invoice.id)
          amount_received = invoice.payment_received_breakups.pluck(:amount_received).reject{|i| i.nil?}.inject(0, :+).to_f.round(2)
        else
          all_refunds = RefundPayment.where(invoice_id: invoice.id)
          invoice_refund_amount = invoice.try(:refund_amount).to_f
          amount_received = invoice.try(:amount_received).to_f.round(2)
        end
        refunds_count = all_refunds.count
        
        if refunds_count > 0
          has_refund_history = true
          all_refunds.each do |refund|
            if department_id.in?(['485396012', '486546481'])
              reason = refund.try(:reason)
              refund_amount = refund.try(:amount).to_f
              return_invoice_number = refund.refund_display_id
              status = refund.refund_state
              return_type = refund.type
              refund_date = refund.refund_date
              refund_time = refund.refund_time
              refund_patient_id = refund.patient.id
            elsif department_id.in?(['50121007', '284748001'])
              reason = refund.try(:note)
              refund_amount = refund.try(:return_amount).to_f
              return_invoice_number = refund.try(:return_bill_number)
              status = refund.try(:status)
              return_type = refund.return_type
              refund_date = refund.return_date
              refund_time = refund.return_time
              refund_patient_id = refund.patient_id
              is_refunded = refund.is_refunded
              is_cancelled = refund.is_canceled
            end
            refund_history << { 'reason': reason, 'amount': refund_amount, 
                            'mode_of_payment': refund.mode_of_payment, 'cash': refund.try(:cash), 
                            'card': refund.try(:card), 'card_number': refund.try(:card_number), 
                            'cheque_date': refund.try(:cheque_date), 
                            'cheque_note': refund.try(:cheque_note), 
                            'transfer_date': refund.try(:transfer_date), 
                            'transfer_note': refund.try(:transfer_note), 
                            'other_note': refund.try(:other_note), 
                            'refund_display_id': return_invoice_number,
                            'bill_number': refund.try(:bill_number), 
                            'advance_display_id': refund.try(:advance_display_id),
                            'type': refund.try(:type), 'department_id': refund.try(:department_id), 
                            'department_name': refund.try(:department_name), 'level': refund.try(:level), 
                            'refund_state': status, 'user_id': refund.user_id, 
                            'return_charges': refund.return_charges, 'refund_type': return_type,
                            'refund_payment_type': refund.try(:refund_payment_type), 
                            'store_id': refund.try(:store_id),
                            'is_canceled': refund.is_canceled, 'canceled_by': refund.try(:canceled_by), 
                            'canceled_by_id': refund.try(:canceled_by_id), 
                            'cancel_date': refund.try(:cancel_date),
                            'refunded_by': refund.try(:refunded_by), 'refunded_by_id': refund.try(:refunded_by_id),
                            'is_refunded': refund.is_refunded, 'refund_date': refund_date, 
                            'refund_time': refund_time, 'patient_id': refund_patient_id
                          }
          end
          if department_id.in?(['50121007', '284748001'])
            invoice_refund_amount = refund_history.pluck(:amount).map{|i|i.to_f}.sum
          end
        end
        cancelled_pending = still_pending = 0
        if is_cancelled.present? && is_cancelled == true && department_id.in?(['485396012', '486546481', '284748001'])
          still_pending = 0
          # cancelled_pending = refund_amount
          cancelled_pending = payment_pending
        else
          still_pending = payment_pending
          cancelled_pending = 0
        end

        invoice_hash = {
          'bill_no': bill_no, 'bill_date': receipt_created_at.to_date, 
          'bill_date_time': receipt_created_at, 'bill_type': bill_type, 
          'total': invoice.try(:total).to_f.round(2), 'tax': tax, 
          'additional_discount': invoice.additional_discount || 0,
          'services_discount': invoice.services_discount || 0, 
          'total_discount': invoice.total_discount || 0, 
          'additional_discount_comment': invoice.additional_discount_comment || 0,
          'round': invoice.try(:round).to_f.round(2), 'status': invoice_status, 
          'advance_payment': advance_amount.to_f.round(2), 
          'amount_remaining': invoice.try(:amount_remaining).to_f.round(2), 
          'payment_pending': payment_pending, 'still_pending': still_pending.to_f.round(2), 
          'cancelled_pending': cancelled_pending.to_f.round(2), 
          'payment_received': payment_received.to_f.round(2), 
          'comments': invoice.comments, 'mode_of_payment': mode_of_payment, 
          'no_of_servies': invoice.services.count, 'currency_id': currency_id, 
          'currency': currency, 'specialty_id': specialty_id, 'specialty_name': specialty_name, 
          'department_id': department_id, 'department_name': department_name, 
          'department_order': department_order, 'facility_name': facility_name, 
          'facility_timezone': facility_timezone, 'type': i_type, 
          'has_pending': (pending_from.count > 0), 
          'pending_received_from': pending_from, 'has_received': has_received_from, 
          'gross_amount': gross_amount.to_f.round(2), 
          'non_taxable_amount': invoice.try(:non_taxable_amount).to_f.round(2), 
          'amount_adjusted': invoice.try(:round).to_f.round(2), 
          'no_of_receipts': payment_received_brkups.count,
          'created_at': receipt_created_at, 'updated_at': invoice.updated_at, 
          'state': state, 'customer_comments': customer_comments, 
          'internal_comments': internal_comments, 
          'is_cancelled': is_cancelled, 'canceled_by_id': invoice.canceled_by_id, 
          'canceled_by': invoice.canceled_by, 'cancel_date': invoice.cancel_date, 
          'is_refunded': is_refunded, 'refund_reason': invoice.refund_reason, 
          'refunded_by': invoice.refunded_by, 'refunded_by_id': invoice.refunded_by_id, 
          'refund_date': invoice.refund_date, 'refund_time': invoice.refund_time, 
          'refund_amount': invoice_refund_amount, 'refund_against_cancel': refund_against_cancel,
          'amount_received': amount_received, 'fresh_booking': fresh_booking, 
          'home_delivery': home_delivery, 'offer_on_bill': invoice.try(:offer_on_bill),
          'offer_on_services': invoice.try(:offer_on_services), 'total_offer': invoice.try(:total_offer),
          'offer_manager_id': invoice.try(:offer_manager_id), 'offer_name': invoice.try(:offer_name),
          'offer_code': invoice.try(:offer_code), 'offer_percentage': invoice.try(:offer_percentage),
          'offer_applied_at': invoice.try(:offer_applied_at), 
          'offer_applied_at_name': invoice.try(:offer_applied_at_name),
          'offer_applied_by': invoice.try(:offer_applied_by),
          'offer_applied_by_name': invoice.try(:offer_applied_by_name),
          'offer_applied_date': invoice.try(:offer_applied_date),
          'offer_applied_datetime': invoice.try(:offer_applied_datetime),
          'total_of_all_discount': invoice.try(:total_of_all_discount)
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
        patient_hash = Mis::BuildCommonData::BuildDataService.patient_details(invoice.try(:patient).try(:id).to_s)

        if invoice.try(:payer_master_id).present?
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
          display_id = appointment.try(:display_id)
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
          display_id = admission.try(:display_id)
          appointment_admission_id = admission.id
          consultant_name = User.find_by(id: admission.doctor)&.fullname
          has_admission = true if admission.present?
        end

        display_id =
          if invoice_type == 'Invoice::Opd'
            appointment.try(:display_id)
          elsif invoice_type == 'Invoice::Ipd'
            admission.try(:display_id)
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
            'appointment_id': appointment.id, display_id: appointment.try(:display_id), 'appointment_registration_type': appointment_registration_type,
            'appointment_type_label': appointment_type_label, 'reason': reason, 'consultant_name': consultant_name
          }
        end

        if admission.present?
          admission_hash = {
            'admission_id': admission.id, 'display_id': admission.try(:display_id), 'consultant_name': consultant_name
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
        filter_fields_hash = { organisation_id: organisation_id, facility_id: facility_id, department_id: department_id, bill_type: bill_type, invoice_status: invoice_status, user_id: user_id, currency_id: currency_id }
        # EOF filter_fields

        # search_fields
        search_fields_hash = { patient_name: patient_hash[:patient_name], user_name: user_name }
        # EOF search_fields

        f_mis_revenue = Finance::ReportData.find_or_create_by(
          invoice_id: invoice.id.to_s, organisation_id: organisation_id, facility_id: facility_id
        )
        
        f_mis_revenue.is_advance = false
        f_mis_revenue.is_cancelled = is_cancelled
        f_mis_revenue.is_refunded = is_refunded
        f_mis_revenue.refunds_count = refunds_count
        f_mis_revenue.has_refund_history = has_refund_history
        f_mis_revenue.refund_history = refund_history
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
        f_mis_revenue.sequences = invoice.sequences.map(&:attributes)
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
