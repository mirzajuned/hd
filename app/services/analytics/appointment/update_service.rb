module Analytics::Appointment
  class UpdateService
    DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
    def self.call(params, _current_user_id, current_facility_id)
      appointment = ::Appointment.find_by(id: params)
      date = appointment.appointmentdate
      specialty_id = appointment.specialty_id
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        general_analytics = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        )

        if general_analytics.blank?
          general_analytics = Analytics::GeneralOverview.create!(
            facility_id: current_facility_id, date: date,
            specialty_id: appointment.specialty_id, organisation_id: appointment.organisation_id
          )
        end
        # if appointment.arrived == false
        #   general_analytics.inc(appointment_arrived_count: -1)
        # end
        #
        if general_analytics.present? && appointment.appointmentstatus == 89925002 && general_analytics.appointment_created_count > 0
          general_analytics.inc(appointment_created_count: -1)
        end
      end
    end

    def self.patient_arrived(params, current_user_id, current_facility_id)
      appointment = ::Appointment.find_by(id: params)
      organisation_id = appointment.try(:organisation_id)
      facility_id = current_facility_id
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
          general_overview = Analytics::GeneralOverview.new(
            organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
            user_id: user_id, data_type: type, data_type_range: hashed_data[type], appointment_created_count: 1,
            start_date: start_date, end_date: end_date, in_year: start_date.year
          )
          general_overview.save!
        end

        if appointment.try(:visit_no).to_i == 1
          general_overview.opd_new_patient_count += 1
          general_overview.first_opd_visit += 1
        else
          general_overview.opd_old_patient_count += 1
          if appointment.try(:visit_no).to_i == 2
            general_overview.second_opd_visit += 1
          elsif appointment.try(:visit_no).to_i == 3
            general_overview.third_opd_visit += 1
          elsif appointment.try(:visit_no).to_i == 4
            general_overview.fourth_opd_visit += 1
          elsif appointment.try(:visit_no).to_i == 5
            general_overview.fifth_opd_visit += 1
          elsif appointment.try(:visit_no).to_i > 5
            general_overview.above_fifth_opd_visit += 1
          end

        end
        general_overview.appointment_arrived_count += 1
        general_overview.save!
      end
    end

    def self.patient_not_arrived(params, current_user_id, current_facility_id)
      appointment = ::Appointment.find_by(id: params)
      organisation_id = appointment.try(:organisation_id)
      facility_id = current_facility_id
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
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          user_id: user_id, data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        )
        record_found = true

        if general_overview.blank?
          general_overview = Analytics::GeneralOverview.new.tap do |g_overview|
            g_overview.appointment_created_count = 1
            g_overview.organisation_id = organisation_id
            g_overview.facility_id = facility_id
            g_overview.specialty_id = specialty_id
            g_overview.user_id = user_id
            g_overview.data_type = type
            g_overview.data_type_range = hashed_data[type]
            g_overview.start_date = start_date
            g_overview.end_date = end_date
            g_overview.in_year = start_date.year
            g_overview.save!
          end
          record_found = false
        end

        if appointment.try(:visit_no).to_i == 1
          if record_found
            general_overview.opd_new_patient_count -= 1 if general_overview.opd_new_patient_count > 0
            general_overview.first_opd_visit -= 1
          end
        else
          if record_found
            general_overview.opd_old_patient_count -= 1 if general_overview.opd_old_patient_count > 0
            if appointment.try(:visit_no).to_i == 2
              general_overview.second_opd_visit += 1
            elsif appointment.try(:visit_no).to_i == 3
              general_overview.third_opd_visit += 1
            elsif appointment.try(:visit_no).to_i == 4
              general_overview.fourth_opd_visit += 1
            elsif appointment.try(:visit_no).to_i == 5
              general_overview.fifth_opd_visit += 1
            elsif appointment.try(:visit_no).to_i > 5
              general_overview.above_fifth_opd_visit += 1
            end
          end
        end

        if appointment.arrived == true
          general_overview.appointment_arrived_count -= 1 if general_overview.appointment_arrived_count > 0 && record_found
          general_overview.save!
        end
      end
    end

    # calls only when appointment_edit or reshedule appointments
    def self.update_appointment_created_count(appointment_id, past_facility_id, past_appointment_date, past_specialty_id)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)

      date = appointment.appointmentdate
      old_date = past_appointment_date

      hashed_data_old = {}
      hashed_data_old['day'] = old_date.yday
      hashed_data_old['week'] = old_date.cweek
      hashed_data_old['month'] = old_date.month
      hashed_data_old['year'] = old_date.year

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        # decrementing existing appointment_created_count
        past_appointment_record = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: past_facility_id, specialty_id: past_specialty_id,
          user_id: user_id, data_type: type, data_type_range: hashed_data_old[type], in_year: start_date.year
        )

        if past_appointment_record && past_appointment_record.appointment_created_count > 0
          past_appointment_record.inc(appointment_created_count: -1)
        end
        # incementing updated walkin_type record
        new_appointment_record = Analytics::GeneralOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          user_id: user_id, data_type: type, data_type_range: hashed_data[type], in_year: start_date.year
        )

        new_appointment_record ||= Analytics::GeneralOverview.new.tap do |g_overview|
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
        new_appointment_record.inc(appointment_created_count: 1) if new_appointment_record.present?
      end
    end

    # calls only when appointment got cancelled from   opd_appointments#cancelappointment
    def self.decrement_walkin_type_count(appointment_id)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)
      date = appointment.appointmentdate

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, _end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        walkin_type = Analytics::WalkinAppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          appointment_type_label: appointment.appointmenttype, user_id: user_id, data_type: type,
          data_type_range: hashed_data[type], in_year: start_date.year
        )

        walkin_type.inc(appointment_type_count: -1) if walkin_type.present? && walkin_type.appointment_type_count > 0
      end
    end

    # calls only when appointment_edit or reshedule appointments
    def self.update_walkin_appointment_type_count(appointment_id, past_facility_id, past_specialty_id, past_appointment_date, past_walkin_label)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)

      date = appointment.appointmentdate
      old_date = past_appointment_date

      hashed_data_old = {}
      hashed_data_old['day'] = old_date.yday
      hashed_data_old['week'] = old_date.cweek
      hashed_data_old['month'] = old_date.month
      hashed_data_old['year'] = old_date.year

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        past_walkin_apt_type = Analytics::WalkinAppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: BSON::ObjectId(past_facility_id),
          specialty_id: past_specialty_id, appointment_type_label: past_walkin_label, user_id: user_id,
          data_type: type, data_type_range: hashed_data_old[type], in_year: start_date.year
        )

        # decrementing existing walkin_type record
        if past_walkin_apt_type && past_walkin_apt_type.appointment_type_count > 0
          past_walkin_apt_type.inc(appointment_type_count: -1)
        end

        next unless appointment.try(:arrived)

        # incementing updated walkin_type record
        new_walkin_type = Analytics::WalkinAppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: BSON::ObjectId(past_facility_id),
          specialty_id: past_specialty_id, appointment_type_label: appointment.appointmenttype, user_id: user_id,
          data_type: type, data_type_range: hashed_data_old[type], in_year: start_date.year
        )

        new_walkin_type ||= Analytics::WalkinAppointmentTypeOverview.new.tap do |walkin_type|
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
        new_walkin_type.inc(appointment_type_count: 1)
      end
    end

    # calls only when appointment got cancelled from    opd_appointments#cancelappointment
    def self.decrement_appointment_type_count(appointment_id)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)

      date = appointment.appointmentdate
      hashed_data = {}

      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year
      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, _end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        appt_type_record = Analytics::AppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          user_id: user_id, appointment_type_id: appointment.appointment_type_id, data_type: type,
          data_type_range: hashed_data[type], in_year: start_date.year
        )
        if appt_type_record && appt_type_record.appointment_type_count > 0
          appt_type_record.inc(appointment_type_count: -1)
        end
      end
    end

    # calls only when appointment_edit or reshedule appointments
    def self.update_appointment_type_count(appointment_id, past_appointment_type_id, past_facility_id, past_specialty_id, past_appointment_date)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)

      date = appointment.appointmentdate
      old_date = past_appointment_date

      new_appointment_type = AppointmentType.find_by(id: appointment.appointment_type_id)
      old_appt_type_id     = past_appointment_type_id
      old_appt_facility_id = past_facility_id
      hashed_data_old = {}
      hashed_data_old['day'] = old_date.yday
      hashed_data_old['week'] = old_date.cweek
      hashed_data_old['month'] = old_date.month
      hashed_data_old['year'] = old_date.year

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        if old_appt_type_id.present?
          past_appt_type_record = Analytics::AppointmentTypeOverview.find_by(
            organisation_id: organisation_id, facility_id: old_appt_facility_id, specialty_id: past_specialty_id,
            appointment_type_id: past_appointment_type_id, user_id: user_id, data_type: type,
            data_type_range: hashed_data_old[type], in_year: start_date.year
          )
        end
        # decrementing existing appointment_type record
        if past_appt_type_record.present? && past_appt_type_record.appointment_type_count > 0
          past_appt_type_record.inc(appointment_type_count: -1)
        end

        # incementing updated appointment_type record
        next unless appointment.try(:arrived) && appointment.appointment_type_id.present?

        new_appt_type_record = Analytics::AppointmentTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          appointment_type_id: appointment.appointment_type_id, data_type: type,
          data_type_range: hashed_data[type], in_year: start_date.year
        )
        new_appt_type_record ||= Analytics::AppointmentTypeOverview.new.tap do |appoint_type|
          appoint_type.organisation_id = organisation_id
          appoint_type.facility_id = facility_id
          appoint_type.specialty_id = specialty_id
          appoint_type.user_id = user_id
          appoint_type.data_type = type
          appoint_type.data_type_range = hashed_data[type]
          appoint_type.appointment_type_id = new_appointment_type.try(:id)
          appoint_type.appointment_type_label = new_appointment_type.try(:label)
          appoint_type.start_date = start_date
          appoint_type.end_date = end_date
          appoint_type.in_year = start_date.year
          appoint_type.save
        end
        new_appt_type_record.inc(appointment_type_count: 1) if new_appt_type_record.present?
      end
    end

    # calls only when appointment got cancelled from    opd_appointments#cancelappointment
    def self.decrement_appointment_category_type_count(appointment_id)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)

      date = appointment.appointmentdate
      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year
      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, _end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        appt_category_type_record = Analytics::AppointmentCategoryTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id, user_id: user_id,
          appointment_category_type_id: appointment.appointment_category_id, data_type: type,
          data_type_range: hashed_data[type], in_year: start_date.year
        )

        if appt_category_type_record && appt_category_type_record.appointment_category_type_count > 0
          appt_category_type_record.inc(appointment_category_type_count: -1)
        end
      end
    end

    # calls only when appointment_edit or reshedule appointments
    def self.update_appointment_category_type_count(appointment_id, past_appointment_category_type_id, past_facility_id, past_specialty_id, past_appointment_date)
      appointment = ::Appointment.find_by(id: appointment_id)
      organisation_id = appointment.try(:organisation_id)
      facility_id = appointment.try(:facility_id)
      specialty_id = appointment.try(:specialty_id)
      user_id = appointment.try(:user_id)
      org_appointment_category_type = OrganisationAppointmentCategoryType.find_by(id: appointment.appointment_category_id)
      date = appointment.appointmentdate
      old_date = past_appointment_date

      hashed_data_old = {}
      hashed_data_old['day'] = old_date.yday
      hashed_data_old['week'] = old_date.cweek
      hashed_data_old['month'] = old_date.month
      hashed_data_old['year'] = old_date.year

      hashed_data = {}
      hashed_data['day'] = date.yday
      hashed_data['week'] = date.cweek
      hashed_data['month'] = date.month
      hashed_data['year'] = date.year

      DATA_CREATION_ARRAY.each_with_index do |type, _indx|
        start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
        if past_appointment_category_type_id.present?
          past_appt_cat_type_record = Analytics::AppointmentCategoryTypeOverview.find_by(
            organisation_id: organisation_id, facility_id: past_facility_id, specialty_id: past_specialty_id,
            appointment_category_type_id: past_appointment_category_type_id, user_id: user_id, data_type: type,
            data_type_range: hashed_data_old[type], in_year: start_date.year
          )
        end

        if past_appt_cat_type_record.present? && past_appt_cat_type_record.try(:appointment_category_type_count) > 0
          past_appt_cat_type_record.inc(appointment_category_type_count: -1)
        end
        next unless appointment.try(:arrived) && appointment.appointment_category_id.present?

        appointment_category_type = Analytics::AppointmentCategoryTypeOverview.find_by(
          organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
          appointment_category_type_id: appointment.appointment_category_id, user_id: user_id, data_type: type,
          data_type_range: hashed_data[type], in_year: start_date.year
        )

        appointment_category_type ||= Analytics::AppointmentCategoryTypeOverview.new.tap do |appoint_cat_type|
          appoint_cat_type.organisation_id = organisation_id
          appoint_cat_type.facility_id = facility_id
          appoint_cat_type.specialty_id = specialty_id
          appoint_cat_type.user_id = user_id
          appoint_cat_type.data_type = type
          appoint_cat_type.data_type_range = hashed_data[type]
          appoint_cat_type.appointment_category_type_id = appointment.appointment_category_id
          appoint_cat_type.appointment_category_type_label = org_appointment_category_type&.label
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
