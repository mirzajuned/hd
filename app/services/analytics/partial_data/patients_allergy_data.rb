module Analytics::PartialData
  class PatientsAllergyData
    class << self
      include AnalyticsHelper
      def call(params_hash = {})
        organisation_id, _facility_id, from_date, to_date = fetch_params_hash(params_hash)
        allergy = params_hash['allergy']

        patient_allergy_label = ['0 - 20', '21 - 40', '41 - 60', '> 60']
        patient_allergy_data = []
        patient_history_male = [0, 0, 0, 0]
        patient_history_female = [0, 0, 0, 0]
        patient_history_trans  = [0, 0, 0, 0]
        patient_history_other  = [0, 0, 0, 0]
        year_now = Time.current.year

        match_with_this = { 'organisation_id' => organisation_id, 'dob_year' => { '$ne' => nil } }
        aggregated_data = Analytics::PatientHistory.collection.aggregate(
          [
            { '$match' => match_with_this },
            {
              '$project' => {
                'age' => { '$subtract' => [year_now, '$dob_year'] },
                'allergy' => "$#{allergy}",
                'gender' => '$gender'
              }
            },
            {
              '$project' => {
                'age' => 1,
                'allergy' => 1,
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
            },
            {
              '$group' =>
               {
                 '_id' => { 'range' => '$range', 'gender' => '$gender' },
                 'count' => { '$sum' => '$allergy' }
               }
            }
          ]
        ).to_a

        aggregated_data.each do |data_hash|
          data = data_hash['_id']
          if data['range'] == '0 - 20'
            if data['gender'] == 'Male'
              patient_history_male[0] += data_hash['count']
            elsif data['gender'] == 'Female'
              patient_history_female[0] += data_hash['count']
            elsif data['gender'] == 'Transgender'
              patient_history_trans[0] += data_hash['count']
            else
              patient_history_other[0] += data_hash['count']
            end
          elsif data['range'] == '21 - 40'
            if data['gender'] == 'Male'
              patient_history_male[1] += data_hash['count']
            elsif data['gender'] == 'Female'
              patient_history_female[1] += data_hash['count']
            elsif data['gender'] == 'Transgender'
              patient_history_trans[1] += data_hash['count']
            else
              patient_history_other[1] += data_hash['count']
            end
          elsif data['range'] == '41 - 60'
            if data['gender'] == 'Male'
              patient_history_male[2] += data_hash['count']
            elsif data['gender'] == 'Female'
              patient_history_female[2] += data_hash['count']
            elsif data['gender'] == 'Transgender'
              patient_history_trans[2] += data_hash['count']
            else
              patient_history_other[2] += data_hash['count']
            end
          else
            if data['gender'] == 'Male'
              patient_history_male[3] += data_hash['count']
            elsif data['gender'] == 'Female'
              patient_history_female[3] += data_hash['count']
            elsif data['gender'] == 'Transgender'
              patient_history_trans[3] += data_hash['count']
            else
              patient_history_other[3] += data_hash['count']
            end
          end
        end

        male = {}
        male['label'] = 'Male'
        male['data'] = patient_history_male
        male['backgroundColor'] = '#003f5c'
        patient_allergy_data.push(male)

        female = {}
        female['label'] = 'Female'
        female['data'] = patient_history_female
        female['backgroundColor'] = '#7a5195'
        patient_allergy_data.push(female)

        trans = {}
        trans['label'] = 'Transgender'
        trans['data'] = patient_history_trans
        trans['backgroundColor'] = '#ef5675'
        patient_allergy_data.push(trans)

        other = {}
        other['label'] = 'Other'
        other['data'] = patient_history_other
        other['backgroundColor'] = '#ffa600'
        patient_allergy_data.push(other)

        [patient_allergy_label, patient_allergy_data, allergy]
      end

      def top_five_allergy_history(params_hash)
        organisation_id, _facility_id, from_date, to_date = fetch_params_hash(params_hash)

        match_with_this = { 'organisation_id' => organisation_id }
        allergy_data = Analytics::PatientHistory.collection.aggregate(
          [
            { '$match' => match_with_this }
          ]
        ).to_a

        top5_data = hashed_data
        loop_disease = eye_drop_allergy__historylist
        if allergy_data.present?
          allergy_data.each do |data|
            loop_disease.each do |d|
              in_hash = data[d]
              next unless top5_data.key?(d)

              if data['gender'] == 'Male'
                top5_data[d]['Male'] += data[d]
              elsif data['gender'] == 'Female'
                top5_data[d]['Female'] += data[d]
              elsif data['gender'] == 'Transgender'
                top5_data[d]['Transgender'] += data[d]
              else
                top5_data[d]['Other'] += data[d]
              end
              top5_data[d]['value'] += data[d]
            end
          end
        end

        top5_data = top5_data.sort_by { |k| k[1]['value'] }.reverse
        top5_data = top5_data.take(5)
        top5_label = []
        top5_values = []
        top5_data_male = []
        top5_data_female = []
        top5_data_trans = []
        top5_data_other = []
        top5_data.each_with_index do |keys, ind|
          top5_label.push(keys[0].try(:humanize).try(:titleize))
          top5_data_male[ind] = keys[1]['Male']
          top5_data_female[ind] = keys[1]['Female']
          top5_data_trans[ind] = keys[1]['Transgender']
          top5_data_other[ind] = keys[1]['Other']
        end

        male = {}
        male['label'] = 'Male'
        male['data'] = top5_data_male
        male['backgroundColor'] = '#003f5c'
        top5_values.push(male)

        female = {}
        female['label'] = 'Female'
        female['data'] = top5_data_female
        female['backgroundColor'] = '#7a5195'
        top5_values.push(female)

        trans = {}
        trans['label'] = 'Transgender'
        trans['data'] = top5_data_trans
        trans['backgroundColor'] = '#ef5675'
        top5_values.push(trans)

        other = {}
        other['label'] = 'Other'
        other['data'] = top5_data_other
        other['backgroundColor'] = '#ffa600'
        top5_values.push(other)

        [top5_label, top5_values]
      end

      def all_allergy_data(params_hash = {})
        organisation_id, _facility_id, from_date, to_date = fetch_params_hash(params_hash)

        match_with_this = { 'organisation_id' => organisation_id }
        allergy_data = Analytics::PatientHistory.collection.aggregate(
          [
            { '$match' => match_with_this }
          ]
        ).to_a
        all_data = hashed_data
        loop_disease = eye_drop_allergy__historylist
        if allergy_data.present?
          allergy_data.each do |data|
            loop_disease.each do |d|
              next unless all_data.key?(d)

              if data['gender'] == 'Male'
                all_data[d]['Male'] += data[d]
              elsif data['gender'] == 'Female'
                all_data[d]['Female'] += data[d]
              elsif data['gender'] == 'Transgender'
                all_data[d]['Transgender'] += data[d]
              else
                all_data[d]['Other'] += data[d]
              end
              all_data[d]['value'] += data[d]
            end
          end
        end

        all_label = []
        all_values = []
        all_data_male = []
        all_data_female = []
        all_data_trans = []
        all_data_other = []
        all_data.each_with_index do |keys, ind|
          all_label.push(keys[0].try(:humanize).try(:titleize))
          all_data_male[ind] = keys[1]['Male']
          all_data_female[ind] = keys[1]['Female']
          all_data_trans[ind] = keys[1]['Transgender']
          all_data_other[ind] = keys[1]['Other']
        end

        male = {}
        male['label'] = 'Male'
        male['data'] = all_data_male
        male['backgroundColor'] = '#003f5c'
        all_values.push(male)

        female = {}
        female['label'] = 'Female'
        female['data'] = all_data_female
        female['backgroundColor'] = '#7a5195'
        all_values.push(female)

        trans = {}
        trans['label'] = 'Transgender'
        trans['data'] = all_data_trans
        trans['backgroundColor'] = '#ef5675'
        all_values.push(trans)

        other = {}
        other['label'] = 'Other'
        other['data'] = all_data_other
        other['backgroundColor'] = '#ffa600'
        all_values.push(other)

        [all_label, all_values]
      end

      private

      def eye_drop_allergy__historylist
        names = [['Tropicamide_P', 'tropicamide_p'], ['Tropicamide', 'tropicamide'], ['Timolol', 'timolol'],
                 ['Homide', 'homide'], ['Latanoprost', 'latanoprost'], ['Brimonidine', 'brimonidine'],
                 ['Travoprost', 'travoprost'], ['Tobramycin', 'tobramycin'], ['Moxifloxacin', 'moxifloxacin'],
                 ['Homatropine', 'homatropine'], ['Pilocarpine', 'pilocarpine'], ['Cyclopentolate', 'cyclopentolate'],
                 ['Atropine', 'atropine'], ['Phenylephrine', 'phenylephrine'], ['Tropicacyl', 'tropicacyl'],
                 ['Paracain', 'paracain'], ['Ciplox', 'ciplox'],
                 ["Tropicamide P + Distilled Water","tropicamide_p_distilled_water" ],
                 ["Tropicamide P + Lubrex","tropicamide_p_lubrex" ]]
        names = names.map { |n| n[1] }.sort
        names
      end

      def hashed_data
        { 'atropine' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'brimonidine' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'ciplox' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'cyclopentolate' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'homatropine' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'homide' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'latanoprost' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'moxifloxacin' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'paracain' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'phenylephrine' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'pilocarpine' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'timolol' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'tobramycin' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'travoprost' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'tropicacyl' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'tropicamide' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'tropicamide_p' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'tropicamide_p_distilled_water' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0,
          'Other' => 0 },
          'tropicamide_p_lubrex' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 }}
      end

      def fetch_params_hash(params_hash)
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']

        [organisation_id, facility_id, from_date, to_date]
      end
    end
  end
end
