# rubocop:disable all
module Mis::ClinicalReports
  class ProcedureDetailService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.procedure_filters(@mis_params)
        end
        aggregation_query = procedure_list_query
        admission_list = MisClinical::Common::PatientProcedureWise.collection.aggregate(aggregation_query).to_a[0] || {}
        @patient_list = admission_list[:data] || []
        total_records = unless @request == 'json'
                         admission_list[:total] || 0
                       else
                         admission_list[:metadata].present? ? admission_list[:metadata][0][:total] : 0
                       end
        procedure_wise_list
        [@data_array, total_records]
      end

      private

      def procedure_wise_list
        @patient_list.each do |list|
          advised_on = (list[:advised_datetime].present?) ? convert_date(list[:advised_datetime]) : '--'
          advised_by = (list[:advised_by].present?) ? list[:advised_by].titleize : '--'
          procedure_name = list[:procedurename]
          performed_by = (list[:performed_by].present?) ? list[:performed_by].titleize : '--'
          performed_on = if list[:performed_time].present?
                            convert_date(list[:performed_time])
                          elsif list[:performed_datetime].present?
                            convert_date(list[:performed_datetime])
                          else
                            '--'
                          end
          laterality = procedure_side(list[:procedureside])
          status = Mis::Constants::Badge.procedure_state(conversion_state(list[:is_performed], list[:is_advised]))
          country_id = Facility.find_by(id: list[:facility_id]).country_id rescue 'IN_108'
          patient_name = list[:patient_details][:patient_name]&.titleize
          patient_display_id = list[:patient_details][:patient_display_id]
          patient_mr_no = (list[:patient_details][:patient_mr_no].present?) ? list[:patient_details][:patient_mr_no] : '-'
          patient_age = (list[:patient_details][:patient_age].present?) ? list[:patient_details][:patient_age] : ''
          gender = list[:patient_details][:patient_gender]
          address_1 = list[:patient_details][:address_1]
          address_2 = list[:patient_details][:address_2]
          mobile = list[:patient_details][:patient_mobilenumber]
          commune = list[:patient_details][:commune]
          area = list[:patient_details][:area_manager_name].present? ? list[:patient_details][:area_manager_name] : '-'
          city = (list[:patient_details][:city]. present? && list[:patient_details][:city] != 'null') ? list[:patient_details][:city] : ''
          district = (list[:patient_details][:district].present? && list[:patient_details][:district] != 'null') ? list[:patient_details][:district] : ''
          state = (list[:patient_details][:state].present? && list[:patient_details][:state] != 'null') ? list[:patient_details][:state] : ''
          pincode = (list[:patient_details][:pincode].present? && list[:patient_details][:pincode] != 0) ? list[:patient_details][:pincode].to_s : ''
          location = display_location(address_1, address_2, city, state, commune, district, pincode)
          conversion_days = list[:conversion_time_days].present? ? list[:conversion_time_days] : 'NA'

          if @request == 'json'
            patient_detail = (patient_name || "") +  "<br>" + (patient_age || '') + "<br>" + (mobile || "")
            patient_detail += "<br>" + ((Mis::Constants::Badge.gender_type(gender)) || "")
          
            @data_array << [advised_on, performed_on, advised_by, performed_by, procedure_name, laterality, patient_detail, patient_display_id, patient_mr_no, area, location, status, conversion_days ]
          else
            patient_age = age_in_years(list[:patient_details][:patient_age])
            loc2 = (country_id == 'VN_254') ? commune : state
            loc3 = (country_id == 'VN_254') ? district : pincode
            status = ActionView::Base.full_sanitizer.sanitize(status)
            laterality = ActionView::Base.full_sanitizer.sanitize(laterality)
            @data_array << [advised_on, performed_on, advised_by, performed_by, procedure_name, laterality, patient_name, patient_display_id, patient_mr_no, mobile, patient_age, gender, area, address_1, address_2, city, loc2, loc3, status, conversion_days ]
          end
        end
      end

      def procedure_list_query
        Mis::ClinicalService::ProcedureQueryBuilder.call(@mis_params, @request)
      end

      def procedure_side(side)
        case side
          when '8966001'
            '<div class="badge badge-purple"> Left </div>'
          when '18944008'
            '<div class="badge badge-yellow"> Right </div>'
          else
            '<div class="badge badge-green"> BE </div>'
        end
      end

      def conversion_state(is_performed, is_advised)
        if is_performed && is_advised
          "Performed"
        else
          "Advised"
        end
      end

      def age_in_years(age)
        return_age = age
        if @request == 'xls' && age.present?
          age_ary = return_age.split(' ')
          if age_ary.count == 2 && age_ary[-1] == 'Months'
            # return_age = age
            return_age = 0 #age should be in years only
          else
            return_age = age_ary[0]
          end
        end
        return_age
      end
      # EOF age_in_years

      def display_location(address_1, address_2, city, state, commune, district, pincode)
        location = ''
        location += address_1 if address_1.present?
        location += "<br>" + address_2 if address_2.present?
        location += "<br>" + city if city.present?
        location += "<br>" + state if state.present?
        location += "<br>" + commune if commune.present?
        location += "<br>" + district if district.present?
        location += "<br>" + pincode if pincode.present?
        location.present? ? location.sub('<br>','') : '-'
      end
      # EOF display_location

      def convert_date(datetime)
        Time.zone.parse(datetime.to_s).to_s(:hg_history_date_time)
      end
      # end convert_date

    end
  end
end
