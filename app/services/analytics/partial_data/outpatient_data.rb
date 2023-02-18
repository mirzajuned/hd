module Analytics::PartialData
  class OutpatientData
    class << self
      def get_appointment_types_data(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        user_id = params_hash['user_id']
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id
        }
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'
        match_with_this.except!('user_id') unless user_id.present?

        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        appointment_types = ::Analytics::AppointmentTypeOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$group' => {
                '_id' => '$appointment_type_label',
                'total_count' => { '$sum' => '$appointment_type_count' }
              }
            }
          ]
        ).to_a

        appointment_types_labels = appointment_types.pluck(:_id).map(&:to_s)
        appointment_types_data   = appointment_types.pluck(:total_count)

        [appointment_types_labels, appointment_types_data]
      end

      def get_appointment_category_types_data(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        user_id = params_hash['user_id']
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

        match_with_this = {
          'organisation_id' => organisation_id,
          'facility_id' => facility_id,
          'specialty_id' => specialty_id,
          'user_id' => user_id,
          'appointment_category_type_label' => { '$nin' => ['', nil] }
        }

        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'
        match_with_this.except!('user_id') unless user_id.present?

        appointment_category_types = ::Analytics::AppointmentCategoryTypeOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            },
            {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$group' => {
                '_id' => '$appointment_category_type_label',
                'total_count' => { '$sum' => '$appointment_category_type_count' }
              }
            }
          ]
        ).to_a

        appointment_category_types_labels = appointment_category_types.pluck(:_id).map(&:to_s)
        appointment_category_types_data   = appointment_category_types.pluck(:total_count)

        [appointment_category_types_labels, appointment_category_types_data]
      end

      def get_walkin_types_data(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        user_id = params_hash['user_id']
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

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

        walkin_types = ::Analytics::WalkinAppointmentTypeOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$group' => {
                '_id' => '$appointment_type_label',
                'total_count' => { '$sum' => '$appointment_type_count' }
              }
            }
          ]
        ).to_a

        walkin_types_labels = walkin_types.pluck(:_id).map(&:to_s)
        walkin_types_data = walkin_types.pluck(:total_count)

        [walkin_types_labels, walkin_types_data]
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
