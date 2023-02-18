module Analytics::Investigations
  class ClinicalSection
    class << self
      DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze

      def call(params, current_user_id, _current_facility_id, current_organisation_id)
        case_sheet = CaseSheet.find_by(id: params['case_sheet_id'])
        specialty_id = case_sheet.specialty_id

        current_user = User.find_by(id: current_user_id)
        @role_ids = current_user&.role_ids
        @investigations = ['ophthal_investigations', 'laboratory_investigations', 'radiology_investigations']

        @investigations.each do |investigation|
          next unless params["before_save_#{investigation}"].count > 0 || params["after_save_#{investigation}"].count > 0

          before_params, after_params = get_final_investigations_hash(params, investigation)

          existing_ids, new_ids, deleted_ids = find_existing_delete_new_ids(before_params.keys, after_params.keys)

          existing_ids.each do |existing_id|
            update(existing_id, before_params, after_params, params, current_organisation_id, investigation, specialty_id)
          end

          new_ids.each do |new_id|
            create(new_id, after_params, params, current_organisation_id, investigation, specialty_id)
          end

          deleted_ids.each do |deleted_id|
            delete(deleted_id, before_params, params, current_organisation_id, investigation, specialty_id)
          end
        end
      end

      private

      def get_final_investigations_hash(params, investigation)
        before_hash = params["before_save_#{investigation}"]
        after_hash = params["after_save_#{investigation}"]

        before = Hash[before_hash.map { |inv| [inv['_id'], { "advised_by_id": inv['advised_by_id'], "counselled_by_id": inv['counselled_by_id'], "is_counselled": inv['is_counselled'], "code": inv['investigation_id'], "investigation_name": inv['investigationname'], "date": inv['advised_datetime'].present? ? Date.parse(inv['advised_datetime']).in_time_zone(params['time_zone']) : inv['updated_at'], "facility_id": inv['advised_at_facility_id'] }] }]

        after = Hash[after_hash.map { |inv| [inv['_id'], { "advised_by_id": inv['advised_by_id'], "counselled_by_id": inv['counselled_by_id'], "is_counselled": inv['is_counselled'], "code": inv['investigation_id'], "investigation_name": inv['investigationname'], "date": inv['advised_datetime'].present? ? Date.parse(inv['advised_datetime']).in_time_zone(params['time_zone']) : inv['updated_at'], "facility_id": inv['advised_at_facility_id'] }] }]

        [before, after]
      end

      def inc_desc_counts(investigation_data, operator, params, current_organisation_id, investigation_type, specialty_id)
        date = investigation_data[:date].to_date
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

          analytics_record = Analytics::ClinicalDataOverview.find_by(
            user_id: investigation_data[:advised_by_id], facility_id: investigation_data[:facility_id], date: date,
            specialty_id: specialty_id, patient_gender: params["#{flag}_save_patient_gender"], data_type: @type,
            patient_age_year: age_year, data_type_range: @hashed_data[@type], in_year: @start_date.year
          )

          if analytics_record.nil? && operator == 'inc'
            analytics_record = create_analytics_record(date, investigation_data[:advised_by_id], investigation_data[:facility_id], params['after_save_patient_gender'], age_year, current_organisation_id, specialty_id)
          end

          next unless analytics_record

          if investigation_type == 'ophthal_investigations'
            investigation_list = analytics_record.ophthal_investigations_list
          elsif investigation_type == 'laboratory_investigations'
            investigation_list = analytics_record.laboratory_investigations_list
          elsif investigation_type == 'radiology_investigations'
            investigation_list = analytics_record.radiology_investigations_list
          end

          record = investigation_list.find { |investigation| investigation['code'] == investigation_data[:code] }

          if record
            data_list_array = investigation_list.reject { |investigation| investigation['code'] == investigation_data[:code] }
            record['count'] = record['count'].to_i + counter_value
            data_list_array << record
            investigation_list = data_list_array.reject { |ele| ele['count'] <= 0 }

          elsif operator == 'inc'
            investigation_list << Hash["count": counter_value, "code": investigation_data[:code], "investigation_name": investigation_data[:investigation_name]]
          end

          if investigation_type == 'ophthal_investigations'
            analytics_record.ophthal_investigations_list = investigation_list
          elsif investigation_type == 'laboratory_investigations'
            analytics_record.laboratory_investigations_list = investigation_list
          elsif investigation_type == 'radiology_investigations'
            analytics_record.radiology_investigations_list = investigation_list
          end
          analytics_record.save
        end
      end

      def inc_counsellor_desc_counts(investigation_data, operator, params, current_organisation_id, investigation_type, specialty_id)
        date = investigation_data[:date].to_date
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

          analytics_record = Analytics::ClinicalDataOverview.find_by(
            user_id: investigation_data[:counselled_by_id], facility_id: investigation_data[:facility_id], date: date,
            specialty_id: specialty_id, patient_gender: params["#{flag}_save_patient_gender"], data_type: @type,
            patient_age_year: age_year, data_type_range: @hashed_data[@type], in_year: @start_date.year
          )

          if analytics_record.nil? && operator == 'inc'
            analytics_record = create_analytics_record(date, investigation_data[:counselled_by_id], investigation_data[:facility_id], params['after_save_patient_gender'], age_year, current_organisation_id, specialty_id)
          end

          next unless analytics_record

          if investigation_type == 'ophthal_investigations'
            investigation_list = analytics_record.ophthal_investigations_list
          elsif investigation_type == 'laboratory_investigations'
            investigation_list = analytics_record.laboratory_investigations_list
          elsif investigation_type == 'radiology_investigations'
            investigation_list = analytics_record.radiology_investigations_list
          end

          record = investigation_list.find { |investigation| investigation['code'] == investigation_data[:code] }

          if record
            data_list_array = investigation_list.reject { |investigation| investigation['code'] == investigation_data[:code] }
            record['count'] = record['count'].to_i + counter_value
            data_list_array << record
            investigation_list = data_list_array.reject { |ele| ele['count'] <= 0 }

          elsif operator == 'inc'
            investigation_list << Hash["count": counter_value, "code": investigation_data[:code], "investigation_name": investigation_data[:investigation_name]]
          end

          if investigation_type == 'ophthal_investigations'
            analytics_record.ophthal_investigations_list = investigation_list
          elsif investigation_type == 'laboratory_investigations'
            analytics_record.laboratory_investigations_list = investigation_list
          elsif investigation_type == 'radiology_investigations'
            analytics_record.radiology_investigations_list = investigation_list
          end
          analytics_record.save
        end
      end

      def create(investigation_id, after_save_params, params, current_organisation_id, investigation_type, specialty_id)
        investigation_data = after_save_params.select { |investigation| investigation == investigation_id }.values[0]

        if @role_ids.include?(499992366) && investigation_data[:is_counselled]
          inc_counsellor_desc_counts(investigation_data, 'inc', params, current_organisation_id, investigation_type, specialty_id)
        else
          inc_desc_counts(investigation_data, 'inc', params, current_organisation_id, investigation_type, specialty_id)
        end
      end

      def update(investigation_id, before_params, after_params, params, current_organisation_id, investigation_type, specialty_id)
        before_save_investigation = before_params.select { |investigation| investigation == investigation_id }.values[0]
        after_save_investigation = after_params.select { |investigation| investigation == investigation_id }.values[0]

        if before_save_investigation[:advised_by_id] != after_save_investigation[:advised_by_id] || before_save_investigation['data'] != after_save_investigation['data'] || params['before_save_patient_age'] != params['after_save_patient_age'] || params['before_save_patient_gender'] != params['after_save_patient_gender']
          inc_desc_counts(before_save_investigation, 'desc', params, current_organisation_id, investigation_type, specialty_id)
          inc_desc_counts(after_save_investigation, 'inc', params, current_organisation_id, investigation_type, specialty_id)
        end
      end

      def delete(investigation_id, before_save_params, params, current_organisation_id, investigation_type, specialty_id)
        investigation_data = before_save_params.select { |investigation| investigation == investigation_id }.values[0]
        inc_desc_counts(investigation_data, 'desc', params, current_organisation_id, investigation_type, specialty_id)

        if @role_ids.include?(499992366) && investigation_data[:is_counselled]
          inc_counsellor_desc_counts(investigation_data, 'desc', params, current_organisation_id, investigation_type, specialty_id)
        end
      end

      def find_existing_delete_new_ids(before_save_inv_codes, after_save_inv_codes)
        existing_ids = []
        new_ids = []
        deleted_ids = []

        after_save_inv_codes.each do |code|
          if before_save_inv_codes.include?(code)
            existing_ids << code
          else
            new_ids << code
          end
        end

        before_save_inv_codes.each do |code|
          deleted_ids << code unless after_save_inv_codes.include?(code)
        end

        [existing_ids, new_ids, deleted_ids]
      end

      def create_analytics_record(date, user_id, facility_id, gender, age, current_organisation_id, specialty_id)
        if date.present? && user_id.present? && facility_id.present? && current_organisation_id.present?
          user = User.find_by(id: user_id)
          record = Analytics::ClinicalDataOverview.new.tap do |investigation|
            investigation.date = date
            investigation.user_id = user_id
            investigation.patient_gender = gender
            investigation.patient_age_year = age
            investigation.user_name = user.fullname
            investigation.user_role_ids = user.role_ids
            investigation.facility_id = facility_id
            investigation.specialty_id = specialty_id
            investigation.organisation_id = current_organisation_id
            investigation.start_date = @start_date
            investigation.end_date = @end_date
            investigation.data_type = @type
            investigation.data_type_range = @hashed_data[@type]
            investigation.in_year = @start_date.year

            investigation.save
          end

          record
        end
      end
    end
  end
end
