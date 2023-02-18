module Analytics
  module AnalyticsDate
    class QueryGenerator
      def self.year_query_creation(years_data)
        year_data_query = Hash.new
        if years_data.present?
          year_array = years_data.map { |row| row[:year] }.uniq
          year_data_query = {
            "data_type" => 'year',
            "data_type_range" => { "$in" => year_array },
            "in_year" => { "$in" => year_array }
          }
        end
        return year_data_query
      end

      def self.month_query_creation(months_data)
        month_data_query = Hash.new
        if months_data.present?

          month_array      = months_data.map { |row| row[:month] }
          year_array       = months_data.pluck(:year).uniq
          # week_array     = start_date_month.upto(end_date_month).to_a.uniq.map{|a| a.cweek}.uniq
          month_data_query = {
            "data_type" => 'month',
            "data_type_range" => { "$in" => month_array },
            "in_year" => { "$in" => year_array }
          }
        end
        return month_data_query
      end

      def self.week_query_creation(weeks_data)
        weeks_data_query = Hash.new
        if weeks_data.present?

          weeks_array     = weeks_data.map { |row| row[:week] }
          year_array      = weeks_data.pluck(:year).uniq
          weeks_data_query = {
            "data_type" => 'week',
            "data_type_range" => { "$in" => weeks_array },
            "in_year" => { "$in" => year_array }
          }
        end
        return weeks_data_query
      end

      def self.day_query_creation(days_data)
        days_data_query = Hash.new
        if days_data.present?

          days_array     = days_data.map { |row| row[:day] }
          year_array     = days_data.pluck(:year).uniq
          days_data_query = {
            "data_type" => 'day',
            "data_type_range" => { "$in" => days_array },
            "in_year" => { "$in" => year_array }
          }
        end
        return days_data_query
      end

      def self.start_end_date(date, type)
        case type
        when 'day'
          start_date = date.try(:beginning_of_day)
          end_date = date.try(:end_of_day)
        when 'week'
          start_date = date.try(:beginning_of_week)
          end_date   = date.try(:end_of_week)
        when 'month'
          start_date = date.try(:beginning_of_month)
          end_date   = date.try(:end_of_month)
        when 'year'
          start_date = date.try(:beginning_of_year)
          end_date   = date.try(:end_of_year)
        end
        return start_date, end_date
      end

      def self.query_array_builder(to_date, from_date)
        days = (Date.parse(to_date) - Date.parse(from_date)).to_i
        if days <= 7
          date_breakup = DateBreakup::Range.between(from_date, to_date).get_days
          label_on = "days"
        elsif days <= 30
          date_breakup = DateBreakup::Range.between(from_date, to_date).get_weeks
          label_on = "weeks"
        elsif days <= 365
          date_breakup = DateBreakup::Range.between(from_date, to_date).get_months
          label_on = "months"
        else
          date_breakup = DateBreakup::Range.between(from_date, to_date).get_years
          label_on = "years"
        end
        days_data = date_breakup[:days]
        weeks_data = date_breakup[:weeks]
        months_data = date_breakup[:months]
        years_data = date_breakup[:years]

        data_query = Array.new
        years_data_query = year_query_creation(years_data)
        month_data_query = month_query_creation(months_data)
        weeks_data_query = week_query_creation(weeks_data)
        days_data_query  = day_query_creation(days_data)

        data_query.push(days_data_query, weeks_data_query, month_data_query, years_data_query)

        return data_query, label_on
      end
    end
  end
end
