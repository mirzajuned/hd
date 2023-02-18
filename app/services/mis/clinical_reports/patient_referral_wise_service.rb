module Mis::ClinicalReports
  class PatientReferralWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['REFERRAL', 'TOTAL'] unless @request == 'json'

        aggregation_query, aggregation_query_count = referral_type_query

        @referral_types = PatientReferralType.collection.aggregate(aggregation_query).to_a || []
        referral_type_list_count = PatientReferralType.collection.aggregate(aggregation_query_count).to_a
        total_records = referral_type_list_count.count > 0 ? referral_type_list_count[0][:referral_type_list_count] : 0

        referral_type_ids = @referral_types.map { |type| type[:_id] }
        get_referral_fields(referral_type_ids) if referral_type_ids.present? && referral_type_ids.count > 0

        referral_type_data

        [@data_array, total_records]
      end

      private

      def referral_type_data
        @referral_types.try(:each) do |referral_type|
          referral = @referral_fields.find { |f| f[:id].to_s == referral_type[:_id].to_s }
          next if referral.nil?

          referral_name = referral[:name]
          count = referral_type[:referral_type_count]

          @data_array << [referral_name, count]
        end
      end

      def referral_type_query
        # ReferralTypeList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$referral_type_id', referral_type_count: { "$sum": 1 } } },
          { "$sort": { referral_type_id: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # ReferralTypeList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$referral_type_id', referral_type_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', referral_type_list_count: { "$sum": 1 } } }
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
        match_options = match_options.merge(created_at: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                          "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end

      def get_referral_fields(referral_ids)
        referrals = ReferralType.where(:id.in => referral_ids)
        @referral_fields = referrals.map { |referral| { id: referral.id.to_s, name: referral.name } }
      end
    end
  end
end
