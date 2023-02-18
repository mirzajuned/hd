module Analytics::Diagnosis
  class ClinicalSection
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze

    def self.call(params, _current_user_id, _current_facility_id, current_organisation_id)
      case_sheet = CaseSheet.find_by(id: params["case_sheet_id"])
      specialty_id = case_sheet.specialty_id

      before_save_params = Hash[params['before_save_diagnosis'].map { |diagnosis| [diagnosis['_id'], { "advised_by_id": diagnosis['advised_by_id'], "date": diagnosis['advised_datetime'].present? ? Date.parse(diagnosis['advised_datetime']).in_time_zone(params['time_zone']) : diagnosis['updated_at'], "facility_id": diagnosis['advised_at_facility_id'], "code": diagnosis['icddiagnosiscode'], "diagnosis_name": diagnosis['diagnosisname'], "icd_type": diagnosis['icd_type'] }] }]

      after_save_params = Hash[params['after_save_diagnosis'].map { |diagnosis| [diagnosis['_id'], { "advised_by_id": diagnosis['advised_by_id'], "date": diagnosis['advised_datetime'].present? ? Date.parse(diagnosis['advised_datetime']).in_time_zone(params['time_zone']) : diagnosis['updated_at'], "facility_id": diagnosis['advised_at_facility_id'], "code": diagnosis['icddiagnosiscode'], "diagnosis_name": diagnosis['diagnosisname'], "icd_type": diagnosis['icd_type'] }] }]

      before_save_diagnosis_codes = before_save_params.keys
      after_save_diagnosis_codes = after_save_params.keys

      existing_ids, new_ids, deleted_ids = find_update_delete_new_ids(before_save_diagnosis_codes, after_save_diagnosis_codes)

      if existing_ids.count > 0
        existing_ids.each do |existing_id|
          update(existing_id, before_save_params, after_save_params, params, current_organisation_id, specialty_id)
        end
      end

      if new_ids.count > 0
        new_ids.each do |new_id|
          create(new_id, after_save_params, params, current_organisation_id, specialty_id)
        end
      end

      if deleted_ids.count > 0
        deleted_ids.each do |deleted_id|
          delete(deleted_id, before_save_params, params, current_organisation_id, specialty_id)
        end
      end
    end

    private

    def self.inc_desc_counts(diagnosis_data, operator, params, current_organisation_id, specialty_id)
      date = diagnosis_data[:date].to_date
      @hashed_data = {}
      @hashed_data['day'] = date.yday
      @hashed_data['week'] = date.cweek
      @hashed_data['month'] = date.month
      @hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        @type = type
        @start_date, @end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)

        counter_value = operator == 'inc' ? 1 : -1
        flag = operator == 'inc' ? 'after' : 'before'
        age_year = params["#{flag}_save_patient_age"].present? ? params["#{flag}_save_patient_age"].split('/')[2] : nil

        advised_record = Analytics::ClinicalDataOverview.find_by(
          user_id: diagnosis_data[:advised_by_id], facility_id: diagnosis_data[:facility_id], date: date,
          specialty_id: specialty_id, patient_gender: params["#{flag}_save_patient_gender"],
          patient_age_year: age_year, data_type: @type, data_type_range: @hashed_data[@type], in_year: @start_date.year
        )

        if advised_record.nil? && operator == 'inc'
          advised_record = create_analytics_record(date, diagnosis_data[:advised_by_id], diagnosis_data[:facility_id], params['after_save_patient_gender'], age_year, current_organisation_id, specialty_id)
        end

        next unless advised_record

        record = advised_record.diagnoses_list.find { |diagnosis| diagnosis['code'] == diagnosis_data[:code] }

        if record
          data_list_array = advised_record.diagnoses_list.reject { |diagnosis| diagnosis['code'] == diagnosis_data[:code] }
          record['count'] = record['count'].to_i + counter_value
          data_list_array << record
          advised_record.diagnoses_list = data_list_array.reject { |ele| ele['count'] <= 0 }
          advised_record.save

        elsif operator == 'inc'
          diagnosis_list = advised_record.diagnoses_list
          user = User.find_by(id: diagnosis_data[:advised_by_id])
          codes_list = user.specialty_ids.include?('309988001') ? Global.send('all_top_icd_diagnosis_codes').codes_list : Global.send('all_top_icd_diagnosis_codes').ortho_codes_list
          parent_code = get_parent_diagnosis_code(diagnosis_data[:code], codes_list)
          diagnosis_list << Hash["count": counter_value, "code": diagnosis_data[:code], "parent_code": parent_code, "diagnosis_name": diagnosis_data[:diagnosis_name]]
          advised_record.diagnoses_list = diagnosis_list
          advised_record.save
        end
      end
    end

    def self.create(diagnosis_id, after_save_params, params, current_organisation_id, specialty_id)
      diagnosis_data = after_save_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]
      inc_desc_counts(diagnosis_data, 'inc', params, current_organisation_id, specialty_id)
    end

    def self.update(diagnosis_id, before_params, after_params, params, current_organisation_id, specialty_id)
      before_save_diagnosis = before_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]
      after_save_diagnosis = after_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]

      if before_save_diagnosis[:advised_by_id] != after_save_diagnosis[:advised_by_id] || before_save_diagnosis['data'] != after_save_diagnosis['data'] || params['before_save_patient_age'] != params['after_save_patient_age'] || params['before_save_patient_gender'] != params['after_save_patient_gender']

        inc_desc_counts(before_save_diagnosis, 'desc', params, current_organisation_id, specialty_id)
      end

      if before_save_diagnosis[:advised_by_id] != after_save_diagnosis[:advised_by_id] || before_save_diagnosis['data'] != after_save_diagnosis['data'] || params['before_save_patient_age'] != params['after_save_patient_age'] || params['before_save_patient_gender'] != params['after_save_patient_gender']

        inc_desc_counts(after_save_diagnosis, 'inc', params, current_organisation_id, specialty_id)
      end
    end

    def self.delete(diagnosis_id, before_save_params, params, current_organisation_id, specialty_id)
      diagnosis_data = before_save_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]
      inc_desc_counts(diagnosis_data, 'desc', params, current_organisation_id, specialty_id)
    end

    def self.find_update_delete_new_ids(before_save_diagnosis_codes, after_save_diagnosis_codes)
      existing_ids = []
      new_ids = []
      deleted_ids = []

      after_save_diagnosis_codes.each do |code|
        if before_save_diagnosis_codes.include?(code)
          existing_ids << code
        else
          new_ids << code
        end
      end

      before_save_diagnosis_codes.each do |code|
        deleted_ids << code unless after_save_diagnosis_codes.include?(code)
      end

      [existing_ids, new_ids, deleted_ids]
    end

    def self.create_analytics_record(date, user_id, facility_id, gender, age, current_organisation_id, specialty_id)
      if date.present? && user_id.present? && facility_id.present? && current_organisation_id.present?
        user = User.find_by(id: user_id)
        record = Analytics::ClinicalDataOverview.new.tap do |diagnosis|
          diagnosis.date = date
          diagnosis.user_id = user_id
          diagnosis.patient_gender = gender
          diagnosis.patient_age_year = age
          diagnosis.user_name = user.fullname
          diagnosis.user_role_ids = user.role_ids
          diagnosis.facility_id = facility_id
          diagnosis.specialty_id = specialty_id
          diagnosis.organisation_id = current_organisation_id
          diagnosis.start_date = @start_date
          diagnosis.end_date = @end_date
          diagnosis.data_type = @type
          diagnosis.data_type_range = @hashed_data[@type]
          diagnosis.in_year = @start_date.year

          diagnosis.save
        end

        record
      end
    end

    def self.get_parent_diagnosis_code(code, codes_list)
      if codes_list.include?(code.upcase)
        code
      elsif code.length >= 3
        code = code.first(-1)
        get_parent_diagnosis_code(code, codes_list)
      end
    end
  end
end
