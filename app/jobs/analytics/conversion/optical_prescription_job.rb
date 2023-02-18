class Analytics::Conversion::OpticalPrescriptionJob < ActiveJob::Base
  queue_as :urgent
  DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
  def perform(prescription_id, _current_user_id, mode, prev_state = '')
    if ['Clinical', 'Optical', 'ClinicalTrue', 'ClinicalFalse'].include?(mode)
      prescription = PatientOpticalPrescription.find_by(id: prescription_id)
    end

    return unless prescription.present?

    user = User.find_by(id: prescription.consultant_id)
    date = prescription.created_at.to_date
    organisation_id = user.organisation_id
    facility_id = prescription.facility_id
    specialty_id = prescription.specalityid

    hashed_data = {}
    hashed_data['day'] = date.yday
    hashed_data['week'] = date.cweek
    hashed_data['month'] = date.month
    hashed_data['year'] = date.year

    if prescription.converted.nil?
      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        conversion = Analytics::Conversion::OpticalPrescription.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user.id,
          data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        ) || Analytics::Conversion::OpticalPrescription.new

        if conversion.new_record?
          conversion.organisation_id = organisation_id
          conversion.facility_id = facility_id
          conversion.specialty_id = specialty_id
          conversion.department_id = '50121007'
          conversion.user_id = user.id
          conversion.add_to_set(role_ids: user.role_ids)
          conversion.start_date = start_date
          conversion.end_date = end_date
          conversion.data_type = type
          conversion.data_type_range = hashed_data[type]
          conversion.in_year = start_date.year
        end
        conversion.inc(total_prescription_advised_count: 1)
        conversion.inc(total_prescription_count: 1)
        conversion.save!
      end
    else
      # if prescription.converted == 'true'
      if prescription.converted == true
        DATA_CREATION_ARRAY.each_with_index do |type, _indx|
          start_date, _end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
          doctor_conversion = Analytics::Conversion::OpticalPrescription.find_by(
            organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user.id,
            data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
          )
          conversion = Analytics::Conversion::OpticalPrescription.find_by(
            organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, data_type: type,
            data_type_range: hashed_data[type], department_id: '50121007', in_year: start_date.year
          )
          invoice = Invoice::Inventories::Department::OpticalInvoice.find_by(prescription_id: prescription.id)

          if conversion.present?
            conversion.inc(total_prescription_converted_count: 1)
            if invoice.present?
              conversion.inc(total_prescription_invoice_amount: invoice.try(:total))
              conversion.inc(total_invoice_amount: invoice.try(:total))
            end
          end
          doctor_conversion.inc(converted_prescription_count: 1) if doctor_conversion.present?
        end
      # elsif prescription.converted == 'false'
      elsif prescription.converted == false
        unless prev_state.nil?
          DATA_CREATION_ARRAY.each_with_index do |type, _indx|
            start_date, _end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
            doctor_conversion = Analytics::Conversion::OpticalPrescription.find_by(
              organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user.id,
              data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
            )
            conversion = Analytics::Conversion::OpticalPrescription.find_by(
              organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
              department_id: '50121007', data_type: type, data_type_range: hashed_data[type],
              in_year: start_date.year
            )
            invoice = Invoice::Inventories::Department::OpticalInvoice.find_by(prescription_id: prescription.id)

            if conversion.present?
              conversion.inc(total_prescription_converted_count: -1)
              if invoice.present?
                conversion.inc(total_prescription_invoice_amount: -invoice.try(:total))
                conversion.inc(total_invoice_amount: -invoice.try(:total))
              end
            end
            doctor_conversion.inc(converted_prescription_count: -1) if doctor_conversion.present?
          end
        end
      end
    end
  end
end
