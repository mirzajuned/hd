module Analytics::PartialData
  class OptometristAverageTime
    class << self
      def call(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'role' => 'optometrist'
        }

        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        weekly_optometrist_average_time = Analytics::UserAverageTime.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } }, {
              '$group' => {
                '_id' => '$user_id',
                'total_patient_seen' => { '$sum' => '$total_patient_seen' },
                'total_time_given' => { '$sum' => '$total_time_given' },
                'avg_time_given' => { '$sum' => '$avg_time_given' }
              }
            }
          ]
        ).to_a

        optometrist_name_labels = []
        optometrist_average_time = []
        total_patient_seen = []
        avg_time_given = []
        weekly_optometrist_average_time.each do |row|
          optometrist_name_labels << User.find_by(id: row['_id']).username
          total_time_given = row['total_time_given'].to_f
          total_patient_seen << row['total_patient_seen']
          avg_time_given << (row['avg_time_given'].to_f / 3600)
          optometrist_average_time << (total_time_given / 3600)
        end

        [optometrist_name_labels, optometrist_average_time.map { |d| d.round(2) },
         total_patient_seen, avg_time_given.map { |d| d.round(2) }]
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
