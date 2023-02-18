module Analytics::PartialData
  class NewOldPatient
    def self.call(params_hash = {})
      label_on =  params_hash['label_on']
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      user_id = params_hash['user_id']
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      # if from_date == to_date
      #   from_date = from_date - 7.days
      # end
      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id
      }
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('user_id') unless user_id.present?
      general_overview_data = Analytics::GeneralOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$match' => { '$or' => match_with_this2 }
          }, {
            '$sort' => { "start_date": -1 }
          },
          {
            '$group' => {
              '_id' => { group_by.to_s => '$start_date' },
              'opd_new_patient_count' => { '$sum' => '$opd_new_patient_count' },
              'opd_old_patient_count' => { '$sum' => '$opd_old_patient_count' },
              'start_date' => { '$addToSet' => '$start_date' },
              'end_date' => { '$addToSet' => '$end_date' }

            }
          },
          {
            '$sort' => { "start_date": -1 }
          }
        ]
      ).to_a
      appointment_chart_labels = []
      appointment_chart_new_pat_data = []
      appointment_chart_old_pat_data = []
      general_overview_data = general_overview_data.reverse
      if group_by == '$dayOfMonth'
        general_overview_data = from_date.upto(to_date).to_a.map { |date| (general_overview_data.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
        general_overview_data.each_with_index do |row, _indx|
          if row.present?
            appointment_chart_labels.push(row['start_date'][0].strftime('%d %a'))
            appointment_chart_new_pat_data.push(row['opd_new_patient_count'])
            appointment_chart_old_pat_data.push(row['opd_old_patient_count'])
          else
            appointment_chart_labels.push('')
            appointment_chart_new_pat_data.push(0)
            appointment_chart_old_pat_data.push(0)
          end
        end
      elsif group_by == '$week'
        general_overview_data = general_overview_data.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
        general_overview_data.each_with_index do |row, _indx|
          start_date = row['start_date'][0]
          end_date = row['end_date'][0]
          appointment_chart_labels << "#{start_date.strftime('%d %b')}-#{end_date.strftime('%d %b')}"
          if row.present?
            appointment_chart_new_pat_data.push(row['opd_new_patient_count'])
            appointment_chart_old_pat_data.push(row['opd_old_patient_count'])
          else
            appointment_chart_new_pat_data.push(0)
            appointment_chart_old_pat_data.push(0)
          end
        end
      elsif group_by == '$month'
        general_overview_data.each_with_index do |row, _indx|
          if row.present?
            appointment_chart_labels << row['start_date'][0].strftime('%b %Y')
            appointment_chart_new_pat_data.push(row['opd_new_patient_count'])
            appointment_chart_old_pat_data.push(row['opd_old_patient_count'])
          else
            appointment_chart_labels << ''
            appointment_chart_new_pat_data.push(0)
            appointment_chart_old_pat_data.push(0)
          end
        end
      elsif group_by == '$year'
        general_overview_data.each_with_index do |row, _indx|
          if row.present?
            appointment_chart_labels << row['start_date'][0].strftime('%Y')
            appointment_chart_new_pat_data.push(row['opd_new_patient_count'])
            appointment_chart_old_pat_data.push(row['opd_old_patient_count'])
          else
            appointment_chart_labels << ''
            appointment_chart_new_pat_data.push(0)
            appointment_chart_old_pat_data.push(0)
          end
        end
      end

      [appointment_chart_labels, appointment_chart_new_pat_data, appointment_chart_old_pat_data]
    end

    private

    def self.fetch_params_hash(params_hash = {})
      organisation_id = params_hash['organisation_id']
      facility_id = params_hash['facility_id']
      specialty_id = params_hash['specialty_id']
      from_date = params_hash['analytics_from_date']
      to_date = params_hash['analytics_to_date']

      [organisation_id, facility_id, specialty_id, from_date, to_date]
    end

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
  end
end
