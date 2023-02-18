module Analytics::PartialData
  class CounsellorOperationalData
    def self.counsellor_procedures_converted(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = fetch_from_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      user_role_id = 499992366
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      total_procedures = get_clinical_data(from_date, to_date, group_by, user_role_id, organisation_id, 'procedures', facility_id, specialty_id, user_id, match_with_this2)

      procedure_labels = []
      @procedures_converted_count = []
      @procedures_not_converted_count = []

      if group_by == '$dayOfMonth'
        from_date.upto(to_date).to_a.each_with_index do |date, _i|
          procedure_labels << date.strftime('%a')
          record_data = total_procedures.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

          get_counsellor_clinical_data(record_data, 'procedures')
        end

      elsif group_by == '$week'
        total_procedures = total_procedures.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
        day_today = Date.today.strftime('%A').to_s.downcase.to_sym
        week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

        week_days.each_with_index do |date, _indx|
          record_data = total_procedures.find { |hash| hash['_id'].to_i == date.cweek }
          procedure_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

          get_counsellor_clinical_data(record_data, 'procedures')
        end

      elsif group_by == '$month'
        months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }
        months.each_with_index do |month, _indx|
          record_data = total_procedures.find { |hash| hash['_id'].to_i == Date.parse(month).month }
          procedure_labels << month

          get_counsellor_clinical_data(record_data, 'procedures')
        end
      elsif group_by == '$year'
        uniq_dates = from_date.upto(to_date).to_a.map(&:year).uniq
        uniq_dates.each_with_index do |year, _indx|
          record_data = total_procedures.find { |hash| hash['_id'].to_i == year }
          procedure_labels << year
          get_counsellor_clinical_data(record_data, 'procedures')
        end
      end

      [procedure_labels, @procedures_converted_count, @procedures_not_converted_count, group_by]
    end

    def self.counsellor_ophthal_investigations_converted(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = fetch_from_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      user_role_id = 499992366
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      total_ophthal_investigations = get_clinical_data(from_date, to_date, group_by, user_role_id, organisation_id, 'ophthal_investigations', facility_id, specialty_id, user_id, match_with_this2)

      @ophthal_investigations_labels = []
      @ophthal_investigations_converted_count = []
      @ophthal_investigations_not_converted_count = []

      if group_by == '$dayOfMonth'
        from_date.upto(to_date).to_a.each_with_index do |date, _i|
          @ophthal_investigations_labels << date.strftime('%a')
          record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

          get_counsellor_clinical_data(record_data, 'ophthal_investigations')
        end

      elsif group_by == '$week'
        total_ophthal_investigations = total_ophthal_investigations.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
        day_today = Date.today.strftime('%A').to_s.downcase.to_sym
        week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

        week_days.each_with_index do |date, _indx|
          record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == date.cweek }
          @ophthal_investigations_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

          get_counsellor_clinical_data(record_data, 'ophthal_investigations')
        end

      elsif group_by == '$month'
        months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }

        months.each_with_index do |month, _indx|
          record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == Date.parse(month).month }
          @ophthal_investigations_labels << month

          get_counsellor_clinical_data(record_data, 'ophthal_investigations')
        end
      elsif group_by == '$year'
        uniq_dates = from_date.upto(to_date).to_a.map(&:year).uniq
        uniq_dates.each_with_index do |year, _indx|
          record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == year }
          @ophthal_investigations_labels << year
          get_counsellor_clinical_data(record_data, 'ophthal_investigations')
        end
      end

      [@ophthal_investigations_labels, @ophthal_investigations_converted_count, @ophthal_investigations_not_converted_count, group_by]
    end

    def self.counsellor_laboratory_investigations_converted(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = fetch_from_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      user_role_id = 499992366
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      total_laboratory_investigations = get_clinical_data(from_date, to_date, group_by, user_role_id, organisation_id, 'laboratory_investigations', facility_id, specialty_id, user_id, match_with_this2)

      @laboratory_investigations_labels = []
      @laboratory_investigations_converted_count = []
      @laboratory_investigations_not_converted_count = []

      if group_by == '$dayOfMonth'
        from_date.upto(to_date).to_a.each_with_index do |date, _i|
          @laboratory_investigations_labels << date.strftime('%a')
          record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

          get_counsellor_clinical_data(record_data, 'laboratory_investigations')
        end

      elsif group_by == '$week'
        total_laboratory_investigations = total_laboratory_investigations.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
        day_today = Date.today.strftime('%A').to_s.downcase.to_sym
        week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

        week_days.each_with_index do |date, _indx|
          record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == date.cweek }
          @laboratory_investigations_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

          get_counsellor_clinical_data(record_data, 'laboratory_investigations')
        end

      elsif group_by == '$month'
        months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }

        months.each_with_index do |month, _indx|
          record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == Date.parse(month).month }
          @laboratory_investigations_labels << month

          get_counsellor_clinical_data(record_data, 'laboratory_investigations')
        end
      elsif group_by == '$year'
        uniq_dates = from_date.upto(to_date).to_a.map(&:year).uniq
        uniq_dates.each_with_index do |year, _indx|
          record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == year }
          @laboratory_investigations_labels << year

          get_counsellor_clinical_data(record_data, 'laboratory_investigations')
        end
      end

      [@laboratory_investigations_labels, @laboratory_investigations_converted_count, @laboratory_investigations_not_converted_count, group_by]
    end

    def self.counsellor_radiology_investigations_converted(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = fetch_from_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      user_role_id = 499992366
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      total_radiology_investigations = get_clinical_data(from_date, to_date, group_by, user_role_id, organisation_id, 'radiology_investigations', facility_id, specialty_id, user_id, match_with_this2)

      @radiology_investigations_labels = []
      @radiology_investigations_converted_count = []
      @radiology_investigations_not_converted_count = []

      if group_by == '$dayOfMonth'
        from_date.upto(to_date).to_a.each_with_index do |date, _i|
          @radiology_investigations_labels << date.strftime('%a')
          record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

          get_counsellor_clinical_data(record_data, 'radiology_investigations')
        end

      elsif group_by == '$week'
        total_radiology_investigations = total_radiology_investigations.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
        day_today = Date.today.strftime('%A').to_s.downcase.to_sym
        week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

        week_days.each_with_index do |date, _indx|
          record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == date.cweek }
          @radiology_investigations_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

          get_counsellor_clinical_data(record_data, 'radiology_investigations')
        end

      elsif group_by == '$month'
        months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }

        months.each_with_index do |month, _indx|
          record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == Date.parse(month).month }
          @radiology_investigations_labels << month

          get_counsellor_clinical_data(record_data, 'radiology_investigations')
        end
      elsif group_by == '$year'
        uniq_dates = from_date.upto(to_date).to_a.map(&:year).uniq

        uniq_dates.each_with_index do |year, _indx|
          record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == year }
          @radiology_investigations_labels << year

          get_counsellor_clinical_data(record_data, 'radiology_investigations')
        end
      end

      [@radiology_investigations_labels, @radiology_investigations_converted_count, @radiology_investigations_not_converted_count, group_by]
    end

    private

    def self.filter_group_by(from_date, to_date, label_on)
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

    def self.get_clinical_data(_from_date, _to_date, group_by, role_id, organisation_id, find_from, facility_id = 'all', specialty_id = 'all', user_id = '', match_with_this2)
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
      user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id,
        'user_role_ids' => { '$in' => [role_id, '$user_role_ids'] }
      }

      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('user_id') unless user_id.present?

      found_records = Analytics::ClinicalOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$match' => { '$or' => match_with_this2 }
          },
          {
            '$project' =>
            { 'start_date' => 1, "total_#{find_from}_counselled" => 1, "total_#{find_from}_converted" => 1 }
          },
          { '$group' =>
            { '_id' => { group_by.to_s => '$start_date' },
              "total_#{find_from}_counselled" => { '$sum' => "$total_#{find_from}_counselled" },
              "total_#{find_from}_converted" => { '$sum' => "$total_#{find_from}_converted" } } }
        ]
      ).to_a

      found_records
    end

    def self.get_counsellor_clinical_data(record_data, find_from)
      if record_data
        # eval("@#{find_from}_total_count") << (record_data["total_#{find_from}_counselled"].to_i)
        eval("@#{find_from}_converted_count") << record_data["total_#{find_from}_converted"].to_i
        eval("@#{find_from}_not_converted_count") << record_data["total_#{find_from}_counselled"].to_i - record_data["total_#{find_from}_converted"].to_i

        eval("@#{find_from}_advised_count") << record_data["total_#{find_from}_advised"].to_i if find_from == 'diagnoses'
      else
        # eval("@#{find_from}_total_count") << 0
        eval("@#{find_from}_converted_count") << 0
        eval("@#{find_from}_not_converted_count") << 0

        eval("@#{find_from}_advised_count") << 0 if find_from == 'diagnoses'
      end
    end

    def self.fetch_from_params_hash(params_hash = {})
      organisation_id = params_hash['organisation_id']
      facility_id = params_hash['facility_id']
      specialty_id = params_hash['specialty_id']
      user_id = params_hash['user_id']
      from_date = params_hash['analytics_from_date']
      to_date = params_hash['analytics_to_date']

      [organisation_id, facility_id, specialty_id, user_id, from_date, to_date]
    end
  end
end
