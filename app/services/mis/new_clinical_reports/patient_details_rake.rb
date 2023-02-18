# rubocop:disable all
module Mis::NewClinicalReports
  class PatientDetailsRake
    class << self
      # rubocop:disable Layout/LineLength
      def call(start_date, end_date, organisation_ids, current_state = nil)
        begin
          mis_logger = Logger.new("#{Rails.root}/log/mis_patient_details_logger.log")
          @current_state = current_state
          query = aggregation_query(start_date, end_date, organisation_ids)
          # appointment_list_wise = AppointmentListView.collection.aggregate(query).to_a
          if @current_state.present?
            appointment_list_wise = AppointmentListView.where(query)
            appointment_list_wise.each do |list|
              Mis::NewClinicalReports::Opd::AppointmentDetailsService.call(list.id.to_s)
            end
          else
            AppointmentListView.where(created_at: start_date..end_date, :organisation_id.in => organisation_ids).or(updated_at: start_date..end_date, :organisation_id.in => organisation_ids).or(appointment_date: start_date..end_date, :organisation_id.in => organisation_ids).batch_size(1000).each do |list|
              # binding.pry
              Mis::NewClinicalReports::Opd::AppointmentDetailsService.call(list.id.to_s)
            end
          end
        rescue StandardError => e
          mis_logger.info(" === Error in PatientDetailsRake while importing appointment details data- out : #{e.inspect}")
        end
      end
      def aggregation_query(start_date, end_date, organisation_ids)
        if @current_state.present?
          match_options = { current_state: @current_state, created_at: start_date..end_date }
        else
          match_options =  { :organisation_id.in => organisation_ids }
        end
        match_options
      end
    end
  end
end