module Analytics::Admission
  class UpdateService
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
    def self.call(params, _current_user, _current_facility)
      admission = ::Admission.find_by(id: params)

      return unless admission.present?

      organisation_id = admission.organisation_id
      facility_id = admission.facility_id
      specialty_id = admission.specialty_id
      user_id = admission.user_id
      date = admission.admissiondate

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        general_analytics = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user_id,
          data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        )

        if general_analytics.blank?
          general_analytics = Analytics::GeneralOverview.new.tap do |g_overview|
            g_overview.organisation_id = organisation_id
            g_overview.facility_id = facility_id
            g_overview.specialty_id = specialty_id
            g_overview.user_id = user_id
            g_overview.data_type = type
            g_overview.data_type_range = hashed_data[type]
            g_overview.start_date = start_date
            g_overview.end_date = end_date
            g_overview.in_year = start_date.year
            g_overview.save
          end
        end

        if admission.is_deleted
          general_analytics.inc(admission_created_count: -1)
        else
          general_analytics.inc(admission_created_count: 1)
        end
      end
    end

    # calls only when admission_edit
    def self.update_admission_created_count(admission_id, past_facility_id, past_admission_date, past_specialty_id)
      admission = ::Admission.find_by(id: admission_id)
      organisation_id = admission.try(:organisation_id)
      facility_id = admission.try(:facility_id)
      specialty_id = admission.try(:specialty_id)
      user_id = admission.try(:user_id)

      date = admission.admissiondate
      old_date = past_admission_date

      hashed_data_old = {}
      hashed_data_old['day'] = old_date.yday
      hashed_data_old['week'] = old_date.cweek
      hashed_data_old['month'] = old_date.month
      hashed_data_old['year'] = old_date.year

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        # decrementing existing admission_created_count
        past_admission_record = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: past_facility_id, specialty_id: past_specialty_id,
          user_id: user_id, data_type: type, data_type_range: hashed_data_old[type], in_year: start_date.year
        )

        if past_admission_record && past_admission_record.admission_created_count > 0
          past_admission_record.inc(admission_created_count: -1)
        end
        # incementing updated admission_created_count
        new_admission_record = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          user_id: user_id, data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        )

        new_admission_record ||= Analytics::GeneralOverview.new.tap do |g_overview|
          g_overview.organisation_id = organisation_id
          g_overview.facility_id = facility_id
          g_overview.specialty_id = specialty_id
          g_overview.user_id = user_id
          g_overview.data_type = type
          g_overview.data_type_range = hashed_data[type]
          g_overview.start_date = start_date
          g_overview.end_date = end_date
          g_overview.in_year = start_date.year
          g_overview.save
        end
        new_admission_record.inc(admission_created_count: 1) if new_admission_record.present?
      end
    end
  end
end
