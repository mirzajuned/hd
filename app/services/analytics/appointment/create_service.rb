module Analytics::Appointment
  class CreateService
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze

    def self.call(params, current_user_id, facility_id)
      appointment = ::Appointment.find_by(id: params)
      organisation_id = appointment.try(:organisation_id)
      facility_id = facility_id
      specialty_id = appointment.specialty_id
      user_id = current_user_id
      date = appointment.appointmentdate

      return if organisation_id.nil? || facility_id.nil? || user_id.nil? || date.nil?

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year
      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        general_overview = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user_id,
          data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        )

        if general_overview.blank?
          general_overview = Analytics::GeneralOverview.new.tap do |g_overview|
            g_overview.organisation_id = organisation_id
            g_overview.facility_id = facility_id
            g_overview.specialty_id = specialty_id
            g_overview.user_id = user_id
            g_overview.data_type = type
            g_overview.data_type_range = hashed_data[type]
            g_overview.start_date = start_date
            g_overview.end_date = end_date
            g_overview.in_year = start_date.year
            g_overview.save
          end
        end

        general_overview.inc(appointment_created_count: 1)
      end

      # create_walkin_appointment_type_record(appointment)
      # removed as from ideamed data was creating wrong so commented
      # create_appointment_type_record(appointment)
      # create_appointment_category_type_record(appointment)
    end

    def self.create_walkin_appointment_type_record(appointment)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.facility_id
      specialty_id = appointment.specialty_id
      user_id = appointment.user_id
      date = appointment.appointmentdate

      return if organisation_id.nil? || facility_id.nil? || user_id.nil? || date.nil?

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        walkin_appt_type = Analytics::WalkinAppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          data_type: type, data_type_range: hashed_data[type], appointment_type_label: appointment.appointmenttype
        )

        walkin_appt_type ||= Analytics::WalkinAppointmentTypeOverview.new.tap do |walkin_type|
          walkin_type.organisation_id = organisation_id
          walkin_type.facility_id = facility_id
          walkin_type.specialty_id = specialty_id
          walkin_type.user_id = user_id
          walkin_type.data_type = type
          walkin_type.data_type_range = hashed_data[type]
          walkin_type.appointment_type_label = appointment.appointmenttype
          walkin_type.start_date = start_date
          walkin_type.end_date = end_date
          walkin_type.in_year = start_date.year
          walkin_type.save
        end
        walkin_appt_type.inc(appointment_type_count: 1)
      end
    end

    def self.create_appointment_type_record(appointment)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.facility_id
      specialty_id = appointment.specialty_id
      user_id = appointment.user_id
      date = appointment.appointmentdate

      return if organisation_id.nil? || facility_id.nil? || user_id.nil? || date.nil?

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      appointment_type = AppointmentType.find_by(id: appointment.appointment_type_id)

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)

        analytics_appointment_type = Analytics::AppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, data_type: type,
          data_type_range: hashed_data[type], appointment_type_id: appointment.appointment_type_id
        )

        analytics_appointment_type ||= Analytics::AppointmentTypeOverview.new.tap do |appoint_type|
          appoint_type.organisation_id = organisation_id
          appoint_type.facility_id = facility_id
          appoint_type.specialty_id = specialty_id
          appoint_type.user_id = user_id
          appoint_type.data_type = type
          appoint_type.data_type_range = hashed_data[type]
          appoint_type.appointment_type_id = appointment.appointment_type_id
          appoint_type.appointment_type_label = appointment_type.try(:label)
          appoint_type.start_date = start_date
          appoint_type.end_date = end_date
          appoint_type.in_year = start_date.year
          appoint_type.save
        end
        analytics_appointment_type.inc(appointment_type_count: 1)
      end
    end

    def self.create_appointment_category_type_record(appointment)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.facility_id
      specialty_id = appointment.specialty_id
      user_id = appointment.user_id
      date = appointment.appointmentdate
      category_id = appointment.appointment_category_id

      return if organisation_id.nil? || facility_id.nil? || user_id.nil? || date.nil? || category_id.nil?

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      category_type = OrganisationAppointmentCategoryType.find_by(id: category_id)

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        appointment_category_type = Analytics::AppointmentCategoryTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user_id,
          data_type: type, data_type_range: hashed_data[type], appointment_category_type_id: category_id
        )

        appointment_category_type ||= Analytics::AppointmentCategoryTypeOverview.new.tap do |appoint_cat_type|
          appoint_cat_type.organisation_id = organisation_id
          appoint_cat_type.facility_id = facility_id
          appoint_cat_type.specialty_id = specialty_id
          appoint_cat_type.user_id = user_id
          appoint_cat_type.data_type = type
          appoint_cat_type.data_type_range = hashed_data[type]
          appoint_cat_type.appointment_category_type_id = category_id
          appoint_cat_type.appointment_category_type_label = category_type&.label
          appoint_cat_type.start_date = start_date
          appoint_cat_type.end_date = end_date
          appoint_cat_type.in_year = start_date.year
          appoint_cat_type.save
        end
        appointment_category_type.inc(appointment_category_type_count: 1)
      end
    end
  end
end
