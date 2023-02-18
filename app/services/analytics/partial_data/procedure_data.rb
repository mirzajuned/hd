module Analytics::PartialData
  class ProcedureData
    include AnalyticsHelper

    def self.top_ten_procedures(params_hash = {})
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, 499992366, '$user_role_ids'] }
      }
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      procedure_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, { '$match' => { '$or' => match_with_this2 } },
          { '$project' => { 'date' => 1, 'procedures_list' => 1 } },
          { '$unwind' => '$procedures_list' },
          { '$group' => {
            '_id' => '$procedures_list.code',
            'procedure_name' => { '$first' => '$procedures_list.procedure_name' },
            'count' => { '$sum' => '$procedures_list.count' }
          } }
        ]
      ).to_a

      procedure_data = procedure_data.sort_by { |ele| ele['count'] }.reverse[0..9]
      top_procedures_labels = procedure_data.pluck('procedure_name').map(&:capitalize)
      top_procedures_data = procedure_data.pluck('count')

      [top_procedures_labels.map(&:upcase), top_procedures_data]
    end

    def self.get_advised_performed_procedures(params_hash = {})
      procedure = params_hash['procedure']
      procedure = procedure.present? ? procedure : 'cataract'
      procedures_codes = CommonProcedure.where(region: procedure).pluck(:code, :name)
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, 499992366, '$user_role_ids'] }
      }
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      procedures_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, { '$match' => { '$or' => match_with_this2 } },
          { '$project' => { 'date' => 1, 'procedures_list' => 1 } },
          { '$unwind' => '$procedures_list' },
          {
            '$group' => {
              '_id' => '$procedures_list.code',
              'procedure_name' => { '$first' => '$procedures_list.procedure_name' },
              'count' => { '$sum' => '$procedures_list.count' }
            }
          }
        ]
      ).to_a
      procedures_data = procedures_data.reject { |ele| ele['_id'].nil? }

      procedures_hash = []
      procedures_codes.each do |code|
        found_procedures = procedures_data.select { |ele| ele['_id'].casecmp(code[0]).zero? }

        procedures_hash << if found_procedures.count > 0
                             { procedure_name: code[1], code: code[0], count: found_procedures.pluck('count').sum }
                           else
                             { procedure_name: code[1], code: code[0], count: 0 }
                           end
      end

      procedures_hash = procedures_hash.sort_by { |ele| ele[:count] }.reverse[0..9]

      labels = procedures_hash.pluck(:procedure_name)
      data = procedures_hash.pluck(:count)

      [labels.map(&:upcase), data]
    end

    def self.get_age_wise_procedures_data(params_hash = {})
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
      year_now = Time.current.year
      region = params_hash['region']
      region = region.present? ? region : 'cataract'
      procedures_codes = CommonProcedure.where(region: region).pluck(:code)

      procedures_labels = ['0 - 20', '21 - 40', '41 - 60', '> 60', 'unspecified']
      procedures_data = [0, 0, 0, 0, 0]
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, 499992366, '$user_role_ids'] }
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
              'procedures_list' => 1
            }
          }
        ]
      ).to_a

      final_procedures_data = []
      age_wise_data.each do |data|
        list_data = data['procedures_list'].group_by { |el| el['code'] }
        list_data.each do |key, value|
          final_procedures_data << { "code": key, "count": value.pluck('count').sum, "age_year": data['patient_age_year'] }
        end
      end

      final_procedures_data = final_procedures_data.group_by { |el| el[:age_year] }
      final_procedures_data.each do |key, value|
        values = value.group_by { |el| el[:code] }
        age = key.present? ? year_now - key.to_i : -1

        if age.between?(0, 20)
          values.each do |k, v|
            if k.present? && procedures_codes.include?(k.upcase)
              procedures_data[0] = procedures_data[0] + v.pluck(:count).sum
            end
          end

        elsif age.between?(21, 40)
          values.each do |k, v|
            if k.present? && procedures_codes.include?(k.upcase)
              procedures_data[1] = procedures_data[1] + v.pluck(:count).sum
            end
          end

        elsif age.between?(41, 60)
          values.each do |k, v|
            if k.present? && procedures_codes.include?(k.upcase)
              procedures_data[2] = procedures_data[2] + v.pluck(:count).sum
            end
          end

        elsif age > 60
          values.each do |k, v|
            if k.present? && procedures_codes.include?(k.upcase)
              procedures_data[3] = procedures_data[3] + v.pluck(:count).sum
            end
          end

        else
          values.each do |k, v|
            if k.present? && procedures_codes.include?(k.upcase)
              procedures_data[4] = procedures_data[4] + v.pluck(:count).sum
            end
          end

        end
      end

      [procedures_labels, procedures_data]
    end

    def self.get_facility_wise_procedures(params_hash = {})
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date = Date.parse(start_date)
      end_date = Date.parse(end_date)
      group_by = 'organisation_id'
      final_procedures = []
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, 499992366, '$user_role_ids'] }
      }
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      procedures_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, { '$match' => { '$or' => match_with_this2 } },
          { '$unwind' => '$procedures_list' },
          { '$group' => {
            '_id' => '$facility_id',
            'procedures_count' => { '$sum' => '$procedures_list.count' }
          } }
        ]
      ).to_a

      procedures_data.each do |data|
        facility = Facility.find_by(id: data['_id'])
        if facility
          facility_name = facility.name
        elsif data['_id']
          facility_name = data['_id']
        end
        final_procedures << { "facility_name": facility_name, "count": data['procedures_count'] }
      end

      data = []
      final_procedures = final_procedures.group_by { |ele| ele[:facility_name] }
      final_procedures.each do |key, value|
        data << { "facility_name": key, "count": value.pluck(:count).sum }
      end

      data = data.sort_by { |ele| ele['count'] }.reverse[0..9]
      [data.pluck(:facility_name).map(&:upcase), data.pluck(:count)]
    end

    private

    def self.set_initial_params(start_date, end_date, facility_id)
      start_date = Date.parse(start_date)
      end_date = Date.parse(end_date)
      group_by = facility_id == 'all' ? 'organisation_id' : 'facility_id'

      [start_date, end_date, group_by]
    end

    def self.fetch_params_hash(params_hash)
      organisation_id = params_hash['organisation_id']
      facility_id = params_hash['facility_id']
      specialty_id = params_hash['specialty_id']
      start_date = params_hash['analytics_from_date']
      end_date = params_hash['analytics_to_date']

      [organisation_id, facility_id, specialty_id, start_date, end_date]
    end
  end
end
