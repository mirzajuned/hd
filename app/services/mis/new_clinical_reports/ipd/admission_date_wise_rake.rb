module Mis::NewClinicalReports::Ipd
  class AdmissionDateWiseRake
    class << self
      def call(start_date, end_date, org_id = nil)
        # TODO: send facility id or organisation id to decide to migrated and also add is_migrated
        facilities = if org_id.present?
                       Organisation.find_by(id: org_id)&.facilities || []
                     else
                       # Facility.all
                     end
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          # :created_at.gte => start_date.beginning_of_day
          scheduled_date_query = aggregation_query_scheduled_date(start_date, end_date, facility_id, organisation_id)
          admission_date_query = aggregation_query_admission_date(start_date, end_date, facility_id, organisation_id)
          discharge_date_query = aggregation_query_discharge_date(start_date, end_date, facility_id, organisation_id)

          scheduled_list_wise =  MisClinical::Ipd::ClinicalReportIpd.collection.aggregate(scheduled_date_query).to_a
          discharged_list_wise = MisClinical::Ipd::ClinicalReportIpd.collection.aggregate(discharge_date_query).to_a
          admission_list_wise = MisClinical::Ipd::ClinicalReportIpd.collection.aggregate(admission_date_query).to_a

          # loop from one date to another date
          # [{date: date, list: []}, {date: date, list: [], total: 2}]
          # todo decide if list is needed or not
          (start_date.to_date..end_date.to_date).each do |date|
            if admission_list_wise.present?
              admission_list = admission_list_wise.select { |arr| arr[:_id] == date }
              if admission_list.present? && admission_list[0][:lists].present?
                admission_list = admission_list[0][:lists].select { |list| admitted(list[:current_state]) }
              end
            end
            if discharged_list_wise.present?
              discharged_list = discharged_list_wise.select { |arr| arr[:_id] == date }
              if discharged_list.present? && discharged_list[0][:lists].present?
                discharged_list = discharged_list[0][:lists].select { |list| discharged(list[:current_state]) }
              end
            end
            if scheduled_list_wise.present?
              scheduled_list = scheduled_list_wise.select { |arr| arr[:_id] == date }
              if scheduled_list.present? && scheduled_list[0][:lists].present?
                scheduled_list = scheduled_list[0][:lists].select { |list| scheduled(list[:current_state]) }
              end
            end

            scheduled_list ||= []
            discharged_list ||= []
            admission_list ||= []

            admitted = admission_list.count
            scheduled = scheduled_list.count
            discharged = discharged_list.count

            admission_stats_fields = { scheduled: scheduled, admitted: admitted, discharged: discharged }

            admission_details = MisClinical::Ipd::AdmissionDateWise.find_or_create_by(
              organisation_id: organisation_id, facility_id: facility_id,
              created_date: date
            )
            admission_details.admission_stats_fields = admission_stats_fields
            admission_details.save!
          end
        end
      rescue StandardError => e
        mis_logger.info(" === Error in AdmissionDateWiseRake while importing admission data: #{e.inspect}")
      end

      def admitted(current_state)
        ['Discharged', 'Admitted'].include?(current_state) && current_state != 'Cancelled'
      end

      def discharged(current_state)
        ['Discharged'].include?(current_state) && current_state != 'Cancelled'
      end

      def scheduled(current_state)
        current_state != 'Cancelled'
      end

      def aggregation_query_scheduled_date(start_date, end_date, facility_id, organisation_id)
        scheduled_date_condition = { "scheduled_date": { '$gte' => start_date, '$lte' => end_date } }
        match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = match_options.merge(scheduled_date_condition)
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$scheduled_date', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end

      def aggregation_query_admission_date(start_date, end_date, facility_id, organisation_id)
        admission_date_condition = { "admission_date": { '$gte' => start_date, '$lte' => end_date } }
        match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = match_options.merge(admission_date_condition)
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$admission_date', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end

      def aggregation_query_discharge_date(start_date, end_date, facility_id, organisation_id)
        discharge_date_condition = { "discharge_date": { '$gte' => start_date, '$lte' => end_date } }
        match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = match_options.merge(discharge_date_condition)
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$discharge_date', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end
    end
  end
end
