module Analytics::PartialData
  class PatientsHistoryData
    class << self
      include AnalyticsHelper
      def call(params_hash = {})
        organisation_id, _facility_id, from_date, to_date = fetch_params_hash(params_hash)
        disease = params_hash['disease']
        disease = disease

        patient_history_label  = ['0 - 20', '21 - 40', '41 - 60', '> 60']
        patient_history_data   = []
        patient_history_male   = [0, 0, 0, 0]
        patient_history_female = [0, 0, 0, 0]
        patient_history_trans  = [0, 0, 0, 0]
        patient_history_other  = [0, 0, 0, 0]

        year_now = Time.current.year

        # #using aggregate function

        match_with_this = { 'organisation_id' => organisation_id, 'dob_year' => { '$ne' => nil } }
        aggregated_data = Analytics::PatientHistory.collection.aggregate(
          [
            { '$match' => match_with_this },
            {
              '$project' => {
                'age' => { '$subtract' => [year_now, '$dob_year'] },
                'disease' => "$#{disease}",
                'gender' => '$gender'
              }
            },
            {
              '$project' => {
                'age' => 1,
                'disease' => 1,
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
                 'count' => { '$sum' => '$disease' }
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
        male['backgroundColor'] = '#004c6d'
        patient_history_data.push(male)

        female = {}
        female['label'] = 'Female'
        female['data'] = patient_history_female
        female['backgroundColor'] = '#3b849f'
        patient_history_data.push(female)

        trans = {}
        trans['label'] = 'Transgender'
        trans['data'] = patient_history_trans
        trans['backgroundColor'] = '#72c0cf'
        patient_history_data.push(trans)

        other = {}
        other['label'] = 'Other'
        other['data'] = patient_history_other
        other['backgroundColor'] = '#b1ffff'
        patient_history_data.push(other)

        [patient_history_label, patient_history_data, disease]
      end

      def top_five_disease_history(params_hash = {})
        organisation_id, _facility_id, from_date, to_date = fetch_params_hash(params_hash)

        match_with_this = { 'organisation_id' => organisation_id }
        history_data = Analytics::PatientHistory.collection.aggregate(
          [
            { '$match' => match_with_this }
          ]
        ).to_a

        top5_label = []

        top5_data = hashed_data
        loop_disease = disease_histories_list
        if history_data.present?
          history_data.each do |data|
            loop_disease.each do |d|
              next unless top5_data.key?(d) && data[d].present?

              if data['gender'] == 'Male'
                top5_data[d]['Male'] = top5_data[d]['Male'].to_f + data[d].to_f
              elsif data['gender'] == 'Female'
                top5_data[d]['Female'] = top5_data[d]['Female'].to_f + data[d].to_f
              elsif data['gender'] == 'Transgender'
                top5_data[d]['Transgender'] = top5_data[d]['Transgender'].to_f + data[d].to_f
              else
                top5_data[d]['Other'] = top5_data[d]['Other'].to_f + data[d].to_f
              end
              top5_data[d]['value'] = top5_data[d]['value'].to_f + data[d].to_f
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
        male['backgroundColor'] = '#004c6d'
        top5_values.push(male)

        female = {}
        female['label'] = 'Female'
        female['data'] = top5_data_female
        female['backgroundColor'] = '#3b849f'
        top5_values.push(female)

        trans = {}
        trans['label'] = 'Transgender'
        trans['data'] = top5_data_trans
        trans['backgroundColor'] = '#72c0cf'
        top5_values.push(trans)

        other = {}
        other['label'] = 'Other'
        other['data'] = top5_data_other
        other['backgroundColor'] = '#b1ffff'
        top5_values.push(other)

        [top5_label, top5_values]
      end

      def all_history_data(params_hash = {})
        organisation_id, _facility_id, from_date, to_date = fetch_params_hash(params_hash)

        match_with_this = { 'organisation_id' => organisation_id }
        history_data = Analytics::PatientHistory.collection.aggregate(
          [
            { '$match' => match_with_this }
          ]
        ).to_a

        all_diseases = hashed_data
        loop_disease = disease_histories_list
        if history_data.present?
          history_data.each do |data|
            loop_disease.each do |d|
              next unless all_diseases.key?(d) && data[d].present?

              if data['gender'] == 'Male'
                all_diseases[d]['Male'] = all_diseases[d]['Male'].to_f + data[d].to_f
              elsif data['gender'] == 'Female'
                all_diseases[d]['Female'] = all_diseases[d]['Female'].to_f + data[d].to_f
              elsif data['gender'] == 'Transgender'
                all_diseases[d]['Transgender'] = all_diseases[d]['Transgender'].to_f + data[d].to_f
              else
                all_diseases[d]['Other'] = all_diseases[d]['Other'].to_f + data[d].to_f
              end
              all_diseases[d]['value'] = all_diseases[d]['value'].to_f + data[d].to_f
            end
          end
        end

        all_data = all_diseases

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
        male['backgroundColor'] = '#004c6d'
        all_values.push(male)

        female = {}
        female['label'] = 'Female'
        female['data'] = all_data_female
        female['backgroundColor'] = '#3b849f'
        all_values.push(female)

        trans = {}
        trans['label'] = 'Transgender'
        trans['data'] = all_data_trans
        trans['backgroundColor'] = '#72c0cf'
        all_values.push(trans)

        other = {}
        other['label'] = 'Other'
        other['data'] = all_data_other
        other['backgroundColor'] = '#b1ffff'
        all_values.push(other)

        [all_label, all_values]
      end

      private

      def disease_histories_list
        names = [['Diabetes', 'diabetes'], ['Hypertension', 'hypertension'], ['Alcoholism', 'alcoholism'],
                 ['Smoking Tobacco', 'smoking_tobacco'], ['Cardiac Disorder', 'cardiac_disorder'],
                 ['Steroid Intake', 'steroid_intake'], ['Drug Abuse', 'drug_abuse'], ['Hiv Aids', 'hiv_aids'],
                 ['Cancer Tumor', 'cancer_tumor'], ['Tuberculosis', 'tuberculosis'], ['Asthma', 'asthma'],
                 ['Cns Disorder Stroke', 'cns_disorder_stroke'], ['Hypothyroidism', 'hypothyroidism'],
                 ['Hyperthyroidism', 'hyperthyroidism'], ['Hepatitis Cirrhosis', 'hepatitis_cirrhosis'],
                 ['Renal Disorder', 'renal_disorder'], ['Acidity', 'acidity'], ['On insulin', 'on_insulin'],
                 ['On Aspirin Blood Thinners', 'on_aspirin_blood_thinners'], ['Consanguinity', 'consanguinity'],
                 ['Thyroid Disorder', 'thyroid_disorder'], ['Chewing Tobacco', 'chewing_tobacco'],
                 ["Rheumatoid Arthritis", "rheumatoid_arthritis"]]
        names = names.map { |n| n[1] }.sort
        names
      end

      def hashed_data
        { 'acidity' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'alcoholism' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'asthma' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'cancer_tumor' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'cardiac_disorder' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'chewing_tobacco' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'cns_disorder_stroke' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'consanguinity' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'diabetes' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'drug_abuse' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'hepatitis_cirrhosis' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'hiv_aids' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'hypertension' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'hyperthyroidism' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'hypothyroidism' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'on_aspirin_blood_thinners' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'on_insulin' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'renal_disorder' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'smoking_tobacco' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'steroid_intake' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'thyroid_disorder' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 },
          'tuberculosis' => { 'value' => 0, 'Male' => 0, 'Female' => 0, 'Transgender' => 0, 'Other' => 0 } }
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
