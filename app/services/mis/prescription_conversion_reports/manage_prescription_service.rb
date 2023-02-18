module Mis::PrescriptionConversionReports
  class ManagePrescriptionService
    class << self
      def call(prescription_type, prescriptionid, organisation_id=nil, facility_id=nil, facility_name=nil, facility_timezone=nil, department_id=nil, department_name=nil, department_order=nil, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        order_count = 0; re_converted = mark_patient_visited = false
        if prescription_type == 'pharmacy'
          patient_prescription = PatientPrescription.find_by(id: prescriptionid)
          dispatched_from_store = patient_prescription.try(:dispatched_from_pharmacy)
          is_deleted = patient_prescription.is_deleted
        elsif prescription_type == 'optical'
          patient_prescription = PatientOpticalPrescription.find_by(id: prescriptionid)
          dispatched_from_store = patient_prescription.try(:dispatched_from_optical)
          is_deleted = (patient_prescription.advise_glasses.present? && patient_prescription.advise_glasses == 'advise') ? false : true
          order_count = patient_prescription.try(:order_count)
          re_converted = patient_prescription.try(:re_converted)
          mark_patient_visited = patient_prescription.try(:mark_patient_visited)
        end
        return unless patient_prescription.present?

        unless facility_id.present?
          facility_id = patient_prescription.try(:facility_id)
          facilty = Facility.find_by(id: facility_id)
          facility_name = facilty.try(:name)
          facility_timezone = facilty.try(:time_zone)
        else
          facility_id = BSON::ObjectId(facility_id)
        end
        
        organisation_id = (organisation_id.present?) ? BSON::ObjectId(organisation_id) : facilty.organisation_id

        store_id = patient_prescription.store_id
        mis_logger.info(
          " ========== Store id not found for #{prescription_type} prescription with ID: #{prescriptionid}"
        ) if store_id.nil?
        store = Inventory::Store.find_by(id: store_id)
        store_name = store.try(:name)
        store_abbreviation_name = store.try(:abbreviation_name)
        store_present = patient_prescription.store_present

        unless department_id.present?
          department_id = if store.present?
                            store.try(:department_id)
                          elsif prescription_type == 'pharmacy'
                            '284748001'
                          elsif prescription_type == 'optical'  
                            '50121007'
                          end
          department = Department.find_by(id: department_id)
          department_name = department.try(:display_name)
          department_order = department.try(:order)
        end
        
        specialty_id = patient_prescription.try(:specalityid)
        specialty_name = patient_prescription.try(:specalityname)

        prescription_id = patient_prescription.id

        prescription_created_at = patient_prescription.created_at
        prescription_updated_at = patient_prescription.updated_at
        prescription_date = patient_prescription.try(:prescription_date)
        prescription_datetime = patient_prescription.try(:prescription_datetime)

        advance_details = {
          display_id: patient_prescription.try(:display_id), 
          advance_amount: patient_prescription.try(:advance_amount),
          advance_reason: patient_prescription.try(:advance_reason)
        }

        advised_on_date = (prescription_date.present?) ? prescription_date : prescription_created_at.to_date
        advised_on_datetime = (prescription_datetime.present?) ? prescription_datetime : prescription_created_at
        advised_by_id = patient_prescription.try(:authorid)
        advised_by_details = {}
        advised_by = User.find_by(id: advised_by_id)
        if advised_by.present?
          advised_by_details = {
            name: advised_by.try(:fullname), designation: advised_by.try(:designation), 
            age: advised_by.try(:age), mobilenumber: advised_by.try(:mobilenumber), 
            email: advised_by.try(:email), address: advised_by.try(:address),
            city: advised_by.try(:city), state: advised_by.try(:state), 
            pincode: advised_by.try(:pincode), commune: advised_by.try(:commune), 
            district: advised_by.try(:district), employee_id: advised_by.try(:employee_id), 
            is_active: advised_by.try(:is_active),
            account_expiry_date: advised_by.try(:account_expiry_date)
          }
        end

        is_converted = patient_prescription.try(:converted)
        converted_on_date = converted_on_datetime = converted_by_id = converted_by = nil
        if is_converted == true
          converted_on_date = (patient_prescription.converted_date.present?) ? patient_prescription.converted_date : patient_prescription.encounterdate.to_date
          converted_on_datetime = (patient_prescription.converted_datetime.present?) ? patient_prescription.converted_datetime : patient_prescription.encounterdate
          converted_by_id = patient_prescription.try(:mark_converted_by)
          converted_by = User.find_by(id: converted_by_id)
        end
        
        converted_by_details = {}
        if converted_by.present?
          converted_by_details = {
            name: converted_by.try(:fullname), designation: converted_by.try(:designation), 
            age: converted_by.try(:age), mobilenumber: converted_by.try(:mobilenumber), 
            email: converted_by.try(:email), address: converted_by.try(:address), 
            city: converted_by.try(:city), state: converted_by.try(:state), 
            pincode: converted_by.try(:pincode), commune: converted_by.try(:commune), 
            district: converted_by.try(:district), employee_id: converted_by.try(:employee_id), 
            is_active: converted_by.try(:is_active),
            account_expiry_date: converted_by.try(:account_expiry_date)
          }
        end
        converted_at_store_id = (is_converted.nil?) ? '-' : patient_prescription.store_id
        converted_at_store_name = (is_converted.nil?) ? '-' : store_name

        patient_details = {}
        if patient_prescription.try(:patient).present?
          patient = patient_prescription.patient
          location_id = patient&.location_id
          area_manager_id = patient&.area_manager_id
          area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
          patient_details = {
            id: patient.try(:id), name: patient.try(:fullname), age: patient.try(:age), 
            exact_age: patient.try(:exact_age), displayage: patient.try(:displayage), 
            dob: patient.try(:dob), dob_day: patient.try(:dob_day), dob_month: patient.dob_month, 
            dob_year: patient.try(:dob_year), is_approx_dob: patient.try(:is_approx_dob), 
            mobilenumber: patient.try(:mobilenumber), address_1: patient.try(:address_1), 
            address_2: patient.try(:address_2), district: patient.try(:district), 
            commune: patient.try(:commune), city: patient.city, state: patient.try(:state), 
            pincode: patient.try(:pincode), identifier_id: patient.try(:patient_identifier_id),
            mrn: patient.try(:patient_mrn), gender: patient.try(:gender), location_id: location_id,
            area_manager_id: area_manager_id, area_manager_name: area_manager_name
          }
        end
        # EOF patient_prescription.patient.present?
        # invoice
        invoice = Invoice::InventoryInvoice.find_by(prescription_id: prescription_id.to_s)
        invoice_id = nil; invoice_details = {}
        if invoice.present?
          invoice_id = invoice.try(:id)
          invoice_type = invoice.try(:_type)
          tax = begin
                  invoice.tax_breakup.map { |h| h[:amount].to_f }.sum
                rescue StandardError
                  0.00
                end
          pending_from = invoice.payment_pending_breakups.pluck(:received_from).uniq
          payment_received_brkups = invoice.payment_received_breakups
          has_received_from = (payment_received_brkups.count > 0)
          payment_received = invoice.try(:payment_received).to_f
          gross_amount = invoice.try(:net_amount).to_f
          invoice_status = invoice.try(:payment_pending).to_f <= invoice.try(:total).to_f ? 'Pending' : 'Paid'
          advance_amount = invoice.try(:advance_payment).to_f
          state = invoice.try(:state)
          mode_of_payment = begin
                              invoice.try(:mode_of_payment) || payment_received_brkups.pluck(
                                :mode_of_payment
                              ).uniq.join(',')
                            rescue StandardError
                              nil
                            end
          if invoice_type.in?(['Invoice::Opd', 'Invoice::Ipd'])
            currency = payment_received_brkups.pluck(:currency_symbol).uniq.last
            currency_id = payment_received_brkups.pluck(:currency_id).uniq.last
          else
            currency = invoice.currency_symbol
            currency_id = invoice.currency_id
          end
          i_type = invoice_type.to_s.split(':')[-1].underscore
          is_cancelled = invoice.is_canceled
          customer_comments = invoice.patient_comment
          internal_comments = invoice.comments

          # return invoice
          return_invoice = Inventory::Transaction::Return.find_by(invoice_id: invoice.id)
          is_refunded = false; refund_reason = refunded_by = ''
          if return_invoice.present?
            is_refunded = true
            refund_reason = return_invoice.try(:note)
            refunded_by_id = return_invoice.try(:user_id)
            return_date = return_invoice.try(:return_date)
            return_time = return_invoice.try(:return_time)
            return_amount = return_invoice.try(:return_amount)
          end
          
          # EOF return invoice
          
          invoice_details = {
            bill_no: invoice.try(:bill_number), bill_date: invoice.try(:created_at), 
            bill_type: invoice.try(:invoice_type), total: invoice.try(:total), tax: tax, 
            additional_discount: invoice.try(:additional_discount) || 0,
            services_discount: invoice.try(:services_discount) || 0, 
            total_discount: invoice.try(:total_discount) || 0,
            additional_discount_comment: invoice.try(:additional_discount_comment),
            round: invoice.try(:round), status: invoice_status, advance_payment: advance_amount,
            amount_remaining: invoice.try(:amount_remaining), 
            payment_pending: invoice.try(:payment_pending),
            payment_received: payment_received, comments: invoice.try(:comments), 
            mode_of_payment: mode_of_payment, no_of_servies: invoice.services.count, 
            currency_id: currency_id, currency: currency, type: i_type, 
            has_pending: (pending_from.count > 0), pending_received_from: pending_from,
            has_received: has_received_from, gross_amount: gross_amount, 
            non_taxable_amount: invoice.try(:non_taxable_amount),
            amount_adjusted: invoice.try(:round), no_of_receipts: payment_received_brkups.count,
            invoice_created_at: invoice.try(:created_at), 
            invoice_updated_at: invoice.try(:updated_at), 
            state: state, customer_comments: customer_comments, 
            internal_comments: internal_comments,
            is_cancelled: is_cancelled, canceled_by_id: invoice.try(:canceled_by_id), 
            canceled_by: invoice.try(:canceled_by), cancel_date: invoice.try(:cancel_date), 
            is_refunded: is_refunded, refund_reason: refund_reason, 
            refunded_by: invoice.try(:refunded_by), refunded_by_id: refunded_by_id, 
            refund_date: return_date, refund_time: return_time, refund_amount: return_amount,
            offer_on_bill: invoice.try(:offer_on_bill), 
            offer_on_services: invoice.try(:offer_on_services), 
            total_offer: invoice.try(:total_offer), 
            offer_manager_id: invoice.try(:offer_manager_id),
            offer_name: invoice.try(:offer_name), offer_code: invoice.try(:offer_code),
            offer_percentage: invoice.try(:offer_percentage),
            total_of_all_discount: invoice.try(:total_of_all_discount)
          }
        end
        # EOF invoice

        # filter_fields
        filter_fields_hash = {
          organisation_id: organisation_id, facility_id: facility_id, department_id: department_id,
          store_id: store_id, advised_on_date: advised_on_date, is_converted: is_converted,
          advised_by_id: advised_by_id, converted_by_id: converted_by_id, is_deleted: is_deleted
        }
        # EOF filter_fields

        # search_fields_hash
        search_fields_hash = {
          facility_name: facility_name, department_name: department_name, store_name: store_name,
          advised_by_name: advised_by_details[:name]
        }
        # EOF search_fields_hash

        store_conversion = Inventory::StoreConversion.find_or_create_by(
          organisation_id: organisation_id, facility_id: facility_id, prescription_id: prescription_id
        )
        store_conversion.prescription_type = prescription_type
        store_conversion.facility_name = facility_name
        store_conversion.facility_timezone = facility_timezone

        store_conversion.department_id = department_id
        store_conversion.department_name = department_name
        store_conversion.department_order = department_order

        store_conversion.store_id = store_id
        store_conversion.store_name = store_name
        store_conversion.store_abbreviation_name = store_abbreviation_name
        store_conversion.store_present = store_present

        store_conversion.specialty_id = specialty_id
        store_conversion.specialty_name = specialty_name

        store_conversion.advised_on_date = advised_on_date
        store_conversion.advised_on_datetime = advised_on_datetime
        store_conversion.advised_by_id = advised_by_id
        store_conversion.advised_by_details = advised_by_details

        store_conversion.is_converted = is_converted
        store_conversion.converted_on_date = converted_on_date
        store_conversion.converted_on_datetime = converted_on_datetime
        store_conversion.converted_by_id = converted_by_id
        store_conversion.converted_by_details = converted_by_details
        store_conversion.converted_at_store_id = converted_at_store_id
        store_conversion.converted_at_store_name = converted_at_store_name

        store_conversion.store_comment = send("#{prescription_type}_comments", patient_prescription)
        store_conversion.patient_details = patient_details
        store_conversion.invoice_id = invoice_id
        store_conversion.invoice_details = invoice_details
        store_conversion.advance_details = advance_details
        store_conversion.is_deleted = is_deleted
        store_conversion.dispatched_from_store = dispatched_from_store
        store_conversion.order_count = order_count
        store_conversion.re_converted = re_converted
        store_conversion.mark_patient_visited = mark_patient_visited
        store_conversion.conversion_time_days = conversion_time(advised_on_date, converted_on_date)
        store_conversion.filter_fields = filter_fields_hash
        store_conversion.search_fields = search_fields_hash
        store_conversion.not_converted_to_converted = patient_prescription.not_converted_to_converted
        store_conversion.save!

        patient_prescription.update_attributes(is_prescription_migrated: true)
      rescue StandardError => e
        mis_logger.error(" === facility :: #{facility_name.inspect}")
        mis_logger.error(" === facility id :: #{facility_id.inspect}")
        mis_logger.error(" === organisation_id :: #{organisation_id.inspect}")
        mis_logger.error(" === error in ManagePrescriptionService :: #{e.inspect}")
      end

      def conversion_time(advised_dt, performed_dt)
        if advised_dt.present? && performed_dt.present?
          (performed_dt.to_date - advised_dt.to_date).to_i
        else
          ''
        end
      end
      # end conversion_time method

      def pharmacy_comments(prescription)
        prescription.pharmacy_comment
      end

      def optical_comments(prescription)
        comments = []
        comments << 'Collection not good' if prescription.reason_one == 'true'
        comments << 'Dilated' if prescription.reason_two == 'true'
        comments << 'Will come later with relatives' if prescription.reason_three == 'true'
        comments << 'Known optical shop' if prescription.reason_four == 'true'
        comments << 'Optical DRT referral' if prescription.reason_five == 'true'
        comments << 'Expensive' if prescription.reason_six == 'true'
        comments << 'Looking for high discount' if prescription.reason_seven == 'true'
        comments << 'Not interested in wearing glasses' if prescription.reason_eight == 'true'
        comments << prescription.optical_comment if prescription.optical_comment.present?
        comments.join(', ')
      end

    end
  end
end
