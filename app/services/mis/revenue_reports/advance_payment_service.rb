module Mis::RevenueReports
  class AdvancePaymentService
    class << self
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def call(advance_bill_id, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        invoice = AdvancePayment.find_by(id: advance_bill_id)
        if invoice.present?
          # mis_logger.info(" ======= advance invoice id: #{invoice.id}")
          organisation_id = invoice.organisation_id.to_s
          facility_id = invoice.facility_id.to_s
          facilty = Facility.find_by(id: facility_id)
          facility_name = facilty.try(:name)
          facility_timezone = facilty.try(:time_zone)

          department_id = invoice.department_id
          department = Department.find_by(id: department_id)
          department_name = department.try(:display_name)
          department_order = department.try(:order)
          advance_state = invoice.advance_state
          is_deleted = invoice.try(:is_deleted)

          user_id = invoice.user_id.to_s
          user = User.find_by(id: user_id)
          user_name = user.try(:fullname)

          patient = invoice.patient
          patient_id = patient.id.to_s
          patient_name = patient.try(:fullname)
          age = (patient.age.present? && patient.age > 0) ? patient.age : patient.exact_age
          commune = patient.try(:commune)
          district = patient.try(:district)
          state = patient.try(:state)
          pincode = patient.try(:pincode)
          city = patient.try(:city)
          location_id = patient&.location_id
          area_manager_id = patient&.area_manager_id
          area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
          is_cancelled = invoice.is_canceled
          is_refunded = invoice.is_refunded

          all_refunds = RefundPayment.where(advance_payment_id: invoice.id)
          refunds_count = all_refunds.count
          refund_history = []; has_refund_history = false

          if refunds_count > 0
            has_refund_history = true
            all_refunds.each do |refund|
              refund_history << { 'reason': refund.try(:reason), 'amount': refund.try(:amount).to_f, 
                                  'mode_of_payment': refund.mode_of_payment, 'cash': refund.try(:cash),
                                  'card': refund.try(:card), 'card_number': refund.try(:card_number),
                                  'cheque_date': refund.try(:cheque_date), 
                                  'cheque_note': refund.try(:cheque_note),
                                  'transfer_date': refund.try(:transfer_date),
                                  'transfer_note': refund.try(:transfer_note),
                                  'other_note': refund.try(:other_note),
                                  'refund_display_id': refund.refund_display_id,
                                  'bill_number': refund.try(:bill_number),
                                  'advance_display_id': refund.try(:advance_display_id),
                                  'type': refund.try(:type), 'department_id': refund.try(:department_id),
                                  'department_name': refund.try(:department_name), 
                                  'level': refund.try(:level), 'refund_state': refund.refund_state, 
                                  'user_id': refund.user_id, 
                                  'return_charges': refund.return_charges, 'refund_type': refund.type,
                                  'refund_payment_type': refund.try(:refund_payment_type),
                                  'store_id': refund.try(:store_id), 'is_canceled': refund.is_canceled, 
                                  'canceled_by': refund.try(:canceled_by), 
                                  'canceled_by_id': refund.try(:canceled_by_id),
                                  'cancel_date': refund.try(:cancel_date),
                                  'refunded_by': refund.try(:refunded_by), 
                                  'refunded_by_id': refund.try(:refunded_by_id), 
                                  'is_refunded': refund.is_refunded, 
                                  'refund_date': refund.refund_date, 'refund_time': refund.refund_time, 
                                  'patient_id': refund.patient.id
                                }
            end
          end

          invoice_hash = {
            'advance_id': invoice.id.to_s, 'bill_no': invoice.advance_display_id, 
            'bill_date': invoice.created_at.to_date, 'bill_date_time': invoice.created_at, 
            'bill_type': 'cash', 'mode_of_payment': invoice.mode_of_payment.downcase, 
            'amount': invoice.amount, 'reason': invoice.reason, 
            'amount_remaining': invoice.amount_remaining, 'state': advance_state, 
            'created_at': invoice.created_at, 'updated_at': invoice.updated_at, 
            'department_id': department_id, 'is_deleted': invoice.is_deleted, 
            'department_name': department_name, 'department_order': department_order,
            'facility_name': facility_name, 'facility_timezone': facility_timezone, 
            'payment_date': invoice.payment_date, 'payment_time': invoice.payment_time, 
            'is_cancelled': is_cancelled, 'canceled_by_id': invoice.canceled_by_id,
            'canceled_by': invoice.canceled_by, 'cancel_date': invoice.cancel_date, 
            'is_refunded': invoice.is_refunded, 'refund_reason': invoice.refund_reason, 
            'refunded_by': invoice.refunded_by, 'refunded_by_id': invoice.refunded_by_id,
            'refund_date': invoice.refund_date, 'refund_time': invoice.refund_time, 
            'refund_amount': invoice.refund_amount
          }
          patient_hash = {
            'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 
            'gender': patient.gender, 'patient_identifier_id': patient.patient_identifier_id, 
            'patient_mrn': patient.patient_mrn, 'location_id': location_id,
            'area_manager_id': area_manager_id, 'area_manager_name': area_manager_name,
            'commune': commune, 'district': district, 'state': state, 'pincode': pincode, 
            'city': city
          }
          user_hash = {
            'user_id': user_id, 'name': user_name, 'designation': user.designation
          }
          # advance payment history
          advance_history = []
          has_advance_history = false
          advancehistories = invoice.advance_history
          if advancehistories.count > 0
            has_advance_history = true
            advancehistories.each do |advancehistory|
              advance_history << {
                log_id: advancehistory['advance_payment_breakup_id'], 
                invoice_id: advancehistory['invoice_id'], username: advancehistory['user_name'], 
                comment: '', bill_number: advancehistory['bill_number'],
                created_at: advancehistory['event_time'], invoice_type: advancehistory['invoice_type'], 
                receipt_date: '', old_total: '', new_total: '', user_id: '', updated_at: '', 
                organisation_id: '', facility_id: '', user_name: advancehistory['user_name'], 
                type: advancehistory['type'], amount: advancehistory['amount']
              }
              # NOTE: empty values are not there in main table
            end
          end
          # EOF advance payment history
          # filter_fields
          filter_fields_hash = { organisation_id: organisation_id, facility_id: facility_id,
                                 user_id: user_id }
          # EOF filter_fields
          # search_fields
          search_fields_hash = { patient_name: patient_name, user_name: user_name }
          # EOF search_fields
          f_mis_revenue = ::Finance::ReportData.find_or_create_by(
            invoice_id: invoice.id.to_s, organisation_id: organisation_id, facility_id: facility_id
          )
          # EOF advance_invoice_fields
          f_mis_revenue.is_advance = true
          f_mis_revenue.is_cancelled = is_cancelled
          f_mis_revenue.is_refunded = is_refunded
          f_mis_revenue.refunds_count = refunds_count
          f_mis_revenue.receipt_created_at = invoice.created_at
          f_mis_revenue.receipt_updated_at = invoice.updated_at
          f_mis_revenue.receipt_display_fields = invoice_hash
          f_mis_revenue.has_refund_history = has_refund_history
          f_mis_revenue.refund_history = refund_history
          f_mis_revenue.patient_display_fields = patient_hash
          f_mis_revenue.user_display_fields = user_hash
          f_mis_revenue.has_advance_history = has_advance_history
          f_mis_revenue.advance_history = advance_history
          f_mis_revenue.filter_fields = filter_fields_hash
          f_mis_revenue.search_fields = search_fields_hash
          f_mis_revenue.is_deleted = is_deleted
          f_mis_revenue.save!
        else
          mis_logger.info("AdvancePayment not found with id: #{advance_bill_id}")
        end
      rescue StandardError => e
        mis_logger.error(" === error in AdvancePaymentService :: #{e.inspect}")
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
