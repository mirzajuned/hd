module Analytics::PatientsFeedback
  class CreateFeedback
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
    def self.call(params, facility_id)
      payload = JSON.parse(params)
      facility = Facility.find_by(id: facility_id)
      organisation_id = facility.try(:organisation_id) if facility.present?

      @date = Date.current
      hashed_data = {}
      hashed_data['day'] = @date.yday
      hashed_data['week'] = @date.cweek
      hashed_data['month'] = @date.month
      hashed_data['year'] = @date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(@date, type)
        feedback_count = Analytics::PatientFeedback.find_by(
          organisation_id: organisation_id, facility_id: facility.id, data_type: type,
          data_type_range: hashed_data[type], in_year: start_date.year
        )

        if feedback_count.blank?
          feedback_count = Analytics::PatientFeedback.new(organisation_id: organisation_id, facility_id: facility.id,
                                                          data_type: type, data_type_range: hashed_data[type])
        end

        if feedback_count.new_record?
          feedback_count.usability = payload['usability'].to_f
          feedback_count.waiting = payload['waiting'].to_f
          feedback_count.cleanliness = payload['cleanliness'].to_f
          feedback_count.overallcare = payload['overallcare'].to_f
          feedback_count.recommendation = payload['recommendation'].to_f
          feedback_count.average_rating = payload['average_rating'].to_f

          feedback_count.total_count += 1
          feedback_count.start_date = start_date
          feedback_count.end_date = end_date
          feedback_count.data_type = type
          feedback_count.data_type_range = hashed_data[type]
          feedback_count.in_year = start_date.year
        else
          feedback_count.usability += payload['usability'].to_f
          feedback_count.waiting += payload['waiting'].to_f
          feedback_count.cleanliness += payload['cleanliness'].to_f
          feedback_count.overallcare += payload['overallcare'].to_f
          feedback_count.recommendation += payload['recommendation'].to_f
          feedback_count.average_rating += payload['average_rating'].to_f

          feedback_count.total_count += 1
        end
        feedback_count.save
      end
    end
  end
end
