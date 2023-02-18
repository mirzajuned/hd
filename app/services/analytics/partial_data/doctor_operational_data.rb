module Analytics::PartialData
  class DoctorOperationalData
    class << self
      def doctor_average_time(params_hash)
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        doctor_role_id = 'doctor'
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id,
          'role' => doctor_role_id
        }

        match_with_this.except!('user_id') unless user_id.present?
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        average_time_taken = Analytics::UserAverageTime.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } }, {
              '$project' => {
                'total_patient_seen' => 1,
                'total_time_given' => 1,
                'opd_new_patient_count' => 1,
                'opd_old_patient_count' => 1,
                'avg_time_given' => 1,
                'start_date' => 1
              }
            },
            {
              '$group' => {
                '_id' => { group_by.to_s => '$start_date' },
                'total_patient_seen' => { '$sum' => '$total_patient_seen' },
                'total_time_given' => { '$sum' => '$total_time_given' },
                'total_avg_time_given' => { '$sum' => '$avg_time_given' }
              }
            }

          ]
        ).to_a

        average_time_taken = average_time_taken.sort_by { |a| a['_id'] }

        doctor_name_labels = []
        total_patient_seen = []
        total_time_given   = []
        total_avg_time_given = []

        if group_by == '$dayOfMonth'
          average_time_taken = from_date.upto(to_date).to_a.map { |date| (average_time_taken.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
          from_date.upto(to_date).to_a.each_with_index do |date, indx|
            date_number = date.strftime('%d').to_i
            doctor_name_labels.push(date.strftime('%a'))
            data_at_position = average_time_taken[indx]
            if data_at_position.present? && (date_number == data_at_position['_id'])
              total_patient_seen <<  data_at_position['total_patient_seen']
              total_time_given   <<  (data_at_position['total_time_given'].to_f / 3600)
              total_avg_time_given << ((data_at_position['total_avg_time_given'].to_f / 3600))
            else
              total_patient_seen << 0
              total_time_given << 0
              total_avg_time_given << 0
            end
          end

        elsif group_by == '$week'
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")
          uniq_dates = from_date.upto(to_date).to_a.map(&:cweek).uniq
          average_time_taken = uniq_dates.map { |week| (average_time_taken.find { |set| set['_id'].to_i == week.to_i }) || {} }
          average_time_taken = average_time_taken.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
          week_days.each_with_index do |date, _indx|
            data_at_position = average_time_taken.find { |hash| hash['_id'].to_i == date.cweek }
            doctor_name_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"
            if data_at_position.present?
              total_patient_seen <<  data_at_position['total_patient_seen']
              total_time_given   <<  (data_at_position['total_time_given'].to_f / 3600)
              total_avg_time_given << ((data_at_position['total_avg_time_given'].to_f / 3600))
            else
              total_patient_seen << 0
              total_time_given << 0
              total_avg_time_given << 0
            end
          end

        elsif group_by == '$month'
          uniq_dates = from_date.upto(to_date).to_a.map(&:month).uniq
          doctor_name_labels = uniq_dates.map { |m| Date::MONTHNAMES[m] }
          average_time_taken = uniq_dates.map { |month| (average_time_taken.find { |set| set['_id'].to_i == month.to_i }) || {} }
          uniq_dates.each_with_index do |month, indx|
            data_at_position = average_time_taken[indx]
            month_number = month
            if data_at_position.present? && (month_number == data_at_position['_id'])
              total_patient_seen <<  data_at_position['total_patient_seen']
              total_time_given   <<  (data_at_position['total_time_given'].to_f / 3600)
              total_avg_time_given << ((data_at_position['total_avg_time_given'].to_f / 3600))
            else
              total_patient_seen << 0
              total_time_given << 0
              total_avg_time_given << 0
            end
          end
        elsif group_by == '$year'
          uniq_dates = from_date.upto(to_date).to_a.map(&:year).uniq
          doctor_name_labels = uniq_dates
          average_time_taken = uniq_dates.map { |year| (average_time_taken.find { |set| set['_id'].to_i == year }) || {} }
          uniq_dates.each_with_index do |year, indx|
            data_at_position = average_time_taken[indx]
            year_number = year
            if data_at_position.present? && (year_number == data_at_position['_id'])
              total_patient_seen <<  data_at_position['total_patient_seen']
              total_time_given   <<  (data_at_position['total_time_given'].to_f / 3600)
              total_avg_time_given << ((data_at_position['total_avg_time_given'].to_f / 3600))
            else
              total_patient_seen << 0
              total_time_given << 0
              total_avg_time_given << 0
            end
          end
        end

        [doctor_name_labels, total_patient_seen, total_time_given.map { |d| d.round(2) }, total_avg_time_given.map { |d| d.round(2) }]
      end

      def doctor_converted_pharmacy(params_hash = {})
        label_on = params_hash['label_on']
        user_id = BSON::ObjectId(params_hash['user_id']) if params_hash['user_id'].present?
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        doctor_role_id = 158965000
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        # if from_date == to_date
        #   from_date = from_date - 7.days
        # end
        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id,
          'role_ids' => { '$in' => [doctor_role_id, '$role_ids'] }
        }
        match_with_this.except!('user_id') unless user_id.present?
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        doctor_converted_pharmacy = Analytics::Conversion::PharmacyPrescription.collection.aggregate(
          [
            { '$match' => match_with_this },
            {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$sort' => { "start_date": -1 }
            },
            {
              '$project' => {
                'total_prescription_count' => 1,
                'total_prescription_converted_count' => 1,
                'total_invoice_amount' => 1,
                'user_id' => 1,
                'facility_id' => 1,
                'organisation_id' => 1,
                'start_date' => 1,
                'end_date' => 1
              }
            }, {
              '$group' => {
                '_id' => { group_by.to_s => '$start_date' },
                'total_count' => { '$sum' => '$total_prescription_count' },
                'converted_count' => { '$sum' => '$total_prescription_converted_count' },
                'start_date' => { '$addToSet' => '$start_date' },
                'end_date' => { '$addToSet' => '$end_date' }
              }
            },
            {
              '$sort' => { "start_date": -1 }
            }
          ]
        ).to_a

        data_labels = []
        data_converted_count = []
        data_total_count = []
        data_not_converted = []

        doctor_converted_pharmacy = doctor_converted_pharmacy.reverse
        if group_by == '$dayOfMonth'
          doctor_converted_pharmacy = from_date.upto(to_date).to_a.map { |date| (doctor_converted_pharmacy.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
          doctor_converted_pharmacy.each_with_index do |row, _indx|
            if row.present?
              data_labels.push(row['start_date'][0].strftime('%d %a'))
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_labels.push('')
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        elsif group_by == '$week'
          doctor_converted_pharmacy = doctor_converted_pharmacy.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
          doctor_converted_pharmacy.each_with_index do |row, _indx|
            start_date = row['start_date'][0]
            end_date = row['end_date'][0]
            data_labels << "#{start_date.strftime('%d %b')}-#{end_date.strftime('%d %b')}"
            if row.present?
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        elsif group_by == '$month'
          doctor_converted_pharmacy.each_with_index do |row, _indx|
            if row.present?
              data_labels << row['start_date'][0].strftime('%b %Y')
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_labels << ''
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        elsif group_by == '$year'
          doctor_converted_pharmacy.each_with_index do |row, _indx|
            if row.present?
              data_labels << row['start_date'][0].strftime('%Y')
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_labels << ''
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        end

        [data_labels, data_total_count, data_converted_count, data_not_converted]
      end

      def doctor_converted_optical(params_hash = {})
        label_on = params_hash['label_on']
        user_id = BSON::ObjectId(params_hash['user_id']) if params_hash['user_id'].present?
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

        doctor_role_id = 158965000
        # if from_date == to_date
        #   from_date = from_date - 7.days
        # end

        match_with_this = {
          'organisation_id' => BSON::ObjectId(organisation_id),
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id,
          'role_ids' => { '$in' => [doctor_role_id, '$role_ids'] }
        }
        match_with_this.except!('user_id') unless user_id.present?
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        doctor_converted_optical = Analytics::Conversion::OpticalPrescription.collection.aggregate(
          [
            { '$match' => match_with_this }, {
              '$match' => { '$or' => match_with_this2 }
            }, {
              '$sort' => { "start_date": -1 }
            },
            {
              '$project' => {
                'total_prescription_advised_count' => 1,
                'converted_prescription_count' => 1,
                'user_id' => 1,
                'facility_id' => 1,
                'organisation_id' => 1,
                'start_date' => 1,
                'end_date' => 1
              }
            }, {
              '$group' => {
                '_id' => { group_by.to_s => '$start_date' },
                'total_count' => { '$sum' => '$total_prescription_advised_count' },
                'converted_count' => { '$sum' => '$converted_prescription_count' },
                'start_date' => { '$addToSet' => '$start_date' },
                'end_date' => { '$addToSet' => '$end_date' }
              }
            },
            {
              '$sort' => { "start_date": -1 }
            }
          ]
        ).to_a

        data_labels = []
        data_converted_count = []
        data_total_count = []
        data_not_converted = []
        doctor_converted_optical = doctor_converted_optical.reverse

        if group_by == '$dayOfMonth'
          doctor_converted_optical = from_date.upto(to_date).to_a.map { |date| (doctor_converted_optical.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
          doctor_converted_optical.each_with_index do |row, _indx|
            if row.present?
              data_labels.push(row['start_date'][0].strftime('%d %a'))
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        elsif group_by == '$week'
          doctor_converted_optical = doctor_converted_optical.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
          doctor_converted_optical.each_with_index do |row, _indx|
            start_date = row['start_date'][0]
            end_date = row['end_date'][0]
            data_labels << "#{start_date.strftime('%d %b')}-#{end_date.strftime('%d %b')}"
            if row.present?
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        elsif group_by == '$month'
          doctor_converted_optical.each_with_index do |row, _indx|
            if row.present?
              data_labels << row['start_date'][0].strftime('%b %Y')
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        elsif group_by == '$year'
          doctor_converted_optical.each_with_index do |row, _indx|
            if row.present?
              data_labels << row['start_date'][0].strftime('%b %Y')
              data_total_count.push(row['total_count'])
              data_converted_count.push(row['converted_count'])
              data_not_converted.push(row['total_count'].to_i - row['converted_count'].to_i)
              # else
              #   data_total_count.push(0)
              #   data_converted_count.push(0)
              #   data_not_converted.push(0)
            end
          end
        end
        [data_labels, data_total_count, data_converted_count, data_not_converted]
      end

      def doctor_procedures_converted(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        doctor_role_id = 158965000

        total_procedures = get_clinical_data(from_date, to_date, group_by, doctor_role_id, organisation_id, 'procedures', facility_id, specialty_id, user_id, match_with_this2)

        procedure_labels = []
        @procedures_total_count = []
        @procedures_converted_count = []
        @procedures_not_converted_count = []

        if group_by == '$dayOfMonth'
          from_date.upto(to_date).to_a.each_with_index do |date, _i|
            procedure_labels << date.strftime('%a')
            record_data = total_procedures.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

            get_doctor_clinical_data(record_data, 'procedures')
          end
        elsif group_by == '$week'
          total_procedures = total_procedures.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

          week_days.each_with_index do |date, _indx|
            record_data = total_procedures.find { |hash| hash['_id'].to_i == date.cweek }
            procedure_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

            get_doctor_clinical_data(record_data, 'procedures')
          end
        elsif group_by == '$month'
          months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }
          months.each_with_index do |month, _indx|
            record_data = total_procedures.find { |hash| hash['_id'].to_i == Date.parse(month).month }
            procedure_labels << month

            get_doctor_clinical_data(record_data, 'procedures')
          end
        elsif group_by == '$year'
          years = from_date.upto(to_date).to_a.map(&:year).uniq
          years.each_with_index do |year, _indx|
            record_data = total_procedures.find { |hash| hash['_id'].to_i == year }
            procedure_labels << year
            get_doctor_clinical_data(record_data, 'procedures')
          end
        end

        [procedure_labels, @procedures_total_count, @procedures_converted_count, @procedures_not_converted_count, group_by]
      end

      def doctor_diagnosis_advised(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        doctor_role_id = 158965000

        total_diagnoses = get_clinical_data(from_date, to_date, group_by, doctor_role_id, organisation_id, 'diagnoses', facility_id, specialty_id, user_id, match_with_this2)

        diagnoses_labels = []
        @diagnoses_total_count = []
        @diagnoses_advised_count = []
        @diagnoses_converted_count = []
        @diagnoses_not_converted_count = []

        if group_by == '$dayOfMonth'
          from_date.upto(to_date).to_a.each_with_index do |date, _i|
            diagnoses_labels << date.strftime('%a')
            record_data = total_diagnoses.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

            get_doctor_clinical_data(record_data, 'diagnoses')
          end

        elsif group_by == '$week'
          total_diagnoses = total_diagnoses.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

          week_days.each_with_index do |date, _indx|
            record_data = total_diagnoses.find { |hash| hash['_id'].to_i == date.cweek }
            diagnoses_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

            get_doctor_clinical_data(record_data, 'diagnoses')
          end

        elsif group_by == '$month'
          months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }
          months.each_with_index do |month, _indx|
            record_data = total_diagnoses.find { |hash| hash['_id'].to_i == Date.parse(month).month }
            diagnoses_labels << month

            get_doctor_clinical_data(record_data, 'diagnoses')
          end
        elsif group_by == '$year'
          years = from_date.upto(to_date).to_a.map(&:year).uniq
          years.each_with_index do |year, _indx|
            record_data = total_diagnoses.find { |hash| hash['_id'].to_i == year }
            diagnoses_labels << year
            get_doctor_clinical_data(record_data, 'diagnoses')
          end
        end

        [diagnoses_labels, @diagnoses_total_count, @diagnoses_advised_count, group_by]
      end

      def doctor_ophthal_investigations_converted(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        doctor_role_id = 158965000
        total_ophthal_investigations = get_clinical_data(from_date, to_date, group_by, doctor_role_id, organisation_id, 'ophthal_investigations', facility_id, specialty_id, user_id, match_with_this2)

        @ophthal_investigations_labels = []
        @ophthal_investigations_total_count = []
        @ophthal_investigations_converted_count = []
        @ophthal_investigations_not_converted_count = []

        if group_by == '$dayOfMonth'
          from_date.upto(to_date).to_a.each_with_index do |date, _i|
            @ophthal_investigations_labels << date.strftime('%a')
            record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

            get_doctor_clinical_data(record_data, 'ophthal_investigations')
          end

        elsif group_by == '$week'
          total_ophthal_investigations = total_ophthal_investigations.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

          week_days.each_with_index do |date, _indx|
            record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == date.cweek }
            @ophthal_investigations_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

            get_doctor_clinical_data(record_data, 'ophthal_investigations')
          end

        elsif group_by == '$month'
          months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }

          months.each_with_index do |month, _indx|
            record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == Date.parse(month).month }
            @ophthal_investigations_labels << month

            get_doctor_clinical_data(record_data, 'ophthal_investigations')
          end
        elsif group_by == '$year'
          years = from_date.upto(to_date).to_a.map(&:year).uniq
          years.each_with_index do |year, _indx|
            record_data = total_ophthal_investigations.find { |hash| hash['_id'].to_i == year }
            @ophthal_investigations_labels << year
            get_doctor_clinical_data(record_data, 'ophthal_investigations')
          end
        end

        [@ophthal_investigations_labels, @ophthal_investigations_total_count, @ophthal_investigations_converted_count, @ophthal_investigations_not_converted_count, group_by]
      end

      def doctor_laboratory_investigations_converted(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        doctor_role_id = 158965000
        total_laboratory_investigations = get_clinical_data(from_date, to_date, group_by, doctor_role_id, organisation_id, 'laboratory_investigations', facility_id, specialty_id, user_id, match_with_this2)

        @laboratory_investigations_labels = []
        @laboratory_investigations_total_count = []
        @laboratory_investigations_converted_count = []
        @laboratory_investigations_not_converted_count = []

        if group_by == '$dayOfMonth'
          from_date.upto(to_date).to_a.each_with_index do |date, _i|
            @laboratory_investigations_labels << date.strftime('%a')
            record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

            get_doctor_clinical_data(record_data, 'laboratory_investigations')
          end

        elsif group_by == '$week'
          total_laboratory_investigations = total_laboratory_investigations.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

          week_days.each_with_index do |date, _indx|
            record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == date.cweek }
            @laboratory_investigations_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

            get_doctor_clinical_data(record_data, 'laboratory_investigations')
          end

        elsif group_by == '$month'
          months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }

          months.each_with_index do |month, _indx|
            record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == Date.parse(month).month }
            @laboratory_investigations_labels << month

            get_doctor_clinical_data(record_data, 'laboratory_investigations')
          end
        elsif group_by == '$year'
          years = from_date.upto(to_date).to_a.map(&:year).uniq
          years.each_with_index do |year, _indx|
            record_data = total_laboratory_investigations.find { |hash| hash['_id'].to_i == year }
            @laboratory_investigations_labels << year
            get_doctor_clinical_data(record_data, 'laboratory_investigations')
          end

        end

        [@laboratory_investigations_labels, @laboratory_investigations_total_count, @laboratory_investigations_converted_count, @laboratory_investigations_not_converted_count, group_by]
      end

      def doctor_radiology_investigations_converted(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        doctor_role_id = 158965000
        total_radiology_investigations = get_clinical_data(from_date, to_date, group_by, doctor_role_id, organisation_id, 'radiology_investigations', facility_id, specialty_id, user_id, match_with_this2)

        @radiology_investigations_labels = []
        @radiology_investigations_total_count = []
        @radiology_investigations_converted_count = []
        @radiology_investigations_not_converted_count = []

        if group_by == '$dayOfMonth'
          from_date.upto(to_date).to_a.each_with_index do |date, _i|
            @radiology_investigations_labels << date.strftime('%a')
            record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == date.strftime('%d').to_i }

            get_doctor_clinical_data(record_data, 'radiology_investigations')
          end

        elsif group_by == '$week'
          total_radiology_investigations = total_radiology_investigations.each { |set| set['_id'] = set['_id'].to_i + 1 } # done intentionally, data from aggregate was coming as -1 week
          day_today = Date.today.strftime('%A').to_s.downcase.to_sym
          week_days = from_date.upto(to_date).to_a.select(&:"#{day_today}?")

          week_days.each_with_index do |date, _indx|
            record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == date.cweek }
            @radiology_investigations_labels << "#{date.strftime('%d')} - #{(date + 6.days).strftime('%d')}"

            get_doctor_clinical_data(record_data, 'radiology_investigations')
          end

        elsif group_by == '$month'
          months = from_date.upto(to_date).to_a.map(&:month).uniq.map { |m| Date::MONTHNAMES[m] }

          months.each_with_index do |month, _indx|
            record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == Date.parse(month).month }
            @radiology_investigations_labels << month

            get_doctor_clinical_data(record_data, 'radiology_investigations')
          end
        elsif group_by == '$year'
          years = from_date.upto(to_date).to_a.map(&:year).uniq
          years.each_with_index do |year, _indx|
            record_data = total_radiology_investigations.find { |hash| hash['_id'].to_i == year }
            @radiology_investigations_labels << year
            get_doctor_clinical_data(record_data, 'radiology_investigations')
          end

        end

        [@radiology_investigations_labels, @radiology_investigations_total_count, @radiology_investigations_converted_count, @radiology_investigations_not_converted_count, group_by]
      end

      def patient_seen_by_doctors(params_hash)
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        from_date = Date.parse(from_date)
        to_date = Date.parse(to_date)
        role = 'doctor'

        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id

        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id,
          'role' => role
        }

        match_with_this.except!('user_id') unless user_id.present?
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        patient_seen_by_doctors = Analytics::UserAverageTime.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } }, {
              '$project' => {
                'total_patient_seen' => 1,
                'total_time_given' => 1,
                'opd_new_patient_count' => 1,
                'opd_old_patient_count' => 1,
                'avg_time_given' => 1,
                'date' => 1,
                'user_id' => 1
              }
            },
            {
              '$group' => {
                '_id' => '$user_id',
                'total_patient_seen' => { '$sum' => '$total_patient_seen' }
              }
            }
          ]
        ).to_a

        patient_seen_by_doctors = patient_seen_by_doctors.sort_by { |row| row['total_patient_seen'] }.reverse

        all_doctors_name_label      = []
        all_doctors_patient_seen    = []
        best_5_doctors_label        = []
        best_5_doctors_patient_seen = []

        all_doctors_name_label = patient_seen_by_doctors.map { |row| User.find_by(id: row['_id']).try(:fullname) }
        all_doctors_patient_seen = patient_seen_by_doctors.map { |row| row['total_patient_seen'] }
        best_5_doctors_label = all_doctors_name_label.take(5)
        best_5_doctors_patient_seen = all_doctors_patient_seen.take(5)

        [all_doctors_name_label, all_doctors_patient_seen, best_5_doctors_label, best_5_doctors_patient_seen]
      end

      def total_patient_seen_by_doc_in_facility(params_hash)
        label_on = params_hash['label_on']
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        user_id = params_hash['user_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']

        patient_seen = []
        from_date = Date.parse(from_date)
        to_date = Date.parse(to_date)
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id
        role = 'doctor'
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id,
          'role' => role
        }

        match_with_this.except!('user_id') unless user_id.present?
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        patient_seen = Analytics::UserAverageTime.collection.aggregate(
          [
            { '$match' => match_with_this }, { '$match' => { '$or' => match_with_this2 } }, {
              '$group' => {
                '_id' => '$facility_id',
                'total_patient_seen' => { '$sum' => '$total_patient_seen' }
              }
            }
          ]
        ).to_a

        all_facility_name = []
        all_total_patient_seen_count = []
        all_facility_abbreviation = []
        patient_seen = patient_seen.sort_by { |k| k['total_patient_seen'] }.reverse
        all_facility_name = patient_seen.map { |fac_id| Facility.find_by(id: fac_id['_id']).try(:name) }
        all_facility_abbreviation = patient_seen.map { |fac_id| Facility.find_by(id: fac_id['_id']).try(:abbreviation) }
        all_total_patient_seen_count = patient_seen.map { |fac_id| fac_id['total_patient_seen'] }

        facility_name_label = all_facility_abbreviation.take(5)
        total_patient_seen_count = all_total_patient_seen_count.take(5)

        [all_facility_name, all_total_patient_seen_count, facility_name_label, total_patient_seen_count, all_facility_abbreviation]
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

      def get_clinical_data(_from_date, _to_date, group_by, role_id, organisation_id, find_from, facility_id, specialty_id, user_id, match_with_this2)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        user_id     = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id
        match_with_this = {
          'organisation_id' => BSON::ObjectId(organisation_id.to_s),
          'user_role_ids' => { '$in' => [role_id, '$user_role_ids'] },
          'user_id' => user_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id
        }

        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'
        match_with_this.except!('user_id') unless user_id.present?

        found_records = Analytics::ClinicalOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, {
              '$match' => {
                '$or' => match_with_this2
              }
            },
            {
              '$project' =>
              { 'start_date' => 1, "total_#{find_from}_advised" => 1, "total_#{find_from}_converted" => 1 }
            },
            { '$group' =>
              { '_id' => { group_by.to_s => '$start_date' }, "total_#{find_from}_advised" => { '$sum' => "$total_#{find_from}_advised" }, "total_#{find_from}_converted" => { '$sum' => "$total_#{find_from}_converted" } } }
          ]
        ).to_a

        found_records
      end

      def get_doctor_clinical_data(record_data, find_from)
        if record_data
          eval("@#{find_from}_total_count") << record_data["total_#{find_from}_advised"].to_i
          eval("@#{find_from}_converted_count") << record_data["total_#{find_from}_converted"].to_i
          eval("@#{find_from}_not_converted_count") << record_data["total_#{find_from}_advised"].to_i - record_data["total_#{find_from}_converted"].to_i

          eval("@#{find_from}_advised_count") << record_data["total_#{find_from}_advised"].to_i if find_from == 'diagnoses'
        else
          eval("@#{find_from}_total_count") << 0
          eval("@#{find_from}_converted_count") << 0
          eval("@#{find_from}_not_converted_count") << 0

          eval("@#{find_from}_advised_count") << 0 if find_from == 'diagnoses'
        end
      end
    end
  end
end
