module Mis::BuildCommonData
  class BuildDataService
    class << self
      def patient_details(patient_id)
        patient = Patient.find_by(id: patient_id)
        patient_hash = {}
        if patient.present?
          patient_name = patient.try(:fullname)
          location_id = patient.try(:location_id)
          area_manager_id = patient.try(:area_manager_id)
          area_manager_name = (location_id.present? && area_manager_id.present? && (patient.try(:area_manager_name).to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient.try(:area_manager_name)
          age = patient.try(:age).present? && patient.try(:age).to_i > 0 ? patient.try(:age) : patient.try(:exact_age)
          exact_age = patient.try(:exact_age)
          opd_visit_count = patient&.opd_visit_count.to_i

          # SS requirements. Adding extra details
          patient_last_appointment = Appointment.where(patient_id: patient_id).last&.appointmentdate
          patient_last_admission = Admission.where(patient_id: patient_id).last&.admissiondate
          is_post_op = if patient_last_appointment.present? && patient_last_admission.present?
                         patient_last_admission > patient_last_appointment
                       else
                         false
                       end
          patient_visit, patient_type = if is_post_op && opd_visit_count >= 1
                            ['Post Op', 'Old']
                          elsif opd_visit_count >= 2 && is_post_op == false
                            ['Followup', 'Old']
                          else
                            ['New', 'New']
                          end
          # binding.pry
          patient_referral_type = PatientReferralType.find_by(patient_id: patient_id)
          referral_type_id = referred_by = relation = ''
          # sub_referral_type = nil
          if patient_referral_type.present?
            referral_type_id = patient_referral_type.try(:referral_type_id)
            sub_referral_type = patient_referral_type.try(:sub_referral_type)
            referred_by = sub_referral_type.try(:name)
            relation = sub_referral_type.try(:relation)
          end
          # EOF SS requirements.
          patient_hash = {patient_id: patient_id, patient_name: patient_name, age: age,
                          gender: patient.try(:gender), 
                          patient_identifier_id: patient.try(:patient_identifier_id),
                          patient_mrn: patient.try(:patient_mrn), 
                          mobilenumber: patient.try(:mobilenumber), 
                          commune: patient.try(:commune), district: patient.try(:district),
                          state: patient.try(:state), pincode: patient.try(:pincode), 
                          city: patient.try(:city), exact_age: exact_age, location_id: location_id,
                          area_manager_id: area_manager_id, area_manager_name: area_manager_name,
                          patient_type: patient_type, patient_visit: patient_visit,
                          referral_type_id: referral_type_id, 
                          sub_referral_type_id: sub_referral_type.try(:id),
                          referred_by: referred_by, relation: relation, relative_name: referred_by,
                          email: patient.try(:email)
                        }
        end
        patient_hash
      end
      #  EOF patient_details

      def invoice_details(invoice_id)
        invoice_hash = {}
        invoice = Invoice.find_by(id: invoice_id)
        department_id = invoice.try(:department_id)
        if invoice.present? && department_id.present?
          organisation_id = invoice.organisation_id.to_s
          facility_id = invoice.facility_id.to_s
          facilty = Facility.find_by(id: facility_id)
          facility_name = facilty.try(:name)
          facility_timezone = facilty.try(:time_zone)
          department = Department.find_by(id: department_id)
          department_name = department.try(:display_name)
          department_order = department.try(:order)
          is_deleted = invoice.try(:is_deleted)
          specialty_id = invoice.specialty_id
          specialty_name = Specialty.find_by(id: specialty_id).try(:name)
          bill_no = invoice.try(:bill_number)
          receipt_created_at = invoice.try(:created_at)
          bill_type = invoice.try(:invoice_type)
          invoice_status = invoice.try(:payment_pending).to_f > invoice.try(:total).to_f ? 'Pending' : 'Paid'
          advance_amount = invoice.try(:advance_payment)
          payment_pending = invoice.try(:payment_pending).to_f
          payment_received = invoice.try(:payment_received)
          gross_amount = invoice.try(:net_amount)
          cancelled_pending = still_pending = 0
          payment_received_brkups = invoice.payment_received_breakups
          invoice_type = invoice.try(:_type)
          tax = begin
                  invoice.tax_breakup.map { |h| h[:amount].to_f }.sum.round(2)
                rescue StandardError
                  0.00
                end

          pending_from = invoice.payment_pending_breakups.pluck(:received_from).uniq
          has_received_from = (payment_received_brkups.count > 0)
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
          if is_cancelled.present? && is_cancelled == true && department_id.in?(['485396012', '486546481', '284748001'])
            still_pending = 0
            # cancelled_pending = refund_amount
            cancelled_pending = payment_pending
          else
            still_pending = payment_pending
            cancelled_pending = 0
          end
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
          invoice_hash = {
            'bill_no': bill_no, 'bill_date': receipt_created_at.try(:to_date), 
            'bill_date_time': receipt_created_at, 'bill_type': bill_type, 
            'total': invoice.try(:total).to_f.round(2), 'tax': tax, 
            'additional_discount': invoice.try(:additional_discount) || 0,
            'services_discount': invoice.try(:services_discount) || 0, 
            'total_discount': invoice.try(:total_discount) || 0, 
            'additional_discount_comment': invoice.try(:additional_discount_comment),
            'round': invoice.try(:round).to_f.round(2), 'status': invoice_status, 
            'advance_payment': advance_amount.to_f.round(2), 
            'amount_remaining': invoice.try(:amount_remaining).to_f.round(2), 
            'payment_pending': payment_pending, 'still_pending': still_pending.to_f.round(2), 
            'cancelled_pending': cancelled_pending.to_f.round(2), 
            'payment_received': payment_received.to_f.round(2), 
            'comments': invoice.try(:comments), 'mode_of_payment': mode_of_payment, 
            'no_of_servies': invoice.try(:services).count.to_i, 'currency_id': currency_id, 
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
            'created_at': receipt_created_at, 'updated_at': invoice.try(:updated_at), 
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
        end
        invoice_hash
      end
      # EOF invoice_details
    end
    # EOF class self
  end
  # EOF BuildDataService
end
