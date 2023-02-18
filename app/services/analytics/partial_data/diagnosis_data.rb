module Analytics::PartialData
  class DiagnosisData
    include AnalyticsHelper

    def self.top_ten_diagnoses(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, '$user_role_ids'] }
      }

      match_with_this.except!('specialty_id') if specialty_id == 'all'

      diagnoses_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$match' => { '$or' => match_with_this2 }
          },
          {
            '$project' => { 'date' => 1, 'diagnoses_list' => 1 }
          },
          { '$unwind' => '$diagnoses_list' },
          {
            '$group' => {
              '_id' => '$diagnoses_list.code',
              'diagnosis_name' => {
                '$first' => '$diagnoses_list.diagnosis_name'
              },
              'count' => {
                '$sum' => '$diagnoses_list.count'
              }
            }
          }
        ]
      ).to_a

      diagnoses_data = diagnoses_data.sort_by { |ele| ele['count'] }.reverse[0..9]
      top_diagnosis_labels = diagnoses_data.pluck('diagnosis_name').map(&:capitalize)
      top_diagnosis_data = diagnoses_data.pluck('count')

      [top_diagnosis_labels.map { |ele| ele.try(:upcase) }, top_diagnosis_data]
    end

    def self.commonly_used_diagnosis(params_hash = {})
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)

      diagnosis = params_hash['diagnosis']
      if specialty_id == '309988001'
        diagnosis = diagnosis.present? ? diagnosis : 'Cataract'
        codes_list = TopIcdDiagnosis.find_by(name: diagnosis).list.pluck(:name, :code)
      elsif specialty_id == '309989009'
        diagnosis = diagnosis.present? ? diagnosis : 'cp'
        codes_list = TopOrthoIcdDiagnosis.find_by(name: diagnosis).list.pluck(:name, :code)
      else
        codes_list = []
      end
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, '$user_role_ids'] }
      }

      match_with_this.except!('specialty_id') if specialty_id == 'all'

      diagnoses_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          { '$match' => match_with_this },
          {
            '$match' => { '$or' => match_with_this2 }
          },
          { '$project' => { 'date' => 1, 'diagnoses_list' => 1 } },
          { '$unwind' => '$diagnoses_list' },
          {
            '$group' => {
              '_id' => '$diagnoses_list.parent_code',
              'diagnosis_name' => { '$first' => '$diagnoses_list.diagnosis_name' },
              'count' => { '$sum' => '$diagnoses_list.count' }
            }
          }
        ]
      ).to_a

      diagnoses_data = Hash[diagnoses_data.map { |ele| [ele['_id'], { 'diagnosis_name' => ele['diagnosis_name'], 'count' => ele['count'], 'code' => ele['_id'] }] }]

      diagnosis_hash = []
      codes_list.each do |code|
        found_diagnosis = diagnoses_data.select { |ele| ele == code[1].downcase }

        if found_diagnosis.count > 0
          found_diagnosis = found_diagnosis.values[0]
          diagnosis_hash << { diagnosis_name: code[0], code: found_diagnosis['code'], count: found_diagnosis['count'] }
        else
          diagnosis_hash << { diagnosis_name: code[0], code: code[1], count: 0 }
        end
      end

      commonly_used_diagnosis_labels = diagnosis_hash.pluck(:diagnosis_name)
      commonly_used_diagnosis_data = diagnosis_hash.pluck(:count)

      [commonly_used_diagnosis_labels.map { |ele| ele.try(:upcase) }, commonly_used_diagnosis_data]
    end

    def self.get_age_wise_diagnosis_data(params_hash = {})
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date, end_date, group_by = set_initial_params(start_date, end_date, facility_id)
      year_now = Date.current.year
      department_id = params_hash['department_id']
      diagnosis     = params_hash['diagnosis']
      if specialty_id == '309988001'
        diagnosis = diagnosis.present? ? diagnosis : 'Cataract'
        codes_list = TopIcdDiagnosis.find_by(name: diagnosis).list.pluck(:code)
      elsif specialty_id == '309989009'
        diagnosis = diagnosis.present? ? diagnosis : 'cp'
        codes_list = TopOrthoIcdDiagnosis.find_by(name: diagnosis).list.pluck(:code)
      else
        codes_list = []
      end

      diagnosis_labels = ['0 - 20', '21 - 40', '41 - 60', '> 60', 'unspecified']
      diagnoses_data = [0, 0, 0, 0, 0]
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, '$user_role_ids'] }
      }

      match_with_this.except!('specialty_id') if specialty_id == 'all'

      age_wise_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$match' => { '$or' => match_with_this2 }
          },
          { '$project' => { 'date' => 1, 'patient_age_year' => 1, 'diagnoses_list' => 1 } }
          # {"$group" => { "_id" => "$diagnoses_list.parent_code" , "year" => { "$first" => "$patient_age_year" }, "diagnosis_name" => { "$first" => "$diagnoses_list.diagnosis_name" }, "count"=> { "$sum" => "$diagnoses_list.count" } } }
        ]
      ).to_a

      final_diagnoses_data = []
      age_wise_data.each do |data|
        list_data = data['diagnoses_list'].group_by { |el| el['parent_code'] }
        list_data.each do |key, value|
          final_diagnoses_data << { "code": key, "count": value.pluck('count').sum, "age_year": data['patient_age_year'] }
        end
      end

      final_diagnoses_data = final_diagnoses_data.group_by { |el| el[:age_year] }
      final_diagnoses_data.each do |key, value|
        values = value.group_by { |el| el[:code] }
        age = key.present? ? year_now - key.to_i : -1

        if age.between?(0, 20)
          values.each do |k, v|
            diagnoses_data[0] = diagnoses_data[0] + v.pluck(:count).sum if k.present? && codes_list.include?(k.upcase)
          end

        elsif age.between?(21, 40)
          values.each do |k, v|
            diagnoses_data[1] = diagnoses_data[1] + v.pluck(:count).sum if k.present? && codes_list.include?(k.upcase)
          end

        elsif age.between?(41, 60)
          values.each do |k, v|
            diagnoses_data[2] = diagnoses_data[2] + v.pluck(:count).sum if k.present? && codes_list.include?(k.upcase)
          end

        elsif age > 60
          values.each do |k, v|
            diagnoses_data[3] = diagnoses_data[3] + v.pluck(:count).sum if k.present? && codes_list.include?(k.upcase)
          end

        else
          values.each do |k, v|
            diagnoses_data[4] = diagnoses_data[4] + v.pluck(:count).sum if k.present? && codes_list.include?(k.upcase)
          end

        end
      end

      [diagnosis_labels.map { |ele| ele.try(:upcase) }, diagnoses_data]
    end

    def self.get_facility_wise_diagnosis_data(params_hash = {})
      organisation_id, facility_id, specialty_id, start_date, end_date = fetch_params_hash(params_hash)
      start_date = Date.parse(start_date)
      end_date = Date.parse(end_date)
      group_by = 'organisation_id'
      final_diagnoses = []
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this = {
        group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'specialty_id' => specialty_id,
        'user_role_ids' => { '$in' => [158965000, '$user_role_ids'] }
      }

      match_with_this.except!('specialty_id') if specialty_id == 'all'

      diagnoses_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$match' => { '$or' => match_with_this2 }
          },
          { '$unwind' => '$diagnoses_list' },
          { '$group' => {
            '_id' => '$facility_id',
            'diagnoses_count' => {
              '$sum' => '$diagnoses_list.count'
            }
          } }
        ]
      ).to_a

      diagnoses_data.each do |data|
        facility = Facility.find_by(id: data['_id'])
        if facility
          facility_name = facility.name
        elsif data['_id']
          facility_name = data['_id']
        end
        final_diagnoses << { "facility_name": facility_name, "count": data['diagnoses_count'] }
      end

      data = []
      final_diagnoses = final_diagnoses.group_by { |ele| ele[:facility_name] }
      final_diagnoses.each do |key, value|
        data << { "facility_name": key, "count": value.pluck(:count).sum }
      end

      data = data.sort_by { |ele| ele['count'] }.reverse[0..9]
      [data.pluck(:facility_name).map { |ele| ele.try(:upcase) }, data.pluck(:count)]
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

# age_wise_data = Analytics::ClinicalDataOverview.collection.aggregate(
#   [
#     { '$match' => { group_by.to_s => BSON::ObjectId(eval(group_by.to_s).to_s), 'date' => { '$gte' => start_date, '$lte' => end_date }, 'user_role_ids' => { '$in' => [158965000, '$user_role_ids'] } } },
#     { '$project' => { 'date' => 1, 'patient_age_year' => 1, 'diagnoses_list' => 1 } },
#     { '$unwind' => '$diagnoses_list' },
#     { '$group' => { '_id' => '$diagnoses_list.parent_code', 'year' => { '$first' => '$patient_age_year' }, 'diagnosis_name' => { '$first' => '$diagnoses_list.diagnosis_name' }, 'count' => { '$sum' => '$diagnoses_list.count' } } }
#   ]
# ).to_a
