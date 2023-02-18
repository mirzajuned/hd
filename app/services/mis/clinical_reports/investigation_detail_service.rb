module Mis::ClinicalReports
  class InvestigationDetailService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @facility = Facility.find(@mis_params[:facility_id])
        @facility_timezone = @facility.time_zone
        @country_id = @facility.country_id
        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params)
        end
        document = Investigation::InvestigationDetail.collection.aggregate(query).to_a[0] || {}
        @collection = document[:data] || []
        total_records =if @request == 'json'
                 document[:metadata].present? ? document[:metadata][0][:total] : 0
               else
                 document[:total] || 0
               end
        collect
        [@data_array, total_records]
      end

      def collect
        @collection.each do |inv|
          performed_at = inv[:performed_at]&.in_time_zone(@facility_timezone)&.strftime('%d/%m/%Y %I:%M %p') || '--'
          advised_at = inv[:advised_at]&.in_time_zone(@facility_timezone)&.strftime('%d/%m/%Y %I:%M %p') || '--'
          status = inv[:performed_at].present? ? 'Performed' : 'Advised'
          
          name = "#{inv[:name]} #{inv[:specialization]}"
          performed_location = if inv[:performed_outside] == true
                                 inv[:performed_outside_by]
                               elsif inv[:performed_at].present?
                                 @facility.name
                               else
                                 ""
                               end

          convertion_time = if inv[:performed_at].present?
                              (inv[:performed_at].to_date - inv[:advised_at].to_date).to_i
                            else
                              'NA'
                            end
          area = inv[:area_manager_name].present? ? inv[:area_manager_name] : '-'
          if @request == 'json'            
            patient_detail = "#{inv[:patient_fullname]} <br> #{inv[:patient_age]} <br> #{inv[:patient_mobilenumber]}"
            patient_detail += "<br>" + ((Mis::Constants::Badge.gender_type(inv[:patient_gender])) || "")

            @data_array << [
              advised_at, performed_at, inv[:advised_by_username], inv[:performed_by_username],
              performed_location, inv[:reviewed_by_username], name,
              patient_detail, inv[:patient_display_id], inv[:patient_mrno], area,
              inv[:patient_location], status, inv[:state]&.titleize, convertion_time
            ] 
          else
            loc2 = (@country_id == 'VN_254') ? inv[:patient_commune] : inv[:patient_state]
            loc3 = (@country_id == 'VN_254') ? inv[:patient_district] : inv[:patient_pincode]
            city = inv[:patient_city]
            @data_array << [
              advised_at, performed_at, inv[:advised_by_username], inv[:performed_by_username],
              performed_location, inv[:reviewed_by_username], name,inv[:patient_fullname], 
              inv[:patient_display_id], inv[:patient_mrno], inv[:patient_mobilenumber], inv[:patient_age], inv[:patient_gender]&.titleize, area, city, loc2, loc3, status, inv[:state]&.titleize, convertion_time
            ] 
          end       
        end
      end

      def query
        Mis::ClinicalService::InvestigationQueryBuilder.call(@mis_params, @request)
      end

    end
  end
end
