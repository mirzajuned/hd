module Analytics::PartialData
  class InvestigationsData
    class << self
      def facility_wise_ophthal_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date = Date.parse(start_date)
        end_date = Date.parse(end_date)
        group_by = 'organisation_id'
        final_investigations = []
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$unwind' => '$ophthal_investigations_list' },
            {
              '$group' => {
                '_id' => '$facility_id',
                'count' => { '$sum' => '$ophthal_investigations_list.count' }
              }
            }
          ]
        ).to_a

        investigation_data.each do |data|
          facility = Facility.find_by(id: data['_id'])
          if facility
            facility_name = facility.name
          elsif data['_id']
            facility_name = data['_id']
          end
          final_investigations << { "facility_name": facility_name, "count": data['count'] }
        end

        data = []
        final_investigations = final_investigations.group_by { |ele| ele[:facility_name] }
        final_investigations.each do |key, value|
          data << { "facility_name": key, "count": value.pluck(:count).sum }
        end

        data = data.sort_by { |ele| ele['count'] }.reverse[0..9]
        [data.pluck(:facility_name).map(&:upcase), data.pluck(:count)]
      end

      def facility_wise_laboratory_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date = Date.parse(start_date)
        end_date = Date.parse(end_date)
        group_by = 'organisation_id'
        final_investigations = []
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$unwind' => '$laboratory_investigations_list' },
            { '$group' => {
              '_id' => '$facility_id',
              'count' => { '$sum' => '$laboratory_investigations_list.count' }
            } }
          ]
        ).to_a

        investigation_data.each do |data|
          facility = Facility.find_by(id: data['_id'])
          if facility
            facility_name = facility.name
          elsif data['_id']
            facility_name = data['_id']
          end
          final_investigations << { "facility_name": facility_name, "count": data['count'] }
        end

        data = []
        final_investigations = final_investigations.group_by { |ele| ele[:facility_name] }
        final_investigations.each do |key, value|
          data << { "facility_name": key, "count": value.pluck(:count).sum }
        end

        data = data.sort_by { |ele| ele['count'] }.reverse[0..9]
        [data.pluck(:facility_name).map(&:upcase), data.pluck(:count)]
      end

      def facility_wise_radiology_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date = Date.parse(start_date)
        end_date = Date.parse(end_date)
        group_by = 'organisation_id'
        final_investigations = []
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$unwind' => '$radiology_investigations_list' },
            {
              '$group' => {
                '_id' => '$facility_id',
                'count' => { '$sum' => '$radiology_investigations_list.count' }
              }
            }
          ]
        ).to_a

        investigation_data.each do |data|
          facility = Facility.find_by(id: data['_id'])
          if facility
            facility_name = facility.name
          elsif data['_id']
            facility_name = data['_id']
          end
          final_investigations << { "facility_name": facility_name, "count": data['count'] }
        end

        data = []
        final_investigations = final_investigations.group_by { |ele| ele[:facility_name] }
        final_investigations.each do |key, value|
          data << { "facility_name": key, "count": value.pluck(:count).sum }
        end

        data = data.sort_by { |ele| ele['count'] }.reverse[0..9]
        [data.pluck(:facility_name).map(&:upcase), data.pluck(:count)]
      end

      def top_ten_ophthal_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            {
              '$project' => {
                'date' => 1,
                'ophthal_investigations_list' => 1
              }
            },
            { '$unwind' => '$ophthal_investigations_list' },
            {
              '$group' => {
                '_id' => '$ophthal_investigations_list.code',
                'investigation_name' => { '$first' => '$ophthal_investigations_list.investigation_name' },
                'count' => { '$sum' => '$ophthal_investigations_list.count' }
              }
            }
          ]
        ).to_a

        investigation_data = investigation_data.sort_by { |ele| ele['count'] }.reverse[0..9]
        top_inv_labels = investigation_data.pluck('investigation_name').map(&:upcase)
        top_inv_data = investigation_data.pluck('count')

        [top_inv_labels, top_inv_data]
      end

      def top_ten_laboratory_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$project' => { 'date' => 1, 'laboratory_investigations_list' => 1 } },
            { '$unwind' => '$laboratory_investigations_list' },
            {
              '$group' => {
                '_id' => '$laboratory_investigations_list.code',
                'investigation_name' => { '$first' => '$laboratory_investigations_list.investigation_name' },
                'count' => { '$sum' => '$laboratory_investigations_list.count' }
              }
            }
          ]
        ).to_a

        investigation_data = investigation_data.sort_by { |ele| ele['count'] }.reverse[0..9]
        top_investigation_labels = investigation_data.pluck('investigation_name').map(&:upcase)
        top_investigation_data = investigation_data.pluck('count')

        [top_investigation_labels, top_investigation_data]
      end

      def top_ten_radiology_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$project' => { 'date' => 1, 'radiology_investigations_list' => 1 } },
            { '$unwind' => '$radiology_investigations_list' },
            {
              '$group' => {
                '_id' => '$radiology_investigations_list.code',
                'investigation_name' => { '$first' => '$radiology_investigations_list.investigation_name' },
                'count' => { '$sum' => '$radiology_investigations_list.count' }
              }
            }
          ]
        ).to_a

        investigation_data = investigation_data.sort_by { |ele| ele['count'] }.reverse[0..9]
        top_investigation_labels = investigation_data.pluck('investigation_name').map(&:upcase)
        top_investigation_data = investigation_data.pluck('count')

        [top_investigation_labels, top_investigation_data]
      end

      def ophthal_investigation_data(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        region = params_hash['region']
        region = region.present? ? region : 'cataract'
        region_codes = OphthalmologyInvestigationData.where(region: region).pluck(:investigation_name, :investigation_id)

        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$project' => { 'date' => 1, 'ophthal_investigations_list' => 1 } },
            { '$unwind' => '$ophthal_investigations_list' },
            {
              '$group' => {
                '_id' => '$ophthal_investigations_list.code',
                'investigation_name' => { '$first' => '$ophthal_investigations_list.investigation_name' },
                'count' => { '$sum' => '$ophthal_investigations_list.count' }
              }
            }
          ]
        ).to_a

        investigation_final_data = []
        region_codes.each do |code|
          found_investigations = investigation_data.select { |ele| ele['_id'].casecmp(code[1]).zero? }

          if found_investigations.count > 0
            investigation_final_data << { investigation_name: code[0], code: code[1], count: found_investigations.pluck('count').sum }
          else
            investigation_final_data << { investigation_name: code[0], code: code[1], count: 0 }
          end
        end

        investigation_final_data = investigation_final_data.sort_by { |ele| ele[:count] }.reverse[0..9]
        labels = investigation_final_data.pluck(:investigation_name).map(&:upcase)
        data = investigation_final_data.pluck(:count)

        [labels, data]
      end

      def laboratory_investigation_data(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
          'date' => { '$gte' => start_date.beginning_of_day, '$lte' => end_date.end_of_day }
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            {
              '$project' => {
                'date' => 1,
                'laboratory_investigations_list' => 1
              }
            },
            { '$unwind' => '$laboratory_investigations_list' },
            { '$group' => {
              '_id' => '$laboratory_investigations_list.code',
              'investigation_name' => { '$first' => '$laboratory_investigations_list.investigation_name' },
              'count' => { '$sum' => '$laboratory_investigations_list.count' }
            } }
          ]
        ).to_a

        investigation_data = investigation_data.sort_by { |ele| ele[:count] }.reverse
        labels = investigation_data.pluck(:investigation_name).map(&:upcase)
        data = investigation_data.pluck(:count)
        data = [0, 0, 0, 0, 0] unless data.present?
        [labels, data]
      end

      def radiology_investigation_data(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        investigation_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$project' => { 'date' => 1, 'radiology_investigations_list' => 1 } },
            { '$unwind' => '$radiology_investigations_list' },
            {
              '$group' => {
                '_id' => '$radiology_investigations_list.code',
                'investigation_name' => { '$first' => '$radiology_investigations_list.investigation_name' },
                'count' => { '$sum' => '$radiology_investigations_list.count' }
              }
            }
          ]
        ).to_a

        labels = investigation_data.pluck(:investigation_name).map(&:upcase)
        data = investigation_data.pluck(:count)
        data = [0, 0, 0, 0, 0] unless data.present?
        [labels, data]
      end

      def age_wise_ophthal_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        region = params_hash['region']
        region = region.present? ? region : 'cataract'
        region_codes = OphthalmologyInvestigationData.where(region: region).pluck(:investigation_id)
        year_now = Time.current.year

        investigations_labels = ['0 - 20', '21 - 40', '41 - 60', '> 60', 'unspecified']
        investigations_data = [0, 0, 0, 0, 0]
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        age_wise_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            { '$project' => {
              'date' => 1,
              'patient_age_year' => 1,
              'ophthal_investigations_list' => 1
            } }
          ]
        ).to_a

        final_investigations = []
        age_wise_data.each do |data|
          list_data = data['ophthal_investigations_list'].group_by { |el| el['code'] }
          list_data.each do |key, value|
            final_investigations << { "code": key, "count": value.pluck('count').sum, "age_year": data['patient_age_year'] }
          end
        end

        final_investigations = final_investigations.group_by { |el| el[:age_year] }
        final_investigations.each do |key, value|
          values = value.group_by { |el| el[:code] }
          age = key.present? ? year_now - key.to_i : -1

          if age.between?(0, 20)
            values.each do |k, v|
              investigations_data[0] = investigations_data[0] + v.pluck(:count).sum if region_codes.include?(k.upcase)
            end

          elsif age.between?(21, 40)
            values.each do |k, v|
              investigations_data[1] = investigations_data[1] + v.pluck(:count).sum if region_codes.include?(k.upcase)
            end

          elsif age.between?(41, 60)
            values.each do |k, v|
              investigations_data[2] = investigations_data[2] + v.pluck(:count).sum if region_codes.include?(k.upcase)
            end

          elsif age > 60
            values.each do |k, v|
              investigations_data[3] = investigations_data[3] + v.pluck(:count).sum if region_codes.include?(k.upcase)
            end

          else
            values.each do |k, v|
              investigations_data[4] = investigations_data[4] + v.pluck(:count).sum if region_codes.include?(k.upcase)
            end

          end
        end

        [investigations_labels, investigations_data]
      end

      def age_wise_laboratory_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        year_now = Time.current.year

        investigations_labels = ['0 - 20', '21 - 40', '41 - 60', '> 60', 'unspecified']
        investigations_data = [0, 0, 0, 0, 0]
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        age_wise_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            {
              '$project' => {
                'date' => 1,
                'patient_age_year' => 1,
                'laboratory_investigations_list' => 1
              }
            }
          ]
        ).to_a

        final_investigations = []
        age_wise_data.each do |data|
          list_data = data['laboratory_investigations_list'].group_by { |el| el['code'] }
          list_data.each do |key, value|
            final_investigations << { "code": key, "count": value.pluck('count').sum, "age_year": data['patient_age_year'] }
          end
        end

        final_investigations = final_investigations.group_by { |el| el[:age_year] }
        final_investigations.each do |key, value|
          values = value.group_by { |el| el[:code] }
          age = key.present? ? year_now - key.to_i : -1

          if age.between?(0, 20)
            values.each do |_k, v|
              investigations_data[0] = investigations_data[0] + v.pluck(:count).sum
            end

          elsif age.between?(21, 40)
            values.each do |_k, v|
              investigations_data[1] = investigations_data[1] + v.pluck(:count).sum
            end

          elsif age.between?(41, 60)
            values.each do |_k, v|
              investigations_data[2] = investigations_data[2] + v.pluck(:count).sum
            end

          elsif age > 60
            values.each do |_k, v|
              investigations_data[3] = investigations_data[3] + v.pluck(:count).sum
            end

          else
            values.each do |_k, v|
              investigations_data[4] = investigations_data[4] + v.pluck(:count).sum
            end
          end
        end

        [investigations_labels, investigations_data]
      end

      def age_wise_radiology_investigations(params_hash = {})
        organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
        start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
        year_now = Time.current.year

        investigations_labels = ['0 - 20', '21 - 40', '41 - 60', '> 60', 'unspecified']
        investigations_data = [0, 0, 0, 0, 0]

        # age_wise_data = Analytics::ClinicalDataOverview.collection.aggregate(
        #   [
        #     { '$match' => { group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id, 'date' => { '$gte' => start_date, '$lte' => end_date }, 'user_role_ids' => { '$in' => [158965000, '$user_role_ids'] } } },
        #     { '$project' => { 'date' => 1, 'patient_age_year' => 1, 'radiology_investigations_list' => 1 } },
        #     { '$unwind' => '$radiology_investigations_list' },
        #     { '$group' => { '_id' => '$radiology_investigations_list.code', 'year' => { '$first' => '$patient_age_year' }, 'investigation_name' => { '$first' => '$radiology_investigations_list.investigation_name' }, 'count' => { '$sum' => '$radiology_investigations_list.count' } } }
        #   ]
        # ).to_a
        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        match_with_this = {
          group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id
        }
        match_with_this.except!('specialty_id') if specialty_id == 'all'

        age_wise_data = Analytics::ClinicalDataOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            }, { '$match' => { '$or' => match_with_this2 } },
            {
              '$project' => {
                'date' => 1,
                'patient_age_year' => 1,
                'radiology_investigations_list' => 1
              }
            }
          ]
        ).to_a

        final_investigations = []
        age_wise_data.each do |data|
          list_data = data['radiology_investigations_list'].group_by { |el| el['code'] }
          list_data.each do |key, value|
            final_investigations << { "code": key, "count": value.pluck('count').sum, "age_year": data['patient_age_year'] }
          end
        end

        final_investigations = final_investigations.group_by { |el| el[:age_year] }
        final_investigations.each do |key, value|
          values = value.group_by { |el| el[:code] }
          age = key.present? ? year_now - key.to_i : -1

          if age.between?(0, 20)
            values.each do |_k, v|
              investigations_data[0] = investigations_data[0] + v.pluck(:count).sum
            end

          elsif age.between?(21, 40)
            values.each do |_k, v|
              investigations_data[1] = investigations_data[1] + v.pluck(:count).sum
            end

          elsif age.between?(41, 60)
            values.each do |_k, v|
              investigations_data[2] = investigations_data[2] + v.pluck(:count).sum
            end

          elsif age > 60
            values.each do |_k, v|
              investigations_data[3] = investigations_data[3] + v.pluck(:count).sum
            end

          else
            values.each do |_k, v|
              investigations_data[4] = investigations_data[4] + v.pluck(:count).sum
            end
          end
        end

        [investigations_labels, investigations_data]
      end

      private

      def set_initial_params(start_date, end_date, facility_id)
        start_date = Date.parse(start_date)
        end_date = Date.parse(end_date)
        group_by = facility_id == 'all' ? 'organisation_id' : 'facility_id'

        [start_date, end_date, group_by]
      end

      def fetch_params_hash(params_hash)
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        start_date = params_hash['analytics_from_date']
        end_date = params_hash['analytics_to_date']

        [organisation_id, facility_id, specialty_id, start_date, end_date]
      end
    end
  end
end
