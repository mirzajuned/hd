module Analytics::Patient
  class CreateService
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
    def self.create_patient_type_record(params)
      params = JSON.parse(params)
      patient_id = params['patient_id']
      organisation_id = params['organisation_id']
      patient = ::Patient.find_by(id: patient_id)

      if patient.patient_type_id.present?
        @date = patient.try(:reg_date)
        hashed_data = {}
        hashed_data['day'] = @date.try(:yday)
        hashed_data['week'] = @date.try(:cweek)
        hashed_data['month'] = @date.try(:month)
        hashed_data['year'] = @date.try(:year)
        patient_type = ::PatientType.find_by(id: patient.patient_type_id)
        DATA_CREATION_ARRAY.each_with_index do |type, _indx|
          start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(@date, type)
          analytics_patient_type = ::Analytics::PatientTypeOverview.find_by(
            organisation_id: organisation_id, data_type: type, data_type_range: hashed_data[type],
            patient_type_id: patient.patient_type_id, in_year: start_date.try(:year)
          )

          analytics_patient_type ||= Analytics::PatientTypeOverview.new.tap do |pat_type|
            pat_type.organisation_id = organisation_id
            pat_type.patient_type_id = patient.patient_type_id
            pat_type.patient_type_label = patient_type.label
            pat_type.start_date = start_date
            pat_type.end_date = end_date
            pat_type.data_type = type
            pat_type.data_type_range = hashed_data[type]
            pat_type.in_year = start_date.try(:year)
            pat_type.save
          end
          analytics_patient_type.inc(patient_type_count: 1)
        end
      end
    end

    def self.create_referral_type_record(params, facility_id)
      params = JSON.parse(params)
      appointment_id = params['appointment_id']
      patient_referral_id = params['patient_referral_id']

      appointment = ::Appointment.find_by(id: appointment_id)
      facility_id = appointment.try(:facility_id) || facility_id
      specialty_id = appointment.try(:specialty_id)
      organisation_id = appointment.try(:organisation_id)

      pat_referral_type = ::PatientReferralType.find_by(id: patient_referral_id)
      referral_type = ::ReferralType.find_by(id: pat_referral_type.try(:referral_type_id))

      @date = appointment.try(:appointmentdate)
      hashed_data = {}
      hashed_data['day'] = @date.try(:yday)
      hashed_data['week'] = @date.try(:cweek)
      hashed_data['month'] = @date.try(:month)
      hashed_data['year'] = @date.try(:year)

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(@date, type)
        analytics_referral_type = ::Analytics::ReferralTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, data_type: type,
          data_type_range: hashed_data[type], referral_type_id: pat_referral_type.referral_type_id,
          in_year: start_date.try(:year)
        )

        analytics_referral_type ||= Analytics::ReferralTypeOverview.new.tap do |ref_type|
          ref_type.organisation_id = organisation_id
          ref_type.facility_id = facility_id
          ref_type.specialty_id = specialty_id
          ref_type.referral_type_id = pat_referral_type.referral_type_id
          ref_type.referral_type_label = referral_type.name
          ref_type.data_type = type
          ref_type.data_type_range = hashed_data[type]
          ref_type.start_date = start_date
          ref_type.end_date = end_date
          ref_type.in_year = start_date.try(:year)
          ref_type.save
        end
        analytics_referral_type.inc(referral_type_count: 1)
      end
    end
  end
end
