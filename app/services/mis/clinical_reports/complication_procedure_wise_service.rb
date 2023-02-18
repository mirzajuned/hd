module Mis::ClinicalReports
  class ComplicationProcedureWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['PROCEDURE', 'COMPLETED', 'INTRA-OP-COMPLICATIONS'] if @request == 'xls'

        @procedure_lists = Inpatient::IpdRecord.collection.aggregate(procedure_list_query[0]).to_a || {}
        procedure_list_count = Inpatient::IpdRecord.collection.aggregate(procedure_list_query[1]).to_a
        total_records = procedure_list_count.count > 0 ? procedure_list_count[0][:procedure_list_count] : 0
        procedure_list_data

        [@data_array, total_records]
      end

      private

      def procedure_list_data
        @procedure_lists.try(:each) do |procedure_list|
          procedure_name = procedure_list[:_id]
          performed_count = procedure_list[:performed_count]
          @intra_comp_count = 0
          procedure_list[:complications_lists].each do |comp_list|
            @intra_comp_count += 1 if comp_list[:complication] == 'Yes'
          end
          performed_count = make_anchor_url(performed_count, procedure_name)
          @data_array << [procedure_name, performed_count, @intra_comp_count]
        end
      end

      def forward_params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=inpatient'
        title = '&title=patient_procedure_wise'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + has_params
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"
        back_skip = "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_length = "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length
      end

      def make_anchor_url(performed_count, procedure_name)
        if @request == 'json'
          href = @mis_params[:url] + forward_params + back_params
          if performed_count > 0
            performed_count = "<a href='#{href}&patient_type=#{procedure_name}'
                                data-remote='true'> #{performed_count}</a>"
          end
        end
        performed_count
      end

      def procedure_list_query
        # AdmissionList Query
        aggregation_query = [
          { "$match": match_options },
          { "$unwind": '$procedure' },
          { "$match": { 'procedure.is_performed': true } },
          { "$unwind": '$operative_notes' },
          { "$project": project_options },
          { "$group": group_options },
          { "$sort": { admissiondate: -1 } }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        aggregation_query_count = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": group_options },
          { "$group": { _id: 'null', procedure_list_count: { "$sum": 1 } } }

        ]
        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        # Date
        match_options = match_options.merge(
          "admissiondate": { "$gte": @mis_params[:start_date].beginning_of_day,
                             "$lte": @mis_params[:end_date].end_of_day }
        )

        match_options = match_options.merge(
          "procedure.is_performed": true
        )

        match_options
      end

      def group_options
        { _id: '$procedure.procedurename',
          complications_lists: { "$push": { complication: '$operative_notes.complication' } },
          performed_count: { "$sum": 1 } }
      end

      def project_options
        {
          "admissiondate": 1,
          "procedure.procedurename": 1,
          "operative_notes.complication": 1
        }
      end
    end
  end
end
