module Analytics::Diagnosis
  class CreateUpdateService
    DATA_CREATION_ARRAY = ["day", "week", "month", "year"].freeze

    def self.call(params, current_user_id, current_facility_id, current_organisation_id)
      case_sheet = CaseSheet.find_by(id: params["case_sheet_id"])
      specialty_id = case_sheet.specialty_id

      before_save_params = Hash[params["before_save_diagnosis"].map { |diagnosis| [diagnosis["_id"], { "advised_by_id": diagnosis["advised_by_id"], "date": diagnosis["advised_datetime"].present? ? Date.parse(diagnosis["advised_datetime"]).in_time_zone(params["time_zone"]) : diagnosis["updated_at"], "facility_id": diagnosis["advised_at_facility_id"] }] }]

      after_save_params = Hash[params["after_save_diagnosis"].map { |diagnosis| [diagnosis["_id"], { "advised_by_id": diagnosis["advised_by_id"], "date": diagnosis["advised_datetime"].present? ? Date.parse(diagnosis["advised_datetime"]).in_time_zone(params["time_zone"]) : diagnosis["updated_at"], "facility_id": diagnosis["advised_at_facility_id"] }] }]

      before_save_diagnosis_ids = before_save_params.keys
      after_save_diagnosis_ids = after_save_params.keys

      existing_ids, new_ids, deleted_ids = find_update_delete_new_ids(before_save_diagnosis_ids, after_save_diagnosis_ids)

      if existing_ids.count > 0
        existing_ids.each do |existing_id|
          update(existing_id, before_save_params, after_save_params, current_organisation_id, specialty_id)
        end
      end

      if new_ids.count > 0
        new_ids.each do |new_id|
          create(new_id, after_save_params, current_organisation_id, specialty_id)
        end
      end

      if deleted_ids.count > 0
        deleted_ids.each do |deleted_id|
          delete(deleted_id, before_save_params, current_organisation_id, specialty_id)
        end
      end
    end

    private

    def self.inc_desc_counts(diagnosis_data, operator, current_organisation_id, specialty_id)
      date = diagnosis_data[:date].to_date
      @hashed_data = Hash.new
      @hashed_data["day"], @hashed_data["week"], @hashed_data["month"], @hashed_data["year"] = date.yday, date.cweek, date.month, date.year

      DATA_CREATION_ARRAY.each_with_index do |type, indx|
        @type = type
        @start_date, @end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)

        counter_value = operator == 'inc' ? 1 : -1
        advised_record = Analytics::ClinicalOverview.find_by(
          user_id: diagnosis_data[:advised_by_id], facility_id: diagnosis_data[:facility_id],
          specialty_id: specialty_id, date: date, data_type: @type, data_type_range: @hashed_data[@type],
          in_year: @start_date.year
        )
        if advised_record.nil? && operator == 'inc'
          advised_record = create_analytics_record(date, diagnosis_data[:advised_by_id], diagnosis_data[:facility_id], current_organisation_id, specialty_id)
        end
        advised_record.inc(total_diagnoses_advised: counter_value) if advised_record.present?
      end
    end

    def self.create(diagnosis_id, after_save_params, current_organisation_id, specialty_id)
      diagnosis_data = after_save_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]
      inc_desc_counts(diagnosis_data, 'inc', current_organisation_id, specialty_id)
    end

    def self.update(diagnosis_id, before_params, after_params, current_organisation_id, specialty_id)
      before_save_diagnosis = before_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]
      after_save_diagnosis = after_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]

      if before_save_diagnosis[:advised_by_id] != after_save_diagnosis[:advised_by_id]
        inc_desc_counts(before_save_diagnosis, 'desc', current_organisation_id, specialty_id)
      end

      if before_save_diagnosis[:advised_by_id] != after_save_diagnosis[:advised_by_id]
        inc_desc_counts(after_save_diagnosis, 'inc', current_organisation_id, specialty_id)
      end
    end

    def self.delete(diagnosis_id, before_save_params, current_organisation_id, specialty_id)
      diagnosis_data = before_save_params.select { |diagnosis| diagnosis == diagnosis_id }.values[0]
      inc_desc_counts(diagnosis_data, 'desc', current_organisation_id, specialty_id)
    end

    def self.find_update_delete_new_ids(before_save_diagnosis_ids, after_save_diagnosis_ids)
      existing_ids = []
      new_ids = []
      deleted_ids = []

      after_save_diagnosis_ids.each do |diagnosis_id|
        if before_save_diagnosis_ids.include?(diagnosis_id)
          existing_ids << diagnosis_id
        else
          new_ids << diagnosis_id
        end
      end

      before_save_diagnosis_ids.each do |diagnosis_id|
        if !after_save_diagnosis_ids.include?(diagnosis_id)
          deleted_ids << diagnosis_id
        end
      end

      return existing_ids, new_ids, deleted_ids
    end

    def self.create_analytics_record(date, user_id, facility_id, current_organisation_id, specialty_id)
      if date.present? && user_id.present? && facility_id.present? && current_organisation_id.present?

        user = User.find_by(id: user_id)
        record = Analytics::ClinicalOverview.new.tap do |diagnosis|
          diagnosis.date = date
          diagnosis.user_id = user_id
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

        return record
      else
        return nil
      end
    end
  end
end
