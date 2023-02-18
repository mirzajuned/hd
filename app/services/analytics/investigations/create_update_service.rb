module Analytics::Investigations
  class CreateUpdateService
    DATA_CREATION_ARRAY = ["day", "week", "month", "year"].freeze

    def self.call(params, current_user_id, current_facility_id, current_organisation_id)
      case_sheet = CaseSheet.find_by(id: params["case_sheet_id"])
      specialty_id = case_sheet.specialty_id

      @investigations = ['ophthal_investigations', 'laboratory_investigations', 'radiology_investigations']

      @investigations.each do |investigation|
        if params["before_save_#{investigation}"].count > 0 || params["after_save_#{investigation}"].count > 0
          get_final_investigations_hash(params, investigation)

          before_investigation_ids = eval("@before_#{investigation}").keys
          after_investigation_ids = eval("@after_#{investigation}").keys

          existing_ids, new_ids, deleted_ids = find_update_delete_new_ids(before_investigation_ids, after_investigation_ids)

          if existing_ids.count > 0
            existing_ids.each do |existing_id|
              update(existing_id, investigation, eval("@before_#{investigation}"), eval("@after_#{investigation}"), current_organisation_id, specialty_id)
            end
          end

          if new_ids.count > 0
            new_ids.each do |new_id|
              create(new_id, investigation, eval("@after_#{investigation}"), current_organisation_id, specialty_id)
            end
          end

          if deleted_ids.count > 0
            deleted_ids.each do |deleted_id|
              delete(deleted_id, investigation, eval("@before_#{investigation}"), current_organisation_id, specialty_id)
            end
          end
        end
      end
    end

    private

    def self.set_variable(variable, value)
      var_name = "@#{variable}" # the '@' is required
      self.instance_variable_set(var_name, value)
    end

    def self.get_final_investigations_hash(params, investigation)
      before_hash = params["before_save_#{investigation}"]
      after_hash = params["after_save_#{investigation}"]

      before = Hash[before_hash.map { |inv| [inv["_id"], { "advised_by_id": inv["advised_by_id"], "performed_by_id": inv["performed_by_id"], "counselled_by_id": inv["counselled_by_id"], "date": inv["advised_datetime"].present? ? Date.parse(inv["advised_datetime"]).in_time_zone(params["time_zone"]) : inv["updated_at"], "facility_id": inv["advised_at_facility_id"] }] }]

      after = Hash[after_hash.map { |inv| [inv["_id"], { "advised_by_id": inv["advised_by_id"], "performed_by_id": inv["performed_by_id"], "counselled_by_id": inv["counselled_by_id"], "date": inv["advised_datetime"].present? ? Date.parse(inv["advised_datetime"]).in_time_zone(params["time_zone"]) : inv["updated_at"], "facility_id": inv["advised_at_facility_id"] }] }]

      self.set_variable("before_#{investigation}", before)
      self.set_variable("after_#{investigation}", after)
    end

    def self.inc_desc_counts(investigation_data, investigation_type, operator, current_organisation_id, specialty_id)
      date = investigation_data[:date].to_date
      @hashed_data = Hash.new

      @hashed_data["day"], @hashed_data["week"], @hashed_data["month"], @hashed_data["year"] = date.yday, date.cweek, date.month, date.year

      DATA_CREATION_ARRAY.each_with_index do |type, indx|
        @type = type
        @start_date, @end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        counter_value = operator == 'inc' ? 1 : -1

        advised_record = Analytics::ClinicalOverview.find_by(
          user_id: investigation_data[:advised_by_id], facility_id: investigation_data[:facility_id],
          specialty_id: specialty_id, date: date, data_type: @type, data_type_range: @hashed_data[@type],
          in_year: @start_date.year
        )

        if advised_record.nil? && operator == 'inc'
          advised_record = create_analytics_record(date, investigation_data[:advised_by_id], investigation_data[:facility_id], current_organisation_id, specialty_id)
        end

        if investigation_data[:advised_by_id] == investigation_data[:counselled_by_id]
          if advised_record
            options = { ("total_#{investigation_type}_advised").to_sym => counter_value, ("total_#{investigation_type}_counselled").to_sym => counter_value }
            options = options.merge(("total_#{investigation_type}_converted").to_sym => counter_value) if investigation_data[:performed_by_id].present?
            advised_record.inc(options)
          end

        else
          if investigation_data[:counselled_by_id].present?
            counselled_record = Analytics::ClinicalOverview.find_by(
              user_id: investigation_data[:counselled_by_id], facility_id: investigation_data[:facility_id],
              specialty_id: specialty_id, date: date, data_type: @type, data_type_range: @hashed_data[@type],
              in_year: @start_date.year
            )

            if counselled_record.nil? && operator == 'inc'
              counselled_record = create_analytics_record(date, investigation_data[:counselled_by_id], investigation_data[:facility_id], current_organisation_id, specialty_id)
            end
          end

          options = { ("total_#{investigation_type}_advised").to_sym => counter_value }
          options = options.merge(("total_#{investigation_type}_converted").to_sym => counter_value) if investigation_data[:performed_by_id].present?
          advised_record.inc(options) if advised_record.present?

          counselled_options = { ("total_#{investigation_type}_counselled").to_sym => counter_value }
          counselled_options = counselled_options.merge(("total_#{investigation_type}_converted").to_sym => counter_value) if investigation_data[:performed_by_id].present?
          counselled_record.inc(counselled_options) if counselled_record.present?
        end
      end
    end

    def self.create(investigation_id, investigation_type, after_save_params, current_organisation_id, specialty_id)
      investigation_data = after_save_params.select { |investigation| investigation == investigation_id }.values[0]
      inc_desc_counts(investigation_data, investigation_type, 'inc', current_organisation_id, specialty_id)
    end

    def self.update(investigation_id, investigation_type, before_params, after_params, current_organisation_id, specialty_id)
      before_save_investigation = before_params.select { |investigation| investigation == investigation_id }.values[0]
      after_save_investigation = after_params.select { |investigation| investigation == investigation_id }.values[0]

      if before_save_investigation[:advised_by_id] != after_save_investigation[:advised_by_id] || before_save_investigation[:performed_by_id] != after_save_investigation[:performed_by_id] || before_save_investigation[:counselled_by_id] != after_save_investigation[:counselled_by_id]
        inc_desc_counts(before_save_investigation, investigation_type, 'desc', current_organisation_id, specialty_id)
      end

      if before_save_investigation[:advised_by_id] != after_save_investigation[:advised_by_id] || before_save_investigation[:performed_by_id] != after_save_investigation[:performed_by_id] || before_save_investigation[:counselled_by_id] != after_save_investigation[:counselled_by_id]
        inc_desc_counts(after_save_investigation, investigation_type, 'inc', current_organisation_id, specialty_id)
      end
    end

    def self.delete(investigation_id, investigation_type, before_save_params, current_organisation_id, specialty_id)
      investigation_data = before_save_params.select { |investigation| investigation == investigation_id }.values[0]
      inc_desc_counts(investigation_data, investigation_type, 'desc', current_organisation_id, specialty_id)
    end

    def self.find_update_delete_new_ids(before_save_investigation_ids, after_save_investigation_ids)
      existing_ids = []
      new_ids = []
      deleted_ids = []

      after_save_investigation_ids.each do |investigation_id|
        if before_save_investigation_ids.include?(investigation_id)
          existing_ids << investigation_id
        else
          new_ids << investigation_id
        end
      end

      before_save_investigation_ids.each do |investigation_id|
        if !after_save_investigation_ids.include?(investigation_id)
          deleted_ids << investigation_id
        end
      end

      return existing_ids, new_ids, deleted_ids
    end

    def self.create_analytics_record(date, user_id, facility_id, current_organisation_id, specialty_id)
      if date.present? && user_id.present? && facility_id.present? && current_organisation_id.present?

        user = User.find_by(id: user_id)
        record = Analytics::ClinicalOverview.new.tap do |investigation|
          investigation.date = date
          investigation.user_id = user_id
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

        return record
      else
        return nil
      end
    end
  end
end
