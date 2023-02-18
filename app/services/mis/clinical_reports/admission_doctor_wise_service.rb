module Mis::ClinicalReports
  class AdmissionDoctorWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DOCTOR NAME', 'TOTAL PATIENTS SEEN'] unless @request == 'json'

        aggregation_query, aggregation_query_count = admission_list_query

        @admission_lists = AdmissionListView.collection.aggregate(aggregation_query).to_a || []
        admission_list_count = AdmissionListView.collection.aggregate(aggregation_query_count).to_a
        total_records = admission_list_count.count > 0 ? admission_list_count[0][:admission_list_count] : 0

        admission_user_ids = @admission_lists.map { |admission| admission[:_id] }
        get_user_fields(admission_user_ids) if admission_user_ids.present? && admission_user_ids.count > 0

        admission_list_data

        [@data_array, total_records]
      end

      private

      def admission_list_data
        @admission_lists.try(:each) do |admission_list|
          user = @user_fields.find { |f| f[:id].to_s == admission_list[:_id].to_s }
          next if user.nil?

          fullname = user[:fullname]
          count = admission_list[:doctor_admission_count]

          if @request == 'json' && count > 0
            href = @mis_params[:url] + forward_params(admission_list) + back_params
            count = "<a href='#{href}' data-remote='true'>#{count}</a>"
          end

          @data_array << [fullname, count]
        end
      end

      def forward_params(admission_list)
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=inpatient'
        title = '&title=admission_list_wise'
        doctor_id = "&admitting_doctor_id=#{admission_list[:_id]}"
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + doctor_id
        + has_params
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"
        back_skip = "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_length = "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        has_params = '&has_params=true'
        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length +
          has_params
      end

      def admission_list_query
        # DoctorAppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$admitting_doctor_id', doctor_admission_count: { "$sum": 1 } } },
          { "$sort": { doctor_admission_count: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # DoctorAppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$admitting_doctor_id', doctor_admission_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', admission_list_count: { "$sum": 1 } } }
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
          "$or": [{ admission_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                      "$lte": @mis_params[:end_date].end_of_day },
                    current_state: { "$ne": 'Discharged' } },
                  { discharge_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                      "$lte": @mis_params[:end_date].end_of_day },
                    current_state: 'Discharged' }]
        )

        # Seen Patients
        match_options = match_options.merge(state: { "$ne": 'Deleted' })

        match_options
      end

      def get_user_fields(user_ids)
        users = User.where(:id.in => user_ids)
        @user_fields = users.map { |user| { id: user.id.to_s, fullname: user.fullname } }
      end
    end
  end
end
