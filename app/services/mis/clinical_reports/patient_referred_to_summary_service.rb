# rubocop:disable all
module Mis::ClinicalReports
  class PatientReferredToSummaryService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.referral_filters(@mis_params)
        end
        aggregation_query = patient_referral_list_query
        patient_referral_list = MisClinical::Opd::DoctorPatientReferralSummaryReport.collection.aggregate(aggregation_query).to_a[0] || {}
        @patient_referral_list = patient_referral_list[:data] || []
        total_records =unless @request == 'json'
                         patient_referral_list[:total] || 0
                       else
                         patient_referral_list[:metadata].present? ? patient_referral_list[:metadata][0][:total] : 0
                       end
        patient_referral_wise_list
        [@data_array, total_records]
      end

      private

      def patient_referral_wise_list
        @patient_referral_list.each do |list|
          # date = list[:referred_on_date_time]&.to_s(:hg_history_date_time)
          date = convert_date(list[:referred_on_date_time])
          patient_details = list[:patient_display_fields]
          patient_display_id = (patient_details[:patient_identifier_id].present?) ? patient_details[:patient_identifier_id] : '-'
          patient_name = (patient_details[:patient_name].present?) ? patient_details[:patient_name].titleize : '-'
          patient_mr_no = (patient_details[:patient_mrn].present?) ? patient_details[:patient_mrn] : '-'
          gender = patient_details[:gender]
          patient_age = (patient_details[:exact_age].present?) ? patient_details[:exact_age] : '-'
          mobile = (patient_details[:mobilenumber].present?) ? patient_details[:mobilenumber] : '-'
          area = (patient_details[:area_manager_name].present?) ? patient_details[:area_manager_name] : '-'
          commune = patient_details[:commune]
          city = (patient_details[:city]. present?) ? patient_details[:city] : ''
          district = (patient_details[:district].present?) ? patient_details[:district] : ''
          state = (patient_details[:state].present?) ? patient_details[:state] : ''
          pincode = (patient_details[:pincode].present? && patient_details[:pincode] != 0) ? patient_details[:pincode].to_s : ''
          location = display_location(city, state, commune, district, pincode)
          sohw_location = (location.present?) ? location : '-' 
          country_id = Facility.find_by(id: list[:facility_id]).country_id rescue 'IN_108'

          referred_by = (list[:from_doctor_name].present?) ? list[:from_doctor_name].titleize : '-'
          referral_type = (list[:referral_type_name].present?) ? list[:referral_type_name].titleize : '-'
          to_doctor_name = (list[:to_doctor_name].present?) ? list[:to_doctor_name].titleize : '-'
          to_facility_name = (list[:to_facility_name].present?) ? list[:to_facility_name].titleize : '-'
          referral_time = (list[:referral_date_time].present?) ? convert_date(list[:referral_date_time], referral_type) : '-'
          referral_details = "#{to_doctor_name}<br>#{to_facility_name}<br>#{referral_time}"
          referral_notes = (list[:referral_notes].present?) ? list[:referral_notes].titleize : '-'
          diagnoses = list[:diagnoses]; display_diagnoses = ''; 
          diagnosisname = diagnosis_code = ''
          if diagnoses.present?
            diagnoses.each do |diagnosis|
              d_name = diagnosis['original_name']
              d_code = diagnosis['diagnosis_code'].upcase.insert(3, '.')
              display_diagnoses += "<li>#{d_name} (#{d_code})</li>"
              diagnosisname += "#{d_name}\n"
              diagnosis_code += "#{d_code}\n"
            end
          end
          
          if @request == 'json'
            referral_type = "<span class='badge #{referral_type.parameterize}'>#{referral_type}</span>"
            gender = (gender.present?) ? Mis::Constants::Badge.gender_type(gender) : '-'
            patient_detail = "#{patient_name}<br>#{patient_age}<br>#{mobile}<br>#{gender}"
          
            @data_array << [date, patient_detail, patient_display_id, patient_mr_no, area, sohw_location, referred_by, referral_type, referral_details, referral_notes, display_diagnoses ]
          else
            patient_age = age_in_years(patient_details[:exact_age])
            loc2 = (country_id == 'VN_254') ? commune : state
            loc3 = (country_id == 'VN_254') ? district : pincode
            # patient_age = patient_age.to_i if patient_age.present?

            @data_array << [ date, patient_display_id, patient_name, patient_mr_no, mobile, patient_age, gender, area, 
                             city, loc2, loc3, referred_by, referral_type, to_doctor_name, to_facility_name, 
                             referral_time, referral_notes, diagnosisname.strip, diagnosis_code.strip ]
          end
        end
      end

      def patient_referral_list_query
        Mis::ClinicalService::PatientReferralQueryBuilder.call(@mis_params, @request)
      end

      def convert_date(datetime, referral_type='')
        if referral_type == 'Outside Organisation'
          datetime.to_date.to_s(:hg_taper_date_format)
        else
          Time.zone.parse(datetime.to_s).to_s(:hg_history_date_time)
        end
        
      end
      # EOF convert_date

      def age_in_years(age)
        return_age = age
        if @request != 'json' && age.present?
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

      def display_location(city, state, commune, district, pincode)
        location = ''
        location += city if city.present?
        location += "<br>" + state if state.present?
        location += "<br>" + commune if commune.present?
        location += "<br>" + district if district.present?
        location += "<br>" + pincode if pincode.present?
        location.present? ? location.sub('<br>','') : '-'
      end
      # EOF display_location

    end
  end
end
