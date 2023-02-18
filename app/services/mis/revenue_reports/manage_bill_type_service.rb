module Mis::RevenueReports
  class ManageBillTypeService
    class << self
      def call(invoiceid)
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        invoice = Invoice.find_by(id: invoiceid)
        invoice_update = invoice.try(:updated_at)
        organisation_id = invoice.try(:organisation_id)
        facility_id = invoice.facility_id
        facility = Facility.find_by(id: facility_id)
        facility_name = facility.try(:name)
        facility_timezone = facility.try(:time_zone)
        invoice_id = invoice.id
        department_id = invoice.department_id
        if department_id.nil?
          mis_logger.info(" ======= department_id is nil for invoice: #{invoice_id}")
          return
        end

        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)

        bill_type = get_bill_type(invoice.net_amount, invoice.total_discount)
        
        f_mis_revenue = Finance::BillTypeSummary.find_or_create_by(
          organisation_id: organisation_id, facility_id: facility_id, department_id: department_id, invoice_id: invoice_id
        )

        f_mis_revenue.facility_name = facility_name
        f_mis_revenue.facility_timezone = facility_timezone
        f_mis_revenue.department_name = department_name
        f_mis_revenue.department_order = department_order

        f_mis_revenue.receipt_date = invoice.try(:created_at).to_date
        f_mis_revenue.receipt_datetime = invoice.try(:created_at)
        f_mis_revenue.bill_type = bill_type
        f_mis_revenue.receipt_display_fields = get_details(
          'Invoice', invoice_id, [
            'bill_number', 'invoice_type', 'total', 'tax', 'additional_discount', 'services_discount',
            'total_discount', 'additional_discount_comment', 'round', 'advance_payment', 
            'amount_remaining', 'payment_pending', 'payment_received', 'currency_id', 'currency_symbol', 
            'specialty_id', '_type', 'net_amount', 'non_taxable_amount', 'state', 'mode_of_payment', 
            'patient_comment', 'comments', 'is_canceled', 'is_refunded', 'refund_reason', 'refunded_by', 
            'refunded_by_id', 'refunded_by_id', 'refund_time', 'refund_amount', 'offer_on_bill',
            'offer_on_services', 'total_offer', 'offer_manager_id', 'offer_name', 'offer_code',
            'offer_percentage', 'offer_applied_at', 'offer_applied_at_name', 'offer_applied_by',
            'offer_applied_by_name', 'offer_applied_date', 'offer_applied_datetime', 
            'total_of_all_discount'
          ]
        )
        f_mis_revenue.user_id = invoice.user_id
        f_mis_revenue.user_display_fields = get_details(
          'User', invoice.user_id, ['fullname', 'mobilenumber', 'email', 'designation']
        )
        f_mis_revenue.patient_id = invoice.patient_id
        patient_display_fields = get_details(
          'Patient', invoice.patient_id, [
            'fullname', 'mobilenumber', 'email', 'gender', 'age', 'exact_age',
            'displayage', 'dob', 'dob_day', 'dob_month', 'dob_year', 'is_approx_dob'
          ]
        )
        patient_current_age, patient_age_present = Patientdata::CurrentAge.call(invoice.patient_id.to_s)
        patient_display_fields.merge!({
          'patient_current_age': patient_current_age, 'patient_age_present': patient_age_present
        })
        f_mis_revenue.patient_display_fields = patient_display_fields
        f_mis_revenue.save!

        invoice.migration = true
        invoice.update(is_migrated: true)
        invoice.update(updated_at: invoice_update)
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManageRevenueService :: #{e.inspect}")
      end
      # end call method

      def get_bill_type(net_amount, discount)
        bill_type = ''
        if net_amount.to_f > 0 && discount.to_f > 0
          bill_type = 'paid_discounted'
        elsif net_amount.to_f == 0  && discount.to_f > 0
          bill_type = 'free_discounted'
        elsif net_amount.to_f > 0 && discount.to_f == 0
          bill_type = 'paid'
        else
          bill_type = 'free'
        end
        bill_type
      end
      # end get_bill_type

      def get_details(table_name, id, fields)
        field_hash = {}
        record = table_name.constantize.find_by(id: id)
        if record.present?
          fields.each do |field|
            field_hash.merge!(:"#{field}" => record[field])
          end
        end
        field_hash
      end
      # end get_details
    end
  end
end
