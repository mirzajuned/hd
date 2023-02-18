# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/ClassLength
module Mis::CollectionReports
  class ManageCollectionService
    class << self
      def call(data_id, receipt_type, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        if receipt_type == 'Bill'
          bill_receipt_data(data_id, receipt_type, mis_logger)
        end
        if receipt_type == 'Advance'
          advance_receipt_data(data_id, receipt_type, mis_logger)
        end
        if receipt_type == 'Refund'
          refund_receipt_data(data_id, receipt_type, mis_logger)
        end
        if receipt_type == 'Return'
          return_receipt_data(data_id, receipt_type, mis_logger)
        end
      rescue StandardError => e
        mis_logger.info(" === Error in ManageCollectionService: #{e.inspect}")
      end
      # EOF call

      def advance_receipt_data(data_id, receipt_type, mis_logger)
        advance_payment_id = data_id
        receipt = AdvancePayment.find_by(id: advance_payment_id)
        invoice_id = receipt.invoice_id.to_s
        if invoice_id.present?
          invoice = Invoice.find_by(id: invoice_id)
        end
        organisation_id = receipt.organisation_id.to_s
        facility_id = receipt.facility_id.to_s
        facilty = Facility.find_by(id: facility_id)
        facility_name = facilty.try(:name)
        facility_timezone = facilty.try(:time_zone)
        specialty_id = receipt.specialty_id
        specialty_name = Specialty.find_by(id: specialty_id).try(:name)
        department_id = receipt.department_id
        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        state = invoice.try(:advance_state)
        store_id = receipt.store_id

        invoice_type = invoice.try(:_type)
        i_type = invoice_type.to_s.split(':')[-1].try(:underscore)
        bill_no = invoice.try(:bill_number) || "-"
        bill_type = invoice.try(:invoice_type) || "-"
        receipt_created_at = invoice.try(:created_at) || "-"

        currency = receipt.try(:currency_symbol)
        currency_id = receipt.try(:currency_id)
        receipt_number = receipt.try(:advance_display_id)
        mode_of_payment = receipt.try(:mode_of_payment)
        mop_note = "#{receipt.try(:card_number)}#{receipt.try(:cheque_note)}#{receipt.try(:transfer_note)}#{receipt.try(:other_note)}#{receipt.try(:gpay_transaction_note)}#{receipt.try(:paytm_transaction_note)}#{receipt.try(:phonepe_transaction_note)}"
        receipt_date = receipt.try(:payment_date) # handling the date issue in advance and refund payment table, changing date as discussed with Anoop
        receipt_time = receipt.try(:payment_time)
        receipt_user_id = receipt.try(:user_id)
        receipt_user = User.find_by(id: receipt_user_id)
        receipt_user_fullname = receipt_user.try(:fullname)
        receipt_hash = {
          'bill_no': bill_no, 'bill_date': receipt_created_at, 'bill_type': bill_type,
          'bill_total': "", 'receipt_amount': receipt.try(:amount), 'comments': receipt.try(:reason),
          'mode_of_payment': mode_of_payment, 'mop_note': mop_note, 'currency_id': currency_id, 
          'currency': currency, 'receipt_no': receipt_number, 'specialty_id': specialty_id, 
          'specialty_name': specialty_name, 'department_id': department_id, 
          'department_name': department_name, 'store_id': store_id, 'department_order': department_order, 
          'facility_id': facility_id, 'facility_name': facility_name,
          'facility_timezone': facility_timezone, 'organisation_id': organisation_id, 'type': i_type,
          'receipt_user_id': receipt_user_id, receipt_user_fullname: receipt_user_fullname,
          'receipt_date': receipt_date, 'receipt_time': receipt_time, 'state': state
        }

        # patient_payer_display_fields
        patient_id = receipt.patient_id.to_s
        patient = Patient.find_by(id: patient_id)
        patient_name = patient.try(:fullname)
        age = (patient.try(:age).present? && patient.try(:age) > 0) ? patient.try(:age) : patient.try(:exact_age)
        commune = patient.try(:commune)
        district = patient.try(:district)
        state = patient.try(:state)
        pincode = patient.try(:pincode)
        city = patient.try(:city)
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        patient_hash = {
          'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 
          'gender': patient.try(:gender), 
          'patient_identifier_id': patient.try(:patient_identifier_id), 
          'patient_mrn': patient.try(:patient_mrn), 'location_id': location_id,
          'area_manager_id': area_manager_id, 'area_manager_name': area_manager_name,
          'commune': commune, 'district': district, 'state': state, 'pincode': pincode,
          'city': city
        }

        # user_display_fields
        user_hash = { 'id': receipt_user_id, 'name': receipt_user_fullname, 'designation': receipt_user.try(:designation) }

        # filter_fields
        filter_fields_hash = {
          organisation_id: organisation_id, facility_id: facility_id, department_id: department_id,
          user_id: receipt_user_id, mode_of_payment: mode_of_payment, store_id: store_id
        }

        # search_fields
        search_fields_hash = { patient_name: patient_name, user_name: receipt_user_fullname }
        # EOF search_fields

        f_mis_collection = Finance::CollectionTransactionData.find_or_create_by(receipt_id: receipt.id.to_s)

        f_mis_collection.is_advance = true
        f_mis_collection.invoice_id = invoice.try(:id)
        f_mis_collection.user_id = receipt_user_id
        f_mis_collection.facility_id = facility_id
        f_mis_collection.organisation_id = organisation_id
        f_mis_collection.user_fullname = receipt_user_fullname
        f_mis_collection.receipt_type = receipt_type

        f_mis_collection.receipt_date = receipt_date
        f_mis_collection.receipt_time = receipt_time

        f_mis_collection.patient_display_fields = patient_hash
        f_mis_collection.receipt_display_fields = receipt_hash
        f_mis_collection.user_display_fields = user_hash
        f_mis_collection.common_display_fields = {}
        f_mis_collection.filter_fields = filter_fields_hash
        f_mis_collection.search_fields = search_fields_hash
        f_mis_collection.store_id = store_id
        f_mis_collection.is_deleted = invoice.try(:is_deleted) || false
        f_mis_collection.save!
      end
      # advance_receipt_data

      def return_receipt_data(data_id, receipt_type, mis_logger)
        return_transaction_id = data_id

        receipt = Inventory::Transaction::Return.find_by(id: return_transaction_id)

        invoice_id = receipt.invoice_id.to_s
        if invoice_id.present?
          invoice = Invoice.find_by(id: invoice_id)
        end

        organisation_id = receipt.organisation_id.to_s
        facility_id = receipt.facility_id.to_s
        facilty = Facility.find_by(id: facility_id)
        facility_name = facilty.try(:name)
        facility_timezone = facilty.try(:time_zone)
        specialty_id = receipt.try(:specialty_id) || invoice.try(:specialty_id)
        specialty_name = Specialty.find_by(id: specialty_id).try(:name)
        department_id = receipt.department_id
        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        store_id = receipt.store_id

        invoice_type = invoice.try(:_type)
        i_type = invoice_type.to_s.split(':')[-1].try(:underscore)

        receipt_created_at = invoice.try(:created_at) || "-"
        bill_no = invoice.try(:bill_number) || "-"
        bill_type = invoice.try(:invoice_type) || "-"

        currency = receipt.try(:currency_symbol)|| invoice.try(:currency_symbol)
        currency_id = receipt.try(:currency_id) || invoice.try(:currency_id)
        receipt_number = receipt.try(:return_bill_number)
        mode_of_payment = receipt.try(:mode_of_payment)
        mop_note = "#{receipt.try(:card_number)}#{receipt.try(:cheque_note)}#{receipt.try(:transfer_note)}#{receipt.try(:other_note)}#{receipt.try(:gpay_transaction_note)}#{receipt.try(:paytm_transaction_note)}#{receipt.try(:phonepe_transaction_note)}"
        receipt_date = receipt.try(:return_date) #handling the date issue in advance and refund payment table
        receipt_time = receipt.try(:return_time) || receipt.try(:created_at)
        receipt_user_id = receipt.try(:user_id).to_s
        receipt_user = User.find_by(id: receipt_user_id)
        receipt_user_fullname = receipt_user.try(:fullname)
        receipt_hash = {
          'bill_no': bill_no, 'bill_date': receipt_created_at, 'bill_type': bill_type,
          'bill_total': "", 'receipt_amount': receipt.try(:return_amount), 
          'comments': receipt.try(:comments), 'mode_of_payment': mode_of_payment, 
          'mop_note': mop_note, 'currency_id': currency_id, 'currency': currency,
          'receipt_no': receipt_number, 'specialty_id': specialty_id, 
          'specialty_name': specialty_name, 'department_id': department_id, 
          'department_name': department_name, 'department_order': department_order, 
          'facility_id': facility_id, 'facility_name': facility_name,
          'facility_timezone': facility_timezone, 'organisation_id': organisation_id, 'type': i_type,
          'receipt_user_id': receipt_user_id, receipt_user_fullname: receipt_user_fullname,
          'receipt_date': receipt_date, 'receipt_time': receipt_time, 'store_id': store_id
        }

        # patient_payer_display_fields
        patient_id = receipt.patient_id.to_s
        patient = Patient.find_by(id: patient_id)
        patient_name = patient.fullname
        age = (patient.age.present? && patient.age > 0) ? patient.age : patient.exact_age
        commune = patient.try(:commune)
        district = patient.try(:district)
        state = patient.try(:state)
        pincode = patient.try(:pincode)
        city = patient.try(:city)
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        patient_hash = {
          'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 
          'gender': patient.gender, 'patient_identifier_id': patient.patient_identifier_id, 
          'patient_mrn': patient.patient_mrn, 'location_id': location_id,
          'area_manager_id': area_manager_id, 'area_manager_name': area_manager_name,
          'commune': commune, 'district': district, 'state': state, 'pincode': pincode, 
          'city': city
        }

        # user_display_fields
        user_hash = { 'id': receipt_user_id, 'name': receipt_user_fullname, 'designation': receipt_user.try(:designation) }

        # filter_fields
        filter_fields_hash = {
          organisation_id: organisation_id, facility_id: facility_id, department_id: department_id,
          user_id: receipt_user_id, mode_of_payment: mode_of_payment, store_id: store_id, currency_id: currency_id
        }

        # search_fields
        search_fields_hash = { patient_name: patient_name, user_name: receipt_user_fullname }
        # EOF search_fields

        f_mis_collection = Finance::CollectionTransactionData.find_or_create_by(receipt_id: receipt.id.to_s)

        f_mis_collection.is_refund = true
        f_mis_collection.invoice_id = invoice.try(:id)
        f_mis_collection.user_id = receipt_user_id
        f_mis_collection.facility_id = facility_id
        f_mis_collection.organisation_id = organisation_id
        f_mis_collection.user_fullname = receipt_user_fullname
        f_mis_collection.receipt_type = 'Refund'

        f_mis_collection.receipt_date = receipt_date
        f_mis_collection.receipt_time = receipt_time

        f_mis_collection.patient_display_fields = patient_hash
        # f_mis_collection.payer_display_fields = payer_hash
        f_mis_collection.receipt_display_fields = receipt_hash
        f_mis_collection.user_display_fields = user_hash
        f_mis_collection.common_display_fields = {}
        f_mis_collection.filter_fields = filter_fields_hash
        f_mis_collection.search_fields = search_fields_hash
        f_mis_collection.store_id = store_id
        f_mis_collection.is_deleted = invoice.try(:is_deleted) || false

        f_mis_collection.save!
      end
      # EOF return_receipt_data

      def refund_receipt_data(data_id, receipt_type, mis_logger)
        refund_payment_id = data_id
        receipt = RefundPayment.find_by(id: refund_payment_id)
        invoice_id = receipt.invoice_id.to_s
        if invoice_id.present?
          invoice = Invoice.find_by(id: invoice_id)
        end

        advance_payment_id = receipt.invoice_id.to_s
        if advance_payment_id.present?
          advance_payment = AdvancePayment.find_by(id: advance_payment_id)
        end

        organisation_id = receipt.organisation_id.to_s
        facility_id = receipt.facility_id.to_s
        facilty = Facility.find_by(id: facility_id)
        facility_name = facilty.try(:name)
        facility_timezone = facilty.try(:time_zone)
        specialty_id = receipt.specialty_id
        specialty_name = Specialty.find_by(id: specialty_id).try(:name)
        department_id = receipt.department_id
        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        store_id = receipt.store_id

        i_type = advance_payment.try(:type).try(:underscore)
        advance_payment_created_at = advance_payment.try(:created_at) || "-"
        advance_display_id = advance_payment.try(:advance_display_id) || "-"

        invoice_type = invoice.try(:_type)
        i_type = invoice_type.to_s.split(':')[-1].try(:underscore) if i_type.blank?

        receipt_created_at = invoice.try(:created_at) || "-"
        bill_no = invoice.try(:bill_number) || "-"
        bill_type = invoice.try(:invoice_type) || "-"

        currency = receipt.try(:currency_symbol)
        currency_id = receipt.try(:currency_id)
        receipt_number = receipt.try(:refund_display_id)
        mode_of_payment = receipt.try(:mode_of_payment)
        mop_note = "#{receipt.try(:card_number)}#{receipt.try(:cheque_note)}#{receipt.try(:transfer_note)}#{receipt.try(:other_note)}#{receipt.try(:gpay_transaction_note)}#{receipt.try(:paytm_transaction_note)}#{receipt.try(:phonepe_transaction_note)}"
        receipt_date = receipt.try(:payment_date) #handling the date issue in advance and refund payment table, changing date as discussed with Anoop
        receipt_time = receipt.try(:payment_time)
        receipt_user_id = receipt.try(:user_id)
        receipt_user = User.find_by(id: receipt_user_id)
        receipt_user_fullname = receipt_user.try(:fullname)


        receipt_hash = {
          'bill_no': bill_no, 'bill_date': receipt_created_at, 'bill_type': bill_type,'bill_total': "",
          'advance_payment_date': advance_payment_created_at, 'advance_display_id': advance_display_id,
          'receipt_amount': receipt.try(:amount), 'comments': receipt.try(:reason),
          'mode_of_payment': mode_of_payment, 'mop_note': mop_note, 'currency_id': currency_id, 
          'currency': currency, 'receipt_no': receipt_number, 'specialty_id': specialty_id, 
          'specialty_name': specialty_name, 'department_id': department_id, 
          'department_name': department_name, 'store_id': store_id,
          'department_order': department_order, 'facility_id': facility_id, 
          'facility_name': facility_name, 'facility_timezone': facility_timezone, 
          'organisation_id': organisation_id, 'type': i_type,
          'receipt_user_id': receipt_user_id, receipt_user_fullname: receipt_user_fullname,
          'receipt_date': receipt_date, 'receipt_time': receipt_time
        }

        # patient_payer_display_fields
        patient_id = receipt.patient_id.to_s
        patient = Patient.find_by(id: patient_id)
        patient_name = patient.fullname
        age = (patient.age.present? && patient.age > 0) ? patient.age : patient.exact_age
        commune = patient.try(:commune)
        district = patient.try(:district)
        state = patient.try(:state)
        pincode = patient.try(:pincode)
        city = patient.try(:city)
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        patient_hash = {
          'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 
          'gender': patient.gender, 'patient_identifier_id': patient.patient_identifier_id, 
          'patient_mrn': patient.patient_mrn, 'location_id': location_id, 
          'area_manager_id': area_manager_id, 'area_manager_name': area_manager_name, 
          'commune': commune, 'district': district, 'state': state, 'pincode': pincode, 
          'city': city
        }
        # user_display_fields
        user_hash = { 'id': receipt_user_id, 'name': receipt_user_fullname, 'designation': receipt_user.try(:designation) }
        # filter_fields
        filter_fields_hash = {
          organisation_id: organisation_id, facility_id: facility_id, department_id: department_id,
          user_id: receipt_user_id, mode_of_payment: mode_of_payment, store_id: store_id
        }
        # search_fields
        search_fields_hash = { patient_name: patient_name, user_name: receipt_user_fullname }
        # EOF search_fields
        f_mis_collection = Finance::CollectionTransactionData.find_or_create_by(receipt_id: receipt.id.to_s)
        f_mis_collection.is_refund = true
        f_mis_collection.invoice_id = invoice.try(:id)
        f_mis_collection.user_id = receipt_user_id
        f_mis_collection.facility_id = facility_id
        f_mis_collection.organisation_id = organisation_id
        f_mis_collection.user_fullname = receipt_user_fullname
        f_mis_collection.receipt_type = receipt_type

        f_mis_collection.receipt_date = receipt_date
        f_mis_collection.receipt_time = receipt_time

        f_mis_collection.patient_display_fields = patient_hash
        # f_mis_collection.payer_display_fields = payer_hash
        f_mis_collection.receipt_display_fields = receipt_hash
        f_mis_collection.user_display_fields = user_hash
        f_mis_collection.common_display_fields = {}
        f_mis_collection.filter_fields = filter_fields_hash
        f_mis_collection.search_fields = search_fields_hash
        f_mis_collection.store_id = store_id
        f_mis_collection.is_deleted = invoice.try(:is_deleted) || false

        f_mis_collection.save!
      end
      # EOF refund_receipt_data

      def bill_receipt_data(data_id, receipt_type, mis_logger)
        invoice_id = data_id
        invoice = Invoice.find_by(id: invoice_id)
        if invoice.present?
          return unless invoice.department_id.present?
          payment_received = invoice.payment_received_breakups
          return if payment_received.blank?
          if payment_received.size > 0
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
            store_id = invoice.store_id
            customer_comments = invoice.try(:patient_comment)
            internal_comments = invoice.try(:comments)
            state = invoice.try(:state)

            bill_no = invoice.try(:bill_number)
            bill_type = invoice.try(:invoice_type)

            i_type = invoice_type.to_s.split(':')[-1].underscore

            payment_received.each do |receipt|
              currency = receipt.try(:currency_symbol)
              currency_id = receipt.try(:currency_id)
              receipt_number = receipt.try(:receipt_id)
              mode_of_payment = receipt.try(:mode_of_payment)
              mop_note = "#{receipt.try(:card_number)}#{receipt.try(:cheque_note)}#{receipt.try(:transfer_note)}#{receipt.try(:other_note)}#{receipt.try(:gpay_transaction_note)}#{receipt.try(:paytm_transaction_note)}#{receipt.try(:phonepe_transaction_note)}"
              receipt_date = receipt.try(:date)
              receipt_time = receipt.try(:time)
              receipt_user_id = receipt.try(:received_by)
              receipt_user = User.find_by(id: receipt_user_id)
              receipt_user_fullname = receipt_user.try(:fullname)

              receipt_hash = {
                'bill_no': bill_no, 'bill_date': receipt_created_at, 'bill_type': bill_type,
                'bill_total': invoice.total, 'receipt_amount': receipt.try(:amount_received), 
                'comments': invoice.comments, 'mode_of_payment': mode_of_payment,'mop_note': mop_note, 
                'currency_id': currency_id, 'currency': currency, 'receipt_no': receipt_number, 
                'specialty_id': specialty_id, 'specialty_name': specialty_name,
                'department_id': department_id, 'department_name': department_name,
                'department_order': department_order, 'facility_id': facility_id, 
                'facility_name': facility_name, 'facility_timezone': facility_timezone, 
                'organisation_id': organisation_id, 'type': i_type,
                'receipt_user_id': receipt_user_id, receipt_user_fullname: receipt_user_fullname,
                'receipt_created_at': receipt_created_at, 'state': state, 'receipt_date': receipt_date,
                'receipt_time': receipt_time, 'customer_comments': customer_comments, 
                'store_id': store_id, 'internal_comments': internal_comments, 
                'offer_on_bill': invoice.try(:offer_on_bill),
                'offer_on_services': invoice.try(:offer_on_services), 
                'total_offer': invoice.try(:total_offer), 'offer_manager_id': invoice.try(:offer_manager_id), 
                'offer_name': invoice.try(:offer_name), 'offer_code': invoice.try(:offer_code), 
                'offer_percentage': invoice.try(:offer_percentage),
                'offer_applied_at': invoice.try(:offer_applied_at), 
                'offer_applied_at_name': invoice.try(:offer_applied_at_name),
                'offer_applied_by': invoice.try(:offer_applied_by),
                'offer_applied_by_name': invoice.try(:offer_applied_by_name),
                'offer_applied_date': invoice.try(:offer_applied_date),
                'offer_applied_datetime': invoice.try(:offer_applied_datetime),
                'total_of_all_discount': invoice.try(:total_of_all_discount)
              }

              # patient_payer_display_fields
              patient = invoice.patient
              patient_id = patient.id.to_s
              patient_name = patient.fullname
              age = (patient.age.present? && patient.age > 0) ? patient.age : patient.exact_age
              commune = patient.try(:commune)
              district = patient.try(:district)
              state = patient.try(:state)
              pincode = patient.try(:pincode)
              city = patient.try(:city)
              location_id = patient&.location_id
              area_manager_id = patient&.area_manager_id
              area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
              patient_hash = {
                'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 
                'gender': patient.gender, 'patient_identifier_id': patient.patient_identifier_id, 
                'patient_mrn': patient.patient_mrn, 'location_id': location_id,
                'area_manager_id': area_manager_id, 'area_manager_name': area_manager_name,
                'commune': commune, 'district': district, 'state': state, 'pincode': pincode,
                'city': city
              }
              # user_display_fields
              user_hash = { 'id': receipt_user_id, 'name': receipt_user_fullname, 'designation': receipt_user.try(:designation) }
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
                  '-'
                end

              if invoice_type == 'Invoice::Opd'
                appointment_registration_type = appointment.try(:appointmenttype) # walkin vs appointment
                appointment_type_id = appointment.try(:appointment_type_id)
                appointment_type_label = AppointmentType.find_by(id: appointment_type_id).try(:label).to_s # dynamic data for new/review/postop etc
                reason = appointment.reason
              end

              common_hash = {
                'display_id': display_id, 'appointment_registration_type': appointment_registration_type,
                'appointment_type_label': appointment_type_label, 'reason': reason
              }
              # EOF common_display_fields

              # filter_fields
              filter_fields_hash = {
                organisation_id: organisation_id, facility_id: facility_id, department_id: department_id,
                bill_type: bill_type, invoice_status: invoice_status, user_id: receipt_user_id,
                mode_of_payment: mode_of_payment, store_id: store_id
              }
              # EOF filter_fields

              # search_fields
              search_fields_hash = { patient_name: patient_name, user_name: receipt_user_fullname }
              # EOF search_fields

              f_mis_collection = Finance::CollectionTransactionData.find_or_create_by(receipt_id: receipt.id.to_s)

              f_mis_collection.is_bill = true
              f_mis_collection.invoice_id = invoice.try(:id)
              f_mis_collection.user_id = receipt_user_id
              f_mis_collection.facility_id = facility_id
              f_mis_collection.organisation_id = organisation_id
              f_mis_collection.user_fullname = receipt_user_fullname
              f_mis_collection.receipt_type = receipt_type

              f_mis_collection.receipt_date = receipt_date
              f_mis_collection.receipt_time = receipt_time

              f_mis_collection.patient_display_fields = patient_hash
              # f_mis_collection.payer_display_fields = payer_hash
              f_mis_collection.receipt_display_fields = receipt_hash
              f_mis_collection.user_display_fields = user_hash
              f_mis_collection.common_display_fields = common_hash
              f_mis_collection.filter_fields = filter_fields_hash
              f_mis_collection.search_fields = search_fields_hash
              f_mis_collection.store_id = store_id
              f_mis_collection.is_deleted = invoice.try(:is_deleted)
              f_mis_collection.save!
            end
          end
        end
      end
      # EOF bill_receipt_data
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
