module Analytics::Patient
  class UpdateService
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
    # method calls from patient_update service when pat_type changes
    def self.update_patient_type_record(params)
      params = JSON.parse(params)

      organisation_id = params['organisation_id']
      patient_id      = params['patient_id']
      past_patient_type_id = params['past_patient_type_id']
      past_date            = (params['past_date'].present?) ? Date.parse(params['past_date']) : ''
      patient = ::Patient.find_by(id: patient_id)

      hashed_data_old = {}
      hashed_data_old['day'] = past_date.try(:yday)
      hashed_data_old['week'] = past_date.try(:cweek)
      hashed_data_old['month'] = past_date.try(:month)
      hashed_data_old['year'] = past_date.try(:year)

      @date = patient.try(:reg_date)
      hashed_data = {}
      hashed_data['day'] = @date.try(:yday)
      hashed_data['week'] = @date.try(:cweek)
      hashed_data['month'] = @date.try(:month)
      hashed_data['year'] = @date.try(:year)

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(@date, type)
        past_pat_type_record = Analytics::PatientTypeOverview.find_by(
          organisation_id: organisation_id, data_type: type, data_type_range: hashed_data_old[type],
          patient_type_id: past_patient_type_id, in_year: start_date.try(:year)
        )

        if past_pat_type_record.present? && past_pat_type_record.try(:patient_type_count) > 0
          past_pat_type_record.inc(patient_type_count: -1)
        end

        next unless patient.patient_type_id.present?

        patient_type = ::PatientType.find_by(
          id: patient.patient_type_id
        )
        analytics_patient_type = Analytics::PatientTypeOverview.find_by(
          organisation_id: organisation_id, data_type: type, data_type_range: hashed_data[type],
          patient_type_id: patient.patient_type_id, in_year: start_date.try(:year)
        )

        analytics_patient_type ||= Analytics::PatientTypeOverview.new.tap do |pat_type|
          pat_type.organisation_id = organisation_id
          pat_type.patient_type_id = patient.patient_type_id
          pat_type.patient_type_label = patient_type.label
          pat_type.start_date = start_date
          pat_type.end_date   = end_date
          pat_type.data_type = type
          pat_type.data_type_range = hashed_data[type]
          pat_type.in_year = start_date.try(:year)
          pat_type.save
        end

        analytics_patient_type.inc(patient_type_count: 1)
      end
    end

    def self.update_referral_type_record(params, facility_id)
      params = JSON.parse(params)

      appointment = ::Appointment.find_by(id: params['appointment_id'])
      organisation_id = appointment.organisation_id
      specialty_id = appointment.specialty_id
      pat_referral_type = PatientReferralType.find_by(appointment_id: appointment.id)
      referral_type = ReferralType.find_by(id: pat_referral_type.try(:referral_type_id))

      past_date = Date.parse(params['before_appointment_date'])
      hashed_data_old = {}
      hashed_data_old['day'] = past_date.try(:yday)
      hashed_data_old['week'] = past_date.try(:cweek)
      hashed_data_old['month'] = past_date.try(:month)
      hashed_data_old['year'] = past_date.try(:year)

      @date = appointment.appointmentdate
      hashed_data = {}
      hashed_data['day'] = @date.try(:yday)
      hashed_data['week'] = @date.try(:cweek)
      hashed_data['month'] = @date.try(:month)
      hashed_data['year'] = @date.try(:year)

      if pat_referral_type.present?
        DATA_CREATION_ARRAY.each_with_index do |type, _indx|
          start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(@date, type)
          past_ref_type = Analytics::ReferralTypeOverview.find_by(
            organisation_id: organisation_id, facility_id: params['before_facility_id'], specialty_id: specialty_id,
            data_type: type, referral_type_id: params['before_referral_type_id'],
            data_type_range: hashed_data_old[type], in_year: start_date.try(:year)
          )

          if past_ref_type.present? && past_ref_type.try(:referral_type_count) > 0
            past_ref_type.inc(referral_type_count: -1)
          end

          next unless pat_referral_type.is_deleted == false

          analytics_ref_type = Analytics::ReferralTypeOverview.find_by(
            organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
            data_type: type, referral_type_id: pat_referral_type.referral_type_id,
            data_type_range: hashed_data[type], in_year: start_date.try(:year)
          )

          analytics_ref_type ||= Analytics::ReferralTypeOverview.new.tap do |ref_type|
            ref_type.organisation_id = organisation_id
            ref_type.facility_id = facility_id
            ref_type.specialty_id = specialty_id
            ref_type.referral_type_id = pat_referral_type.referral_type_id
            ref_type.referral_type_label = referral_type.name
            ref_type.start_date = start_date
            ref_type.end_date   = end_date
            ref_type.data_type = type
            ref_type.data_type_range = hashed_data[type]
            ref_type.in_year = start_date.try(:year)
            ref_type.save
          end

          analytics_ref_type.inc(referral_type_count: 1)
        end

      end
    end

    # case when appointment got cancelled
    def self.decrement_referral_type_count(appointment_id)
      appointment = Appointment.find_by(id: appointment_id)
      organisation_id = appointment.organisation_id
      facility_id = appointment.facility_id
      specialty_id = appointment.specialty_id
      pat_referral_type = PatientReferralType.find_by(appointment_id: appointment.id)

      @date = appointment.appointmentdate
      hashed_data = {}
      hashed_data['day'] = @date.yday
      hashed_data['week'] = @date.cweek
      hashed_data['month'] = @date.month
      hashed_data['year'] = @date.year

      if pat_referral_type.present? && pat_referral_type.is_deleted == false
        DATA_CREATION_ARRAY.each_with_index do |type, _indx|
          analytics_ref_type = Analytics::ReferralTypeOverview.find_by(
            organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, data_type: type,
            data_type_range: hashed_data[type], referral_type_id: pat_referral_type.referral_type_id,
            in_year: @date.year
          )

          if analytics_ref_type.present? && analytics_ref_type.try(:referral_type_count) > 0
            analytics_ref_type.inc(referral_type_count: -1)
          end
        end
      end
    end
  end
end
