module Analytics::Procedure
  class CreateUpdateService
    DATA_CREATION_ARRAY = ["day", "week", "month", "year"].freeze

    def self.call(params, current_user_id, current_facility_id, current_organisation_id)
      case_sheet = CaseSheet.find_by(id: params["case_sheet_id"])
      specialty_id = case_sheet.specialty_id

      before_save_params = Hash[params["before_save_procedure"].map { |procedure| [procedure["_id"], { "advised_by_id": procedure["advised_by_id"], "performed_by_id": procedure["performed_by_id"], "counselled_by_id": procedure["counselled_by_id"], "date": procedure["advised_datetime"].present? ? Date.parse(procedure["advised_datetime"]).in_time_zone(params["time_zone"]) : procedure["updated_at"], "facility_id": procedure["advised_at_facility_id"] }] }]

      after_save_params = Hash[params["after_save_procedure"].map { |procedure| [procedure["_id"], { "advised_by_id": procedure["advised_by_id"], "performed_by_id": procedure["performed_by_id"], "counselled_by_id": procedure["counselled_by_id"], "date": procedure["advised_datetime"].present? ? Date.parse(procedure["advised_datetime"]).in_time_zone(params["time_zone"]) : procedure["updated_at"], "facility_id": procedure["advised_at_facility_id"] }] }]

      before_save_procedure_ids = before_save_params.keys
      after_save_procedure_ids = after_save_params.keys

      existing_ids, new_ids, deleted_ids = find_update_delete_new_ids(before_save_procedure_ids, after_save_procedure_ids)

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

    def self.inc_desc_counts(procedure_data, operator, current_organisation_id, specialty_id)
      date = procedure_data[:date].to_date
      @hashed_data = Hash.new
      @hashed_data["day"], @hashed_data["week"], @hashed_data["month"], @hashed_data["year"] = date.yday, date.cweek, date.month, date.year

      DATA_CREATION_ARRAY.each_with_index do |type, indx|
        @type = type
        @start_date, @end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        counter_value = operator == 'inc' ? 1 : -1
        advised_record = Analytics::ClinicalOverview.find_by(
          user_id: procedure_data[:advised_by_id], facility_id: procedure_data[:facility_id],
          specialty_id: specialty_id, date: date, data_type: @type, data_type_range: @hashed_data[@type],
          in_year: @start_date.year
        )

        if advised_record.nil? && operator == 'inc'
          advised_record = create_analytics_record(procedure_data[:date], procedure_data[:advised_by_id], procedure_data[:facility_id], current_organisation_id, specialty_id)
        end

        if procedure_data[:advised_by_id] == procedure_data[:counselled_by_id]
          if advised_record
            options = { total_procedures_advised: counter_value, total_procedures_counselled: counter_value }
            options = options.merge(total_procedures_converted: counter_value) if procedure_data[:performed_by_id].present?
            advised_record.inc(options)
          end

        else
          if procedure_data[:counselled_by_id].present?
            counselled_record = Analytics::ClinicalOverview.find_by(
              user_id: procedure_data[:counselled_by_id], facility_id: procedure_data[:facility_id],
              specialty_id: specialty_id, date: date, data_type: @type, data_type_range: @hashed_data[@type],
              in_year: @start_date.year
            )
            if counselled_record.nil? && operator == 'inc'
              counselled_record = create_analytics_record(procedure_data[:date], procedure_data[:counselled_by_id], procedure_data[:facility_id], current_organisation_id, specialty_id)
            end
          end

          options = { total_procedures_advised: counter_value }
          options = options.merge(total_procedures_converted: counter_value) if procedure_data[:performed_by_id].present?
          advised_record.inc(options) if advised_record.present?

          counselled_options = { total_procedures_counselled: counter_value }
          counselled_options = counselled_options.merge(total_procedures_converted: counter_value) if procedure_data[:performed_by_id].present?
          counselled_record.inc(counselled_options) if counselled_record.present?
        end
      end
    end

    def self.create(procedure_id, after_save_params, current_organisation_id, specialty_id)
      procedure_data = after_save_params.select { |procedure| procedure == procedure_id }.values[0]
      inc_desc_counts(procedure_data, 'inc', current_organisation_id, specialty_id)
    end

    def self.update(procedure_id, before_params, after_params, current_organisation_id, specialty_id)
      before_save_procedure = before_params.select { |procedure| procedure == procedure_id }.values[0]
      after_save_procedure = after_params.select { |procedure| procedure == procedure_id }.values[0]

      if before_save_procedure[:advised_by_id] != after_save_procedure[:advised_by_id] || before_save_procedure[:performed_by_id] != after_save_procedure[:performed_by_id] || before_save_procedure[:counselled_by_id] != after_save_procedure[:counselled_by_id]
        inc_desc_counts(before_save_procedure, 'desc', current_organisation_id, specialty_id)
      end

      if before_save_procedure[:advised_by_id] != after_save_procedure[:advised_by_id] || before_save_procedure[:performed_by_id] != after_save_procedure[:performed_by_id] || before_save_procedure[:counselled_by_id] != after_save_procedure[:counselled_by_id]
        inc_desc_counts(after_save_procedure, 'inc', current_organisation_id, specialty_id)
      end
    end

    def self.delete(procedure_id, before_save_params, current_organisation_id, specialty_id)
      procedure_data = before_save_params.select { |procedure| procedure == procedure_id }.values[0]
      inc_desc_counts(procedure_data, 'desc', current_organisation_id, specialty_id)
    end

    def self.find_update_delete_new_ids(before_save_procedure_ids, after_save_procedure_ids)
      existing_ids = []
      new_ids = []
      deleted_ids = []

      after_save_procedure_ids.each do |procedure_id|
        if before_save_procedure_ids.include?(procedure_id)
          existing_ids << procedure_id
        else
          new_ids << procedure_id
        end
      end

      before_save_procedure_ids.each do |procedure_id|
        if !after_save_procedure_ids.include?(procedure_id)
          deleted_ids << procedure_id
        end
      end

      return existing_ids, new_ids, deleted_ids
    end

    def self.create_analytics_record(date, user_id, facility_id, current_organisation_id, specialty_id)
      if date.present? && user_id.present? && facility_id.present? && current_organisation_id.present?
        user = User.find_by(id: user_id)
        record = Analytics::ClinicalOverview.new.tap do |procedure|
          procedure.date = date
          procedure.user_id = user_id
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

        return record
      else
        return nil
      end
    end
  end
end
