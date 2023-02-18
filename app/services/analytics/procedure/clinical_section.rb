module Analytics::Procedure
  class ClinicalSection
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze

    def self.call(params, _current_user_id, _current_facility_id, current_organisation_id)
      case_sheet = CaseSheet.find_by(id: params['case_sheet_id'])
      specialty_id = case_sheet.specialty_id

      before_save_params = Hash[params['before_save_procedure'].map { |procedure| [procedure['_id'], { "advised_by_id": procedure['advised_by_id'], "date": procedure['advised_datetime'].present? ? Date.parse(procedure['advised_datetime']).in_time_zone(params['time_zone']) : procedure['updated_at'], "facility_id": procedure['advised_at_facility_id'], "code": procedure['procedurefullcode'], "procedure_name": procedure['procedurename'], "procedure_type": procedure['procedure_type'] }] }]

      after_save_params = Hash[params['after_save_procedure'].map { |procedure| [procedure['_id'], { "advised_by_id": procedure['advised_by_id'], "date": procedure['advised_datetime'].present? ? Date.parse(procedure['advised_datetime']).in_time_zone(params['time_zone']) : procedure['updated_at'], "facility_id": procedure['advised_at_facility_id'], "code": procedure['procedurefullcode'], "procedure_name": procedure['procedurename'], "procedure_type": procedure['procedure_type'] }] }]

      before_save_procedure_codes = before_save_params.keys
      after_save_procedure_codes = after_save_params.keys

      existing_ids, new_ids, deleted_ids = find_update_delete_new_ids(before_save_procedure_codes, after_save_procedure_codes)

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

    def self.inc_desc_counts(procedure_data, operator, params, current_organisation_id, specialty_id)
      date = procedure_data[:date].to_date
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
          user_id: procedure_data[:advised_by_id], facility_id: procedure_data[:facility_id],
          specialty_id: specialty_id, date: date, patient_gender: params["#{flag}_save_patient_gender"],
          patient_age_year: age_year, data_type: @type, data_type_range: @hashed_data[@type], in_year: @start_date.year
        )

        if advised_record.nil? && operator == 'inc'
          advised_record = create_analytics_record(date, procedure_data[:advised_by_id], procedure_data[:facility_id], params['after_save_patient_gender'], age_year, current_organisation_id, specialty_id)
        end

        next unless advised_record

        record = advised_record.procedures_list.find { |procedure| procedure['code'] == procedure_data[:code] }

        if record
          data_list_array = advised_record.procedures_list.reject { |procedure| procedure['code'] == procedure_data[:code] }
          record['count'] = record['count'].to_i + counter_value
          data_list_array << record
          advised_record.procedures_list = data_list_array.reject { |ele| ele['count'] <= 0 }
          advised_record.save

        elsif operator == 'inc'
          procedure_list = advised_record.procedures_list
          procedure_list << Hash["count": counter_value, "code": procedure_data[:code], "procedure_name": procedure_data[:procedure_name]]
          advised_record.procedures_list = procedure_list
          advised_record.save
        end
      end
    end

    def self.create(procedure_id, after_save_params, params, current_organisation_id, specialty_id)
      procedure_data = after_save_params.select { |procedure| procedure == procedure_id }.values[0]
      inc_desc_counts(procedure_data, 'inc', params, current_organisation_id, specialty_id)
    end

    def self.update(procedure_id, before_params, after_params, params, current_organisation_id, specialty_id)
      before_save_procedure = before_params.select { |procedure| procedure == procedure_id }.values[0]
      after_save_procedure = after_params.select { |procedure| procedure == procedure_id }.values[0]

      if before_save_procedure[:advised_by_id] != after_save_procedure[:advised_by_id] || before_save_procedure['data'] != after_save_procedure['data'] || params['before_save_patient_age'] != params['after_save_patient_age'] || params['before_save_patient_gender'] != params['after_save_patient_gender']
        inc_desc_counts(before_save_procedure, 'desc', params, current_organisation_id, specialty_id)
        inc_desc_counts(after_save_procedure, 'inc', params, current_organisation_id, specialty_id)
      end
    end

    def self.delete(procedure_id, before_save_params, params, current_organisation_id, specialty_id)
      procedure_data = before_save_params.select { |procedure| procedure == procedure_id }.values[0]
      inc_desc_counts(procedure_data, 'desc', params, current_organisation_id, specialty_id)
    end

    def self.find_update_delete_new_ids(before_save_procedure_codes, after_save_procedure_codes)
      existing_ids = []
      new_ids = []
      deleted_ids = []

      after_save_procedure_codes.each do |code|
        if before_save_procedure_codes.include?(code)
          existing_ids << code
        else
          new_ids << code
        end
      end

      before_save_procedure_codes.each do |code|
        deleted_ids << code unless after_save_procedure_codes.include?(code)
      end

      [existing_ids, new_ids, deleted_ids]
    end

    def self.create_analytics_record(date, user_id, facility_id, gender, age, current_organisation_id, specialty_id)
      if date.present? && user_id.present? && facility_id.present? && current_organisation_id.present?
        user = User.find_by(id: user_id)
        record = Analytics::ClinicalDataOverview.new.tap do |procedure|
          procedure.date = date
          procedure.user_id = user_id
          procedure.patient_gender = gender
          procedure.patient_age_year = age
          procedure.user_name = user.fullname
          procedure.user_role_ids = user.role_ids
          procedure.facility_id = facility_id
          procedure.specialty_id = specialty_id
          procedure.organisation_id = current_organisation_id
          procedure.start_date = @start_date
          procedure.end_date = @end_date
          procedure.data_type = @type
          procedure.data_type_range = @hashed_data[@type]
          procedure.in_year = @start_date.year

          procedure.save
        end

        record
      end
    end
  end
end
