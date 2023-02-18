# rubocop:disable all
module Mis::NewClinicalReports
  class DailyStatsRake
    class << self
      def call(start_date, end_date, organisation_ids)
        mis_logger = Logger.new("#{Rails.root}/log/mis_daily_stats_logger.log")
        # query = aggregation_query(start_date, end_date, organisation_ids)
        # date_wise_list = AppointmentListView.collection.aggregate(query, { allow_disk_use: true })#.to_a
        appointment_lists = AppointmentListView.where(appointment_date: start_date..end_date, :organisation_id.in => organisation_ids)
        date_wise_list = appointment_lists.group_by { |al| al[:appointment_date] }
        date_wise_list.each do |key, value|
          # key = val[:_id]
          # value = val[:appointment_lists]
          appointment_date = key
          group_by_organisations = value.group_by { |al| al[:organisation_id] }
          group_by_organisations.each do |organisation_id, group_by_organisation|
            group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
            group_by_facilities.each do |facility_id, group_by_facility|
              current_state_group = group_by_facility.group_by { |al| al[:current_state] }
              current_appointmenttype_group = group_by_facility.group_by { |al| al[:appointmenttype] }

              not_arrived = current_state_group['Scheduled'].to_a.size
              completed = current_state_group['Completed'].to_a.size
              incompleted = current_state_group['Waiting'].to_a.size + current_state_group['Engaged'].to_a.size +
                            current_state_group['Incompleted'].to_a.size
              cancelled = current_state_group['Deleted'].to_a.size

              clinical_opd_record = MisClinical::Opd::ClinicalReportOpd.where('appointment_display_fields.appointment_date' => appointment_date, facility_id: facility_id.to_s, organisation_id: organisation_id.to_s)
              patient_visit = clinical_opd_record.group_by { |al| al['patient_display_fields.patient_visit'] }
              follow_up = patient_visit['Followup'].to_a.size
              new = patient_visit['New'].to_a.size
              post_visit = patient_visit['Post Op'].to_a.size
              walkin = current_appointmenttype_group['walkin'].to_a.size
              appointment = current_appointmenttype_group['appointment'].to_a.size
              engaged_arr = group_by_facility.map { |app| Mis::ClinicalService::AppointmentReportConverter.get_avg_engaged_time_epoc(app[:appointment_id]) }
              total_arr = group_by_facility.map { |app| Mis::ClinicalService::AppointmentReportConverter.get_total_time_epoch(app[:appointment_id]) }
              avg_total_time = total_arr.inject{ |sum, el| sum + el }.to_f / total_arr.size
              avg_engaged_time = engaged_arr.inject{ |sum, el| sum + el }.to_f / total_arr.size
              avg_total_time_in_format = Mis::ClinicalService::AppointmentReportConverter.convert_time(avg_total_time.to_i)
              avg_waiting_time_in_format = 0
              avg_engaged_time_in_format = Mis::ClinicalService::AppointmentReportConverter.convert_time(avg_engaged_time.to_i)
              max_total_time = total_arr.max
              max_total_time_in_format = Mis::ClinicalService::AppointmentReportConverter.convert_time(max_total_time.to_i)
              max_waiting_time = 0
              max_engaged_time = 0

              appointment_stats_fields = { not_arrived: not_arrived, completed: completed, incompleted: incompleted,
                                           cancelled: cancelled }
              patient_stats_fields = { new: new, follow_up: follow_up, post_op: post_visit }
              appointment_type_stats_fields = { walkin: walkin, appointment: appointment }
              turnaround_time_stats_fields = { avg_waiting_time: avg_waiting_time_in_format,
                                               avg_engaged_time: avg_engaged_time_in_format,
                                               avg_total_time: avg_total_time_in_format, max_total_time: max_total_time_in_format,
                                               max_waiting_time: max_waiting_time, max_engaged_time: max_engaged_time }

              opd_statistics = MisClinical::Opd::OpdStatistic.find_or_create_by(
                appointment_date: appointment_date, facility_id: facility_id
              )
              opd_statistics.organisation_id = organisation_id
              opd_statistics.appointment_stats_fields = appointment_stats_fields
              opd_statistics.patient_stats_fields = patient_stats_fields
              opd_statistics.appointment_type_stats_fields = appointment_type_stats_fields
              opd_statistics.turnaround_time_stats_fields = turnaround_time_stats_fields
              opd_statistics.save!
            end
          end
        end
      rescue StandardError => e
        mis_logger.info(" === Error in DailyStatsRake - out : #{e.inspect}")
      end
      
      def aggregation_query(start_date, end_date, organisation_ids)
        appointment_date_condition = { "appointment_date": { "$gte"=> start_date, "$lte" => end_date }  }
        match_options =  { organisation_id: { "$in": organisation_ids } }
        match_options = match_options.merge( appointment_date_condition )
        aggregationquery = [
                  { "$match": match_options },
                  { "$group":  {_id: '$appointment_date', appointment_lists: { "$push": '$$ROOT' }} }
                ]
        aggregationquery
      end
    end
  end
end
