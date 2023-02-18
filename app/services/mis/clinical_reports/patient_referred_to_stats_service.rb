module Mis::ClinicalReports
  class PatientReferredToStatsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @data_array << Mis::Constants::ReportSheetFilters.referral_filters(@mis_params) unless @request == 'json'
        aggregation_query = referral_stats_query
        lists = MisClinical::Opd::DoctorPatientReferralStats.collection.aggregate(aggregation_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end
        referral_list_data
        [@data_array, total_records]
      end

      private

      def referral_list_data
        @stats_lists.try(:each) do |referrals_list|
          referral_data = referrals_list[:data]
          referral_date = referrals_list[:_id].to_s(:hg_date_format)
          referral_data.group_by{ |inv| inv['referred_date'] }.each do |referred_date, referrals|
            intra_facility_count = referrals.pluck(:intra_facility_count).sum
            inter_facility_count = referrals.pluck(:inter_facility_count).sum
            outside_organisation_count = referrals.pluck(:outside_organisation_count).sum
            
            forward_params = forward_params(@mis_params[:facility_id], referrals_list[:_id])
            forward_params_intra = forward_params(@mis_params[:facility_id], referrals_list[:_id], 'Intra Facility')
            forward_params_inter = forward_params(@mis_params[:facility_id], referrals_list[:_id], 'Inter Facility')
            forward_params_outside = forward_params(@mis_params[:facility_id], referrals_list[:_id], 'Outside Organisation')

            href = @mis_params[:url] + forward_params + back_params
            href_intra = @mis_params[:url] + forward_params_intra + back_params
            href_inter = @mis_params[:url] + forward_params_inter + back_params
            href_outside = @mis_params[:url] + forward_params_outside + back_params

            if @request == 'json'
              referral_date = "<a href='#{href}' data-remote='true'>#{referral_date}</a>"
              intra_facility_count = "<a href='#{href_intra}' data-remote='true'>#{intra_facility_count}</a>" if intra_facility_count > 0
              inter_facility_count = "<a href='#{href_inter}' data-remote='true'>#{inter_facility_count}</a>" if inter_facility_count > 0
              outside_organisation_count = "<a href='#{href_outside}' data-remote='true'>#{outside_organisation_count}</a>" if outside_organisation_count > 0
            end

            @data_array << [referral_date, intra_facility_count, inter_facility_count, outside_organisation_count]
          end
        end
        # @data_array
      end
      # end referral_list_data method

      def referral_stats_query
        Mis::ClinicalService::PatientReferralStatsQueryBuilder.call(@mis_params, @request)
      end
      # end referral_stats_query method

      def forward_params(facility_id, referral_date, referral_type = nil)
        params_str = "&start_date=#{referral_date}"
        params_str += "&end_date=#{referral_date}"
        params_str += "&time_period=#{@mis_params[:time_period]}"
        params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
        params_str += "&facility_id=#{facility_id}"
        params_str += "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        params_str += "&referral_type=#{referral_type}" if referral_type.present?
        params_str += '&group=referral'
        params_str += '&title=patient_referred_to_summary'
        params_str += '&has_params=true'

        params_str
      end
      # EOF forward_params

      def back_params
        back_params_str = "&back_start_date=#{@mis_params[:start_date]}"
        back_params_str += "&back_end_date=#{@mis_params[:end_date]}"
        back_params_str += "&back_time_period=#{@mis_params[:time_period]}"
        back_params_str += "&back_group=#{@mis_params[:group]}"
        back_params_str += "&back_title=#{@mis_params[:title]}"
        back_params_str += "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_params_str += "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        back_params_str += '&has_params=true'

        back_params_str
      end
      # EOF back_params
    end
  end
end
