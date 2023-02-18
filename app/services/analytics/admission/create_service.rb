module Analytics::Admission
  class CreateService
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
    def self.call(params, _current_user_id, _current_facility_id, state = 'admission')
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

        if state == 'admission'
          general_analytics.inc(admission_created_count: 1)
        elsif state == 'admitted'
          general_analytics.inc(admission_admitted_count: 1)
        elsif state == 'not_admitted'
          general_analytics.inc(admission_admitted_count: -1)
        end
      end
    end
  end
end
