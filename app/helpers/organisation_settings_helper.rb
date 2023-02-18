module OrganisationSettingsHelper
  class << self
    def get_data(flag, all_data)
      options = {}

      # same helper class used in final print view side and settings side
      all_data.keys.each do |key|
        options['Facility'] = 'Dummy Facility' if key == 'facility_name'

        patient_details(key, options)

        patient_contact_details(key, options)

        doctor_details(key, options)

        admission_details(key, options, flag)

        appointment_details(key, options, flag)

        billing_details(key, options, flag)

        invoice_details(options, flag) if key == 'created_at'
      end

      options
    end

    def disable_opd_templates_durations
      [['30 Days', 30], ['45 Days', 45], ['60 Days', 60], ['90 Days', 90]]
    end

    private

    def patient_details(key, options)
      options['Patient'] = 'Dummy Patient' if ['fullname', 'recipient'].include?(key)
      options['Patient Type'] = 'Dummy Patient Type' if key == 'patient_type'
      options['Pat ID'] = 'PHD-PAT-103227' if key == 'patient_identifier'
      options['Age/Sex'] = '16 years / M' if key == 'calculate_age_gender'
      options['MR No.'] = 'MRN - 124' if key == 'mr_no'
      options['GSTIN'] = '0732322DGH' if key == 'gstin'
      options['Legal Name'] = 'Dummy Patient' if key == 'legal_name'
    end

    def patient_contact_details(key, options)
      options['Address'] = 'Address 1, Address 2, Bengaluru , KARNATAKA, 560102' if key == 'address'
      options['Contact'] = '9132132310' if key == 'mobilenumber'
    end

    def doctor_details(key, options)
      options['Doctor'] = 'Dummy Doctor' if ['consultant_name', 'doctor_name'].include?(key)
      options['Adm. Doctor'] = 'Dummy Doctor' if key == 'admitting_doctor'
      options['Referred By'] = 'Dummy Doctor' if key == 'referring_doctor'
    end

    def admission_details(key, options, flag)
      options['Adm. ID'] = 'PHD-OPD-206018' if key == 'display_id' && flag.include?('ipd')
      options['Adm. Dt'] = '16 Apr 19' if key == 'admission_date'
      options['Room Details'] = 'Ward- 12' if key == 'ward_bed_code'
    end

    def appointment_details(key, options, flag)
      options['Appt. ID'] = 'PHD-OPD-206018' if key == 'display_id' && flag.include?('opd')
      options['Appt. Dt'] = '16 Apr 19' if key == 'appointment_date'
    end

    def billing_details(key, options, flag)
      options['Bill Type'] = 'Cash' if key == 'bill_type'
      options['Bill No'] = 'PHD-INV-200388' if key == 'bill_number'
      options['Claim Processor'] = 'Processor' if key == 'claim_processor'
      options['Insurer'] = 'Insurer' if key == 'insurer'
      inventory_departments = ['pharmacy_invoices', 'optical_invoices']
      options['Billed On'] = '16 Apr 19, 05:18 PM' if key == 'date_time' && inventory_departments.include?(flag)
      options['Order No'] = 'PHD-ORD-200388' if key == 'order_no'
      options['Order On'] = '16 Apr 19, 05:18 PM' if key == 'order_on'
    end

    def invoice_details(options, flag)
      if ['opd_invoices', 'ipd_invoices'].include?(flag)
        options['Billed On'] = '16 Apr 19, 05:18 PM'
      else
        options['Note Dt'] = '16 Apr 19'
      end
    end
  end
end
