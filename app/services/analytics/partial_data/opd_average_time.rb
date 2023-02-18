module Analytics::PartialData
  class OpdAverageTime
    class << self
      def call(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        # if from_date == to_date
        #   from_date = from_date - 7.days
        # end
        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id
        }

        facility_count = if facility_id == 'all'
                           Facility.where(organisation_id: organisation_id, is_active: true).count
                         else
                           1
                         end

        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        weekly_opd_average_time_grp = Analytics::FacilityAverageTime.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$group' => {
                '_id' => { group_by.to_s => '$start_date' },
                'average_time' => { '$sum' => '$average_time' },
                'total_patient_seen' => { '$sum' => '$total_patient_seen' }
              }
            }

          ]
        ).to_a

        opd_chart_labels = []
        opd_average_time = []
        weekly_opd_average_time_grp = weekly_opd_average_time_grp.sort_by { |a| a['_id'] }
        if group_by == '$dayOfMonth'
          weekly_opd_average_time_grp = from_date.upto(to_date).to_a.map { |date| (weekly_opd_average_time_grp.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
          from_date.upto(to_date).to_a.each_with_index do |date, indx|
            date_number = date.strftime('%d').to_i
            opd_chart_labels.push(date.strftime('%a'))
            data_at_position = weekly_opd_average_time_grp[indx]

            if data_at_position.present? && (date_number == data_at_position['_id'])
              time = data_at_position['average_time'].to_f
              pat_seen = data_at_position['total_patient_seen']
              pat_seen = 1 if pat_seen == 0
              avg_time = (time / 3600)
              opd_average_time.push(avg_time)
            else
              opd_average_time.push(0)
            end
          end
        elsif group_by == '$week'
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")
          uniq_dates = from_date.upto(to_date).to_a.map(&:cweek).uniq
          weekly_opd_average_time_grp = uniq_dates.map { |week| (weekly_opd_average_time_grp.find { |set| set['_id'].to_i == week.to_i }) || {} }
          weekly_opd_average_time_grp = weekly_opd_average_time_grp.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
          week_days.each_with_index do |date, _indx|
            data_at_position = weekly_opd_average_time_grp.find { |hash| hash['_id'].to_i == date.cweek }
            opd_chart_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"
            if data_at_position.present?
              time = data_at_position['average_time'].to_f
              pat_seen = data_at_position['total_patient_seen']
              pat_seen = 1 if pat_seen == 0
              avg_time = (time / 3600)
              opd_average_time.push(avg_time)
            else
              opd_average_time.push(0)
            end
          end
        elsif group_by == '$month'
          uniq_dates = from_date.upto(to_date).to_a.map(&:month).uniq
          opd_chart_labels = uniq_dates.map { |m| Date::MONTHNAMES[m] }
          weekly_opd_average_time_grp = uniq_dates.map { |month| (weekly_opd_average_time_grp.find { |set| set['_id'].to_i == month.to_i }) || {} }
          uniq_dates.each_with_index do |month, indx|
            data_at_position = weekly_opd_average_time_grp[indx]
            month_number = month
            if data_at_position.present? && (month_number == data_at_position['_id'])
              time = data_at_position['average_time'].to_f
              pat_seen = data_at_position['total_patient_seen']
              pat_seen = 1 if pat_seen == 0
              avg_time = (time / 3600)
              opd_average_time.push(avg_time)
            else
              opd_average_time.push(0)
            end
          end
        elsif group_by == '$year'
          uniq_dates = from_date.upto(to_date).to_a.map(&:year).uniq
          opd_chart_labels = uniq_dates
          weekly_opd_average_time_grp = uniq_dates.map { |month| (weekly_opd_average_time_grp.find { |set| set['_id'].to_i == month.to_i }) || {} }
          uniq_dates.each_with_index do |year, indx|
            data_at_position = weekly_opd_average_time_grp[indx]
            year_number = year
            if data_at_position.present? && (year_number == data_at_position['_id'])
              time = data_at_position['average_time'].to_f
              pat_seen = data_at_position['total_patient_seen']
              pat_seen = 1 if pat_seen == 0
              avg_time = (time / 3600)
              opd_average_time.push(avg_time)
            else
              opd_average_time.push(0)
            end
          end
        end
        opd_average_time = opd_average_time.map { |s| (s.to_f / facility_count).round(2) }
        [opd_chart_labels, opd_average_time]
      end

      private

      def fetch_params_hash(params_hash = {})
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']

        [organisation_id, facility_id, specialty_id, from_date, to_date]
      end

      def filter_group_by(from_date, to_date, label_on)
        from_date = Date.parse(from_date)
        to_date = Date.parse(to_date)
        group_by = case label_on
                   when 'days'
                     '$dayOfMonth'
                   when 'weeks'
                     '$week'
                   when 'months'
                     '$month'
                   else
                     '$year'
                   end

        [group_by, from_date, to_date]
      end
    end
  end
end
