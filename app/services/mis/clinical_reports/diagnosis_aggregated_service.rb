module Mis::ClinicalReports
  class DiagnosisAggregatedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.diagnosis_filters(@mis_params)
        end
        # check for alina Vision
        organisation_id = @mis_params[:organisation_id]
        aggregation_query = diagnosis_stats_query
        lists = MisClinical::Common::DiagnosisStats.collection.aggregate(aggregation_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end
        diagnosis_list_data
        [@data_array, total_records]
      end

      private

      def diagnosis_list_data
        @stats_lists.try(:each) do |diagnoses_list|
          diagnosis_data = diagnoses_list[:data]

          diagnosis_data.group_by{ |diagns| diagns['diagnosis_original_name'] }.each do |diagnosis_name, diagnosis|
            generate_aggregate_data(diagnosis, diagnosis_name)
          end
        end
        # @data_array
      end
      # end diagnosis_list_data method

      def generate_aggregate_data(diagnosis, diagnosis_name)
        diagnosis_code = diagnosis.pluck(:'diagnosis_code').uniq.last.upcase.insert(3, '.')
        diagnosis_json_name = "#{diagnosis_name&.titleize} (#{diagnosis_code})"

        ['male', 'female', 'transgender', 'unspecified'].each do |gender|
          instance_variable_set("@#{gender}_till_fifteen", diagnosis.map { |d| d['gender_wise_age']["#{gender}_till_fifteen"].to_i }.sum)
          instance_variable_set("@#{gender}_above_fifteen_till_fiftyfive", diagnosis.map { |d| d['gender_wise_age']["#{gender}_above_fifteen_till_fiftyfive"].to_i }.sum)
          instance_variable_set("@#{gender}_above_fiftyfive", diagnosis.map { |d| d['gender_wise_age']["#{gender}_above_fiftyfive"].to_i }.sum)
          instance_variable_set("@#{gender}_undefined", diagnosis.map { |d| d['gender_wise_age']["#{gender}_undefined"].to_i }.sum)

          total = (instance_variable_get("@#{gender}_till_fifteen") + instance_variable_get("@#{gender}_above_fifteen_till_fiftyfive") + instance_variable_get("@#{gender}_above_fiftyfive") + instance_variable_get("@#{gender}_undefined"))
          
          if @request == 'json'
            @data_array << [ diagnosis_json_name, gender.titleize, instance_variable_get("@#{gender}_till_fifteen") || 0, instance_variable_get("@#{gender}_above_fifteen_till_fiftyfive") || 0, instance_variable_get("@#{gender}_above_fiftyfive") || 0, instance_variable_get("@#{gender}_undefined") || 0, total ]
            diagnosis_json_name = ''
          else
            @data_array << [ diagnosis_name&.titleize, diagnosis_code, gender.titleize, instance_variable_get("@#{gender}_till_fifteen") || 0, instance_variable_get("@#{gender}_above_fifteen_till_fiftyfive") || 0, instance_variable_get("@#{gender}_above_fiftyfive") || 0, instance_variable_get("@#{gender}_undefined") || 0, total ]
          end
        end
      end
      # EOF generate_aggregate_data

      def diagnosis_stats_query
        Mis::ClinicalService::DiagnosisQueryBuilder.call(@mis_params, @request, true)
      end
    end
  end
end
