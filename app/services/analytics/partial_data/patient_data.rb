module Analytics::PartialData
  class PatientData
    def self.get_patient_types(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = set_initial_params(from_date, to_date, label_on)
      organisation_id = BSON::ObjectId(organisation_id.to_s)

      match_with_this = {
        'organisation_id' => organisation_id
      }
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      patient_types_array = ::Analytics::PatientTypeOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$match' => { '$or' => match_with_this2 }
          },
          {
            '$group' => {
              '_id' => '$patient_type_label',
              'total_count' => { '$sum' => '$patient_type_count' }
            }
          }
        ]
      ).to_a

      patient_types_labels = patient_types_array.pluck(:_id)
      patient_types_data = patient_types_array.pluck(:total_count)

      [patient_types_labels, patient_types_data]
    end

    def self.patient_gender_count_data(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = set_initial_params(from_date, to_date, label_on)
      organisation_id = BSON::ObjectId(organisation_id.to_s)

      match_with_this = {
        'reg_hosp_ids' => organisation_id.to_s,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        }
      }

      patient_gender_grp = ::Patient.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$group' => {
              '_id' => '$gender',
              'total_count' => { '$sum' => 1 }
            }
          }
        ]
      ).to_a

      transgender_patient = patient_gender_grp.find { |set| set['_id'] == 'Transgender' }.try(:[], 'total_count').to_i
      male_patient = patient_gender_grp.find { |set| set['_id'] == 'Male' }.try(:[], 'total_count').to_i
      female_patient = patient_gender_grp.find { |set| set['_id'] == 'Female' }.try(:[], 'total_count').to_i
      unspecified_patient = patient_gender_grp.find { |set| set['_id'].nil? }.try(:[], 'total_count').to_i
      unspecified_patient += patient_gender_grp.find { |set| (set['_id'] == '') }.try(:[], 'total_count').to_i
      patient_gender_array = [male_patient, female_patient, transgender_patient, unspecified_patient]

      patient_gender_array
    end

    def self.patient_age_group_count_data(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = set_initial_params(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)

      match_with_this = {
        'reg_hosp_ids' => organisation_id.to_s,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        }
      }

      patient_age_grp_array = ::Patient.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$group' => {
              '_id' => '$age',
              'total_count' => { '$sum' => 1 }
            }
          }
        ]
      ).to_a
      patient_age_array = [patient_age_grp_array.select { |set| set['_id'].to_i <= 20 && !set['_id'].nil? }.pluck('total_count').sum, patient_age_grp_array.select { |set| set['_id'].to_i >= 21 && set['_id'].to_i <= 40 }.pluck('total_count').sum, patient_age_grp_array.select { |set| set['_id'].to_i >= 41 && set['_id'].to_i <= 60 }.pluck('total_count').sum, patient_age_grp_array.select { |set| set['_id'].to_i >= 61 && set['_id'].to_i <= 80 }.pluck('total_count').sum, patient_age_grp_array.select { |set| set['_id'].to_i > 81 }.pluck('total_count').sum]

      patient_age_array
    end

    private

    def self.fetch_params_hash(params_hash = {})
      organisation_id = params_hash['organisation_id']
      facility_id     = params_hash['facility_id']
      from_date       = params_hash['analytics_from_date']
      to_date         = params_hash['analytics_to_date']

      [organisation_id, facility_id, from_date, to_date]
    end

    def self.set_initial_params(from_date, to_date, label_on)
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
