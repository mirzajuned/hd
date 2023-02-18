module Analytics::PartialData
  class ReferralSource
    class << self
      def call(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

        # if from_date == to_date
        #   from_date = from_date - 7.days
        # end

        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id
        }

        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        referral_types = ::Analytics::ReferralTypeOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$group' => {
                '_id' => '$referral_type_label',
                'total_count' => { '$sum' => '$referral_type_count' }
              }
            }
          ]
        ).to_a

        referral_types_labels = ['Self', 'Doctor Referral', 'Staff Referral', 'Relative', 'Campaign', 'Camp',
                                 'Institutional Referral', 'Agent', 'Online', 'Others', 'Third Party', 'Consultant']
        referral_types_data = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        referral_types.each_with_index do |referral, _i|
          if referral['_id'] == 'Self'
            referral_types_data[0] = referral['total_count']
          elsif referral['_id'] == 'Doctor Referral'
            referral_types_data[1] = referral['total_count']
          elsif referral['_id'] == 'Staff Referral'
            referral_types_data[2] = referral['total_count']
          elsif referral['_id'] == 'Relative'
            referral_types_data[3] = referral['total_count']
          elsif referral['_id'] == 'Campaign'
            referral_types_data[4] = referral['total_count']
          elsif referral['_id'] == 'Camp'
            referral_types_data[5] = referral['total_count']
          elsif referral['_id'] == 'Institutional Referral'
            referral_types_data[6] = referral['total_count']
          elsif referral['_id'] == 'Agent'
            referral_types_data[7] = referral['total_count']
          elsif referral['_id'] == 'Online'
            referral_types_data[8] = referral['total_count']
          elsif referral['_id'] == 'Others'
            referral_types_data[9] = referral['total_count']
          elsif referral['_id'] == 'Third Party'
            referral_types_data[10] = referral['total_count']
          elsif referral['_id'] == 'Consultant'
            referral_types_data[11] = referral['total_count']
          end
        end

        [referral_types_labels, referral_types_data]
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
