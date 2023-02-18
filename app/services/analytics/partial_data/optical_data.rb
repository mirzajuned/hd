module Analytics::PartialData
  class OpticalData
    def self.call(params_hash = {})
      label_on =  params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date, role_id = fetch_from_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
      user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id
      # if from_date == to_date
      #   from_date = from_date - 7.days
      # end
      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id,
        'role_ids' => { '$in' => [role_id, '$role_ids'] }
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('user_id') unless user_id.present?
      match_with_this.except!('role_ids') unless role_id.present?

      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      optical_data = Analytics::Conversion::OpticalPrescription.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$match' => { '$or' => match_with_this2 }
          }, {
            '$sort' => { "start_date": -1 }
          }, {
            '$project' => {
              'total_prescription_advised_count' => 1,
              'converted_prescription_count' => 1,
              'not_converted_count' => 1,
              # 'total_invoice_amount' => 1,
              'start_date' => 1,
              'end_date' => 1
            }
          }, {
            '$group' => {
              '_id' => { group_by.to_s => '$start_date' },
              'total_count' => { '$sum' => '$total_prescription_advised_count' },
              'converted_count' => { '$sum' => '$converted_prescription_count' },
              'not_converted_count' => { '$sum' => '$not_converted_count' },
              # 'total_invoice_amount' => { '$sum' => '$total_invoice_amount' },
              'start_date' => { '$addToSet' => '$start_date' },
              'end_date' => { '$addToSet' => '$end_date' }
            }
          },
          {
            '$sort' => { "start_date": -1 }
          }
        ]
      ).to_a

      optical_chart_labels = []
      optical_total_count = []
      optical_converted_count = []
      optical_not_converted_count = []
      # optical_earnings = []
      # optical_data = optical_data.sort_by{|row| row["_id"]}.reverse
      optical_data = optical_data.reverse

      if group_by == '$dayOfMonth'
        optical_data = from_date.upto(to_date).to_a.map { |date| (optical_data.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
        optical_data.each_with_index do |row, _indx|
          if row.present?
            optical_chart_labels << row['start_date'][0].strftime('%d %a')
            optical_total_count <<  row['total_count']
            optical_converted_count << row['converted_count']
            optical_not_converted_count << (row['total_count'] - row['converted_count'])
            # optical_earnings << row['total_invoice_amount']
          else
            optical_chart_labels << ''
            optical_total_count << 0
            optical_converted_count << 0
            optical_not_converted_count << 0
            # optical_earnings << 0
          end
        end
      elsif group_by == '$week'
        optical_data = optical_data.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
        optical_data.each_with_index do |row, _indx|
          start_date = row['start_date'][0]
          end_date = row['end_date'][0]
          optical_chart_labels << "#{start_date.strftime('%d %b')}-#{end_date.strftime('%d %b')}"
          if row.present?
            optical_total_count << row['total_count']
            optical_converted_count << row['converted_count']
            optical_not_converted_count << (row['total_count'] - row['converted_count'])
            # optical_earnings << row['total_invoice_amount']
          else
            optical_total_count << 0
            optical_converted_count << 0
            optical_not_converted_count << 0
            # optical_earnings << 0
          end
        end
      elsif group_by == '$month'
        optical_data.each_with_index do |row, _indx|
          if row.present?
            optical_chart_labels << row['start_date'][0].strftime('%b %Y')
            optical_total_count <<  row['total_count']
            optical_converted_count << row['converted_count']
            optical_not_converted_count << (row['total_count'] - row['converted_count'])
            # optical_earnings << row['total_invoice_amount']
          else
            optical_chart_labels << ''
            optical_total_count << 0
            optical_converted_count << 0
            optical_not_converted_count << 0
            # optical_earnings << 0
          end
        end
      elsif group_by == '$year'
        optical_data.each_with_index do |row, _indx|
          if row.present?
            optical_chart_labels << row['start_date'][0].strftime('%Y')
            optical_total_count <<  row['total_count']
            optical_converted_count << row['converted_count']
            optical_not_converted_count << (row['total_count'] - row['converted_count'])
            # optical_earnings << row['total_invoice_amount']
          else
            optical_chart_labels << ''
            optical_total_count << 0
            optical_converted_count << 0
            optical_not_converted_count << 0
            # optical_earnings << 0
          end
        end
      end

      [optical_chart_labels, optical_total_count, optical_converted_count, optical_not_converted_count]
    end

    def self.fetch_from_params_hash(params_hash)
      organisation_id = params_hash['organisation_id']
      facility_id = params_hash['facility_id']
      specialty_id = params_hash['specialty_id']
      user_id = params_hash['user_id']
      from_date = params_hash['analytics_from_date']
      to_date = params_hash['analytics_to_date']
      role_id = params_hash['role_id']
      [organisation_id, facility_id, specialty_id, user_id, from_date, to_date, role_id]
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
