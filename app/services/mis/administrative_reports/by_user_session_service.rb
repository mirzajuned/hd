module Mis::AdministrativeReports
  class ByUserSessionService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []
        if @request == 'xlsx'
          @data_array << ['Event Date', 'Event Time (UTC)', 'Event Time (Local)', 'User Name', 'User Full Name', 'Role', 'Event', 'Event By', 'Ip Address', 'Device Type', 'Device Name', 'Facility Name']
        end

        aggregation_query, aggregation_query_count = user_session_audits_query
        
        @user_session_audits = UserSessionAudit.collection.aggregate(aggregation_query).to_a || []
        user_session_audits_count = UserSessionAudit.collection.aggregate(aggregation_query_count).to_a

        user_session_audit_data
        total_records = (user_session_audits_count.count if user_session_audits_count.count > 0) || 0
        [@data_array, total_records]
      end

      private

      def user_session_audit_data
        @user_session_audits.each do |ua|
          time_zone = Facility.find(ua[:facility_id]).time_zone
          local_time = ua[:event_datetime].in_time_zone(time_zone).strftime("%I:%M:%S %p")
          utc_time = ua[:event_datetime].strftime("%I:%M:%S %p")
          utc_date = ua[:event_datetime].strftime("%d-%m-%Y")
          @data_array << [utc_date, utc_time, local_time, ua[:user_name], ua[:user_full_name], ua[:user_role], ua[:event], ua[:event_by], ua[:ip_address], ua[:device_type], ua[:device_name], ua[:facility_name]]
        end
      end

      def user_session_audits_query
        aggregation_query = [
          { "$match": match_options },
      
      
      
          { "$sort": { event_datetime: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { event_datetime: -1 } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        match_options = {}

        # Facility/Organisation
        if @mis_params[:facility_id].present?
          facility_ids = [@mis_params[:facility_id], BSON::ObjectId(@mis_params[:facility_id])]
          match_options = match_options.merge(facility_id: { "$in": facility_ids })
        else
          organisation_ids = [@mis_params[:organisation_id], BSON::ObjectId(@mis_params[:organisation_id])]
          match_options = match_options.merge(organisation_id: { "$in": organisation_ids })
        end
        match_options = match_options.merge(event: { "$in": (@mis_params[:event] == "All" || @mis_params[:event].blank?) ? ["Logout", "Login"] : [@mis_params[:event]] })
        # Date/Time
        match_options = match_options.merge(event_datetime: { 
                                                            "$gte": @mis_params[:start_date].beginning_of_day,
                                                            "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end
    end
  end
end
