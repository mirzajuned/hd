module Analytics::PartialData
  class PatientOutcome
    def self.call(organisation_id, facility_id, from_date, to_date); end

    def self.marked_complicated_data(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this },
          { '$project' => {
            'facility_id' => '$facility_id',
            'gender' => '$patient_gender',
            'range' => {
              'complicated' => { '$cond' => [{ '$eq' => ['$has_complication', 'Yes'] }, 1, 0] },
              'not_complicated' => { '$cond' => [{ '$eq' => ['$has_complication', 'No'] }, 1, 0] },
              'not_filled' => { '$cond' => [{ '$eq' => ['$has_complication', ''] }, 1, 0] }
            }
          } },
          { '$group' => {
            '_id' => '$facility_id',
            'complicated' => { '$sum' => '$range.complicated' },
            'not_complicated' => { '$sum' => '$range.not_complicated' },
            'not_filled' => { '$sum' => '$range.not_filled' }
          } }
        ]
      ).to_a

      all_facility_name = []
      all_complicated_surgery = []
      all_not_complicated_surgery = []

      if data.length > 5
        all_facility_name = data.map { |fac_id| Facility.find_by(id: fac_id['_id']).try(:name) }
        all_complicated_surgery = data.map { |fac_id| fac_id['complicated'] }
        all_not_complicated_surgery = data.map { |fac_id| fac_id['not_complicated'] }
      end
      sorted_data = data.sort_by { |k| k['complicated'] }.reverse.take(5)

      facility_name_label = sorted_data.map { |fac_id| Facility.find_by(id: fac_id['_id']).try(:abbreviation) }
      complicated_surgery = sorted_data.map { |fac_id| fac_id['complicated'] }
      not_complicated_surgery = sorted_data.map { |fac_id| fac_id['not_complicated'] }

      [facility_name_label, complicated_surgery, not_complicated_surgery, all_facility_name, all_complicated_surgery, all_not_complicated_surgery]
    end

    def self.facility_wise_elective_emergency(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this },
          { '$project' => {
            'facility_id' => '$facility_id',
            'gender' => '$patient_gender',
            'range' => {
              'emergency' => { '$cond' => [{ '$eq' => ['$type_of_surgery_performed', 'Emergency'] }, 1, 0] },
              'elective' => { '$cond' => [{ '$eq' => ['$type_of_surgery_performed', 'Elective'] }, 1, 0] },
              'not_filled' => { '$cond' => [{ '$eq' => ['$type_of_surgery_performed', ''] }, 1, 0] }
            }
          } },
          { '$group' => {
            '_id' => '$facility_id',
            'emergency' => { '$sum' => '$range.emergency' },
            'elective' => { '$sum' => '$range.elective' },
            'not_filled' => { '$sum' => '$range.not_filled' }
          } }
        ]
      ).to_a

      all_facility_name_labels_emergency = []
      all_emergency = []
      all_elective = []
      all_not_filled = []

      sorted_data = data.sort_by { |k| k['emergency'] }.reverse

      all_facility_name_labels_emergency = sorted_data.map { |fac_id| Facility.find_by(id: fac_id['_id']).try(:abbreviation) }
      all_emergency = sorted_data.map { |fac_id| fac_id['emergency'] }
      all_elective = sorted_data.map { |fac_id| fac_id['elective'] }
      all_not_filled = sorted_data.map { |fac_id| fac_id['not_filled'] }

      facility_name_labels = all_facility_name_labels_emergency.take(5)
      emergency = all_emergency.take(5)
      elective = all_elective.take(5)
      not_filled = all_not_filled.take(5)

      [facility_name_labels, emergency, elective, not_filled, all_facility_name_labels_emergency, all_emergency, all_elective, all_not_filled]
    end

    def self.patients_count_bcva_near(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      labels_eye_sight_left_near = ['6/6', '6/9', '6/12', '6/18', '6/36']

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this },
          { '$project' => {
            'bestcorrected_va_post_surgery_left_near' => 1,
            'bestcorrected_va_post_surgery_right_near' => 1,
            'patient_gender' => 1,
            'has_complication' => 1,
            'range' => {
              'six_by_six_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_near', '6/6'] }, 1, 0] },
              'six_by_nine_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_near', '6/9'] }, 1, 0] },
              'six_by_twelve_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_near', '6/12'] }, 1, 0] },
              'six_by_eighteen_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_near', '6/18'] }, 1, 0] },
              'six_by_thirty_six_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_near', '6/36'] }, 1, 0] },
              'six_by_six_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_near', '6/6'] }, 1, 0] },
              'six_by_nine_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_near', '6/9'] }, 1, 0] },
              'six_by_twelve_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_near', '6/12'] }, 1, 0] },
              'six_by_eighteen_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_near', '6/18'] }, 1, 0] },
              'six_by_thirty_six_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_near', '6/36'] }, 1, 0] }
            }
          } }, {
            '$group' => {
              '_id' => '$has_complication',
              'six_by_six_left' => { '$sum' => '$range.six_by_six_left' },
              'six_by_nine_left' => { '$sum' => '$range.six_by_nine_left' },
              'six_by_twelve_left' => { '$sum' => '$range.six_by_twelve_left' },
              'six_by_eighteen_left' => { '$sum' => '$range.six_by_eighteen_left' },
              'six_by_thirty_six_left' => { '$sum' => '$range.six_by_thirty_six_left' },
              'six_by_six_right' => { '$sum' => '$range.six_by_six_right' },
              'six_by_nine_right' => { '$sum' => '$range.six_by_nine_right' },
              'six_by_twelve_right' => { '$sum' => '$range.six_by_twelve_right' },
              'six_by_eighteen_right' => { '$sum' => '$range.six_by_eighteen_right' },
              'six_by_thirty_six_right' => { '$sum' => '$range.six_by_thirty_six_right' }
            }
          }, {
            '$project' => {
              '_id' => '$_id',
              'six_by_six' => { '$sum' => ['$six_by_six_left', '$six_by_six_right'] },
              'six_by_nine' => { '$sum' => ['$six_by_nine_left', '$six_by_nine_right'] },
              'six_by_twelve' => { '$sum' => ['$six_by_twelve_left', '$six_by_twelve_right'] },
              'six_by_eighteen' => { '$sum' => ['$six_by_eighteen_left', '$six_by_eighteen_right'] },
              'six_by_thirty_six' => { '$sum' => ['$six_by_thirty_six_left', '$six_by_thirty_six_right'] }

            }
          }
        ]
      ).to_a

      if data.find { |set| set['_id'] == 'No' }.present?
        data_with_no = data.find { |set| set['_id'] == 'No' }
        not_complicated_data = data_with_no.values
        remove_no = not_complicated_data.shift
        not_complicated_data = not_complicated_data
      else
        not_complicated_data = [0, 0, 0, 0, 0]
      end

      if data.find { |set| set['_id'] == 'Yes' }.present?
        data_with_yes = data.find { |set| set['_id'] == 'Yes' }
        complicated_data = data_with_yes.values
        remove_yes = complicated_data.shift
        complicated_data = complicated_data
      else
        complicated_data = [0, 0, 0, 0, 0]
      end

      [labels_eye_sight_left_near, not_complicated_data, complicated_data]
    end

    def self.patients_count_bcva_far(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      labels_eye_sight_left_near = ['6/6', '6/9', '6/12', '6/18', '6/36']

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this },
          { '$project' => {
            'bestcorrected_va_post_surgery_left_far' => 1,
            'bestcorrected_va_post_surgery_right_far' => 1,
            'patient_gender' => 1,
            'has_complication' => 1,
            'range' => {
              'six_by_six_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_far', '6/6'] }, 1, 0] },
              'six_by_nine_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_far', '6/9'] }, 1, 0] },
              'six_by_twelve_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_far', '6/12'] }, 1, 0] },
              'six_by_eighteen_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_far', '6/18'] }, 1, 0] },
              'six_by_thirty_six_left' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_left_far', '6/36'] }, 1, 0] },
              'six_by_six_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_far', '6/6'] }, 1, 0] },
              'six_by_nine_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_far', '6/9'] }, 1, 0] },
              'six_by_twelve_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_far', '6/12'] }, 1, 0] },
              'six_by_eighteen_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_far', '6/18'] }, 1, 0] },
              'six_by_thirty_six_right' => { '$cond' => [{ '$eq' => ['$bestcorrected_va_post_surgery_right_far', '6/36'] }, 1, 0] }
            }
          } }, {
            '$group' => {
              '_id' => '$has_complication',
              'six_by_six_left' => { '$sum' => '$range.six_by_six_left' },
              'six_by_nine_left' => { '$sum' => '$range.six_by_nine_left' },
              'six_by_twelve_left' => { '$sum' => '$range.six_by_twelve_left' },
              'six_by_eighteen_left' => { '$sum' => '$range.six_by_eighteen_left' },
              'six_by_thirty_six_left' => { '$sum' => '$range.six_by_thirty_six_left' },
              'six_by_six_right' => { '$sum' => '$range.six_by_six_right' },
              'six_by_nine_right' => { '$sum' => '$range.six_by_nine_right' },
              'six_by_twelve_right' => { '$sum' => '$range.six_by_twelve_right' },
              'six_by_eighteen_right' => { '$sum' => '$range.six_by_eighteen_right' },
              'six_by_thirty_six_right' => { '$sum' => '$range.six_by_thirty_six_right' }
            }
          }, {
            '$project' => {
              '_id' => '$_id',
              'six_by_six' => { '$sum' => ['$six_by_six_left', '$six_by_six_right'] },
              'six_by_nine' => { '$sum' => ['$six_by_nine_left', '$six_by_nine_right'] },
              'six_by_twelve' => { '$sum' => ['$six_by_twelve_left', '$six_by_twelve_right'] },
              'six_by_eighteen' => { '$sum' => ['$six_by_eighteen_left', '$six_by_eighteen_right'] },
              'six_by_thirty_six' => { '$sum' => ['$six_by_thirty_six_left', '$six_by_thirty_six_right'] }

            }
          }
        ]
      ).to_a

      if data.find { |set| set['_id'] == 'No' }.present?
        data_with_no = data.find { |set| set['_id'] == 'No' }
        not_complicated_data = data_with_no.values
        remove_no = not_complicated_data.shift
        not_complicated_data = not_complicated_data
      else
        not_complicated_data = [0, 0, 0, 0, 0]
      end

      if data.find { |set| set['_id'] == 'Yes' }.present?
        data_with_yes = data.find { |set| set['_id'] == 'Yes' }
        complicated_data = data_with_yes.values
        remove_yes = complicated_data.shift
        complicated_data = complicated_data
      else
        complicated_data = [0, 0, 0, 0, 0]
      end

      [labels_eye_sight_left_near, not_complicated_data, complicated_data]
    end

    def self.patient_count_surgery_type(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this }, {
            '$group' => {
              '_id' => '$surgery_code',
              'count' => { "$sum": 1 }
            }
          }
        ]
      ).to_a

      cataract_count = 0
      cornea_count   = 0
      count_data = []
      helper_instance = Analytics::PatientOutcome::LogmarValues.new
      cataract_data = helper_instance.cataract_procedures
      cornea_data = helper_instance.cornea_procedures

      data.each do |surgery_code|
        id = surgery_code['_id']
        cataract_count += surgery_code['count'] if cataract_data.key?(id)
        cornea_count += surgery_code['count'] if cornea_data.key?(id)
      end
      lable = ['Cataract', 'Cornea']
      count_data.push(cataract_count)
      count_data.push(cornea_count)

      [lable, count_data]
    end

    def self.patient_count_by_cornia_surgery_type(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      helper_instance = Analytics::PatientOutcome::LogmarValues.new
      cornea_data_hash = helper_instance.cornea_procedures
      cornea_data      = cornea_data_hash.keys
      cataract_data_hash = helper_instance.cataract_procedures
      cataract_data = cataract_data_hash.keys

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this }, {
            '$group' => {
              '_id' => '$surgery_code',
              'count' => { '$sum' => 1 }
            }
          }
        ]
      ).to_a

      labels_cornea = []
      cornea_count_data = []
      labels_cataract = []
      cataract_count_data = []

      data.each do |set|
        id = set['_id']
        if cornea_data.include?(id)
          labels_cornea.push(cornea_data_hash[id])
          cornea_count_data.push(set['count'])
        end
        if cataract_data.include?(id)
          labels_cataract.push(cataract_data_hash[id])
          cataract_count_data.push(set['count'])
        end
      end

      [labels_cornea, cornea_count_data, labels_cataract, cataract_count_data]
    end

    def self.patient_count_by_diagnosis_gender(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      helper_instance = Analytics::PatientOutcome::LogmarValues.new
      cornea_data_hash = helper_instance.cornea_procedures
      cornea_data      = cornea_data_hash.keys
      cataract_data_hash = helper_instance.cataract_procedures
      cataract_data = cataract_data_hash.keys

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this }, {
            '$project' => {
              'surgery_code' => '$surgery_code',
              'gender' => '$patient_gender'
            }
          }
        ]
      ).to_a

      labels_cataract = []
      cataract_male   = []
      cataract_female = []
      cataract_trans  = []
      cataract_other  = []
      cataract_hashed = {}

      labels_cornea   = []
      cornea_male     = []
      cornea_female   = []
      cornea_trans    = []
      cornea_other    = []
      cornea_hashed   = {}

      data.each do |row|
        code = row['surgery_code']
        gender = row['gender'].try(:downcase)
        if cataract_data.include?(code)
          if cataract_hashed.key?(code)
            cataract_hashed[code]['other'] = (cataract_hashed[code]['other'] += 1) if gender.blank?
            cataract_hashed[code][gender]  = (cataract_hashed[code][gender] += 1) unless gender.blank?
          else
            cataract_hashed[code] = create_hashed('male', 'female', 'transgender', 'other')
            cataract_hashed[code]['other'] = (cataract_hashed[code]['other'] += 1) if gender.blank?
            cataract_hashed[code][gender]  = (cataract_hashed[code][gender] += 1) unless gender.blank?
            labels_cataract.push(cataract_data_hash[code])
          end
        end
        if cornea_data.include?(code)
          if cornea_hashed.key?(code)
            cornea_hashed[code]['other'] = (cornea_hashed[code]['other'] += 1) if gender.blank?
            cornea_hashed[code][gender]  = (cornea_hashed[code][gender] += 1) unless gender.blank?
          else
            cornea_hashed[code] = create_hashed('male', 'female', 'transgender', 'other')
            cornea_hashed[code]['other'] = (cornea_hashed[code]['other'] += 1) if gender.blank?
            cornea_hashed[code][gender]  = (cornea_hashed[code][gender] += 1) unless gender.blank?
            labels_cornea.push(cornea_data_hash[code])
          end
        end
      end

      cataract_hashed['cataract'] = create_hashed('male', 'female', 'transgender', 'other') if cataract_hashed.empty?

      cornea_hashed['cornea'] = create_hashed('male', 'female', 'transgender', 'other') if cornea_hashed.empty?
      cataract_hashed.each_with_index do |key, _array|
        at_first = key[1]
        cataract_male.push(at_first['male'])
        cataract_female.push(at_first['female'])
        cataract_trans.push(at_first['transgender'])
        cataract_other.push(at_first['other'])
      end

      cornea_hashed.each_with_index do |key, _array|
        at_first = key[1]
        cornea_male.push(at_first['male'])
        cornea_female.push(at_first['female'])
        cornea_trans.push(at_first['transgender'])
        cornea_other.push(at_first['other'])
      end

      [labels_cataract, cataract_male, cataract_female, cataract_trans, cataract_other, labels_cornea, cornea_male, cornea_female, cornea_trans, cornea_other]
    end

    def self.patients_count_by_laterality(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this }, {
            '$project' => {
              'laterality' => '$laterality',
              'gender' => '$patient_gender'
            }
          }, {
            '$group' => {
              '_id' => '$laterality',
              'gender' => {
                '$push' => '$gender'
              }
            }
          }
        ]
      ).to_a

      laterality = { '40638003' => 'Bilateral', '18944008' => 'Right', '8966001' => 'Left' }
      laterality_labels = laterality.values
      male_data = []
      female_data = []
      trans_data  = []
      other_data  = []
      laterality.each do |key, _value|
        find_data = data.find { |row| row['_id'] == key }
        if find_data.present?
          gender_data = find_data['gender']
          male_data.push(gender_data.count('Male'))
          female_data.push(gender_data.count('Female'))
          trans_data.push(gender_data.count('Transgender'))
          other_data.push(gender_data.count(nil))
        else
          male_data.push(0)
          female_data.push(0)
          trans_data.push(0)
          other_data.push(0)
        end
      end

      [laterality_labels, male_data, female_data, trans_data, other_data]
    end

    def self.patients_count_by_surgery_age_cataract(params_hash = {})
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date)
      data = []
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'complete_data' => true
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      helper_instance = Analytics::PatientOutcome::LogmarValues.new
      cornea_data_hash = helper_instance.cornea_procedures
      cornea_data      = cornea_data_hash.keys
      cataract_data_hash = helper_instance.cataract_procedures
      cataract_data = cataract_data_hash.keys

      year_now = Time.now.year

      data = Analytics::Ophthalmology::PatientSurgicalOutcome.collection.aggregate(
        [
          { '$match' => match_with_this },
          {
            '$project' => {
              'age' => { '$subtract' => [year_now, '$patient_dob_year'] },
              'surgery_code' => '$surgery_code',
              'gender' => '$patient_gender'
            }
          },
          {
            '$project' => {
              'age' => 1,
              'surgery_code' => 1,
              'gender' => 1,
              'range' => {
                '$concat' => [
                  { '$cond' => [{ '$lt' => ['$age', 0] }, 'Unknown', ''] },
                  { '$cond' => [{ '$and' => [{ '$gte' => ['$age', 0] }, { '$lte' => ['$age', 20] }] }, '0 - 20', ''] },
                  { '$cond' => [{ '$and' => [{ '$gte' => ['$age', 21] }, { '$lte' => ['$age', 40] }] }, '21 - 40', ''] },
                  { '$cond' => [{ '$and' => [{ '$gte' => ['$age', 41] }, { '$lte' => ['$age', 60] }] }, '41 - 60', ''] },
                  { '$cond' => [{ '$gte' => ['$age', 61] }, '61 +', ''] }
                ]
              }
            }
          }
        ]
      ).to_a

      cataract_hashed = {}
      labels_cataract = []
      cataract_0_20   = []
      cataract_21_40  = []
      cataract_41_60  = []
      cataract_61     = []

      cornea_hashed = {}
      labels_cornea = []
      cornea_0_20   = []
      cornea_21_40  = []
      cornea_41_60  = []
      cornea_61     = []

      data.each do |row|
        code = row['surgery_code']
        range = row['range']
        # cataract data
        if cataract_data.include?(code)
          if cataract_hashed.key?(code)
            cataract_hashed[code][range] = cataract_hashed[code][range] += 1
          else
            cataract_hashed[code] = create_hashed('0 - 20', '21 - 40', '41 - 60', '61 +')
            cataract_hashed[code][range] = cataract_hashed[code][range] += 1
            labels_cataract.push(cataract_data_hash[code])
          end
        end
        # cornea data
        if cornea_data.include?(code)
          if cornea_hashed.key?(code)
            cornea_hashed[code][range] = cornea_hashed[code][range] += 1
          else
            cornea_hashed[code] = create_hashed('0 - 20', '21 - 40', '41 - 60', '61 +')
            cornea_hashed[code][range] = cornea_hashed[code][range] += 1
            labels_cornea.push(cornea_data_hash[code])
          end
        end
      end

      cataract_hashed['cataract'] = create_hashed('0 - 20', '21 - 40', '41 - 60', '61 +') if cataract_hashed.empty?
      cornea_hashed['cornea'] = create_hashed('0 - 20', '21 - 40', '41 - 60', '61 +') if cornea_hashed.empty?

      cataract_hashed.each_with_index do |key, _array|
        at_first = key[1]
        cataract_0_20.push(at_first['0 - 20'])
        cataract_21_40.push(at_first['21 - 40'])
        cataract_41_60.push(at_first['41 - 60'])
        cataract_61.push(at_first['61 +'])
      end

      cornea_hashed.each_with_index do |key, _array|
        at_first = key[1]
        cornea_0_20.push(at_first['0 - 20'])
        cornea_21_40.push(at_first['21 - 40'])
        cornea_41_60.push(at_first['41 - 60'])
        cornea_61.push(at_first['61 +'])
      end

      [labels_cataract, cataract_0_20, cataract_21_40, cataract_41_60, cataract_61, labels_cornea, cornea_0_20, cornea_21_40, cornea_41_60, cornea_61]
    end

    def self.create_hashed(*args)
      hashed = {}
      args.each do |key|
        hashed[key] = 0
      end
      hashed
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

    def self.set_initial_params(from_date, to_date)
      from_date = Date.parse(from_date)
      to_date = Date.parse(to_date)

      [from_date, to_date]
    end
  end
end
