module Mis::ClinicalReports
  class PatientTimeSpentWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @non_role_keys = ['incomplete', 'complete', 'away', 'not_arrived']
        @data_array = []

        if @request == 'xlsx'
          @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params)
        end
        aggregation_query = appointment_list_query
        appointment_patient = MisClinical::Opd::ClinicalReportOpd.collection.aggregate(aggregation_query).to_a[0] || {}
        @patient_list = appointment_patient[:data] || []
        total_records = if @request == 'xlsx'
                          appointment_patient[:total] || 0
                        else
                          appointment_patient[:metadata].present? ? appointment_patient[:metadata][0][:total] : 0
                        end
        patient_wise_list
        [@data_array, total_records]
      end

      private

      def patient_wise_list
        @patient_list.each do |list|
          patient_fields = list[:patient_display_fields]
          name = patient_fields[:patient_name].present? ? patient_fields[:patient_name] : '--'
          phone = (patient_fields[:patient_mobilenumber].present?) ? patient_fields[:patient_mobilenumber] : '--'
          age = patient_fields[:patient_age].present? ? patient_fields[:patient_age] : ''
          gender = patient_fields[:patient_gender].present? ? patient_fields[:patient_gender] : '--'
          area = patient_fields[:area_manager_name].present? ? patient_fields[:area_manager_name] : '-'
          location = (patient_fields[:city] || '') + ' ' + (patient_fields[:state] || '')

          patient_id = patient_fields[:patient_display_id].present? ? patient_fields[:patient_display_id] : '--'
          patient_mr_no = patient_fields[:patient_mr_no].present? ? patient_fields[:patient_mr_no] : '--'
          appointment_id = list[:appointment_display_fields][:appointment_display_id].present? ? list[:appointment_display_fields][:appointment_display_id] : '--'
          patient_vist = patient_fields[:patient_visit]
          appointmenttype = list[:appointment_display_fields][:appointmenttype]
          appointment_reason = list[:appointment_display_fields][:appointment_type]
          appointment_doctor = list[:appointment_display_fields][:consulting_doctor]
          total_time_mins = if list[:patient_role_wise_tat_secs].present?
              list[:patient_role_wise_tat_secs].sum {|item| @non_role_keys.include?(item[0]) ? 0 : item[1].to_f } / 60
            else
              0
            end
          total_time_mins = total_time_mins.round
          total_time = "#{total_time_mins/60} H #{total_time_mins%60} M"
          waiting_time = list[:appointment_display_fields][:waiting_time]
          engaged_time = list[:appointment_display_fields][:engaged_time]
          current_state = list[:appointment_display_fields][:current_state]
          other_doctors = list[:appointment_display_fields][:other_doctors]#&.split(',')&.uniq&.join
          other_users = list[:appointment_display_fields][:other_users]
          date = convert_date(list[:appointment_display_fields][:appointment_start_time])
          patient_referral_type = (patient_fields[:referral_type].present?) ? patient_fields[:referral_type] : '--'
          patient_sub_referral_type = (patient_fields[:sub_referral_type_name].present?) ? patient_fields[:sub_referral_type_name] : '--'
          appointment_referral_type = (list[:appointment_display_fields][:referral_type].present?) ? list[:appointment_display_fields][:referral_type] : '--'
          appointment_sub_referral_type = (list[:appointment_display_fields][:sub_referral_type_name].present?) ? list[:appointment_display_fields][:sub_referral_type_name] : '--'

          commune = (patient_fields[:commune].present?) ? patient_fields[:commune] : ''
          city = (patient_fields[:city]. present?) ? patient_fields[:city] : ''
          district = (patient_fields[:district].present?) ? patient_fields[:district] : ''
          state = (patient_fields[:state].present?) ? patient_fields[:state] : ''
          pincode = (patient_fields[:pincode].present? && patient_fields[:pincode] != 0) ? patient_fields[:pincode].to_s : ''
          location = display_location(city, state, commune, district, pincode)
          country_id = Facility.find_by(id: list[:facility_id]).country_id rescue 'IN_108'
          diagnosis_name = diagnosis_code = diagnoses = procedure_name = procedure_code = procedures = ''
          if list[:diagnoses].present?
            list[:diagnoses].each do |diagnosis|
              if diagnosis['originalname'].present?
                d_name = diagnosis['originalname'].titleize
                diagnosis_name += "#{d_name}, "
              end
              if diagnosis['diagnosis_code'].present?
                d_code = diagnosis['diagnosis_code'].upcase.insert(3, '.')
                diagnosis_code += "#{d_code}, "
              end
              diagnoses += "<li>#{d_name} (#{d_code})</li>" if d_name.present? && d_code.present?
            end
          end
          diagnoses = '--' unless diagnoses.present?
          diagnosis_name = diagnosis_name.present? ? diagnosis_name.chomp(', ') : '--'
          diagnosis_code = diagnosis_code.present? ? diagnosis_code.chomp(', ') : '--'
          if list[:procedures].present?
            list[:procedures].each do |procedure|
              if procedure['procedure_name'].present?
                p_name = procedure['procedure_name'].titleize
                procedure_name += "#{p_name}, "
              end
              if procedure['procedure_side'].present?
                p_code = procedure['procedure_side'].titleize
                procedure_code += "#{p_code}, "
              end
              procedures += "<li>#{p_name}, #{p_code}</li>" if p_name.present? && p_code.present?
            end
          end
          procedures = '--' unless procedures.present?
          procedure_name = procedure_name.present? ? procedure_name.chomp(', ') : '--'
          procedure_code = procedure_code.present? ? procedure_code.chomp(', ') : '--'
          if @request == 'xlsx'
            age = age.present? ? age.to_i : '--'
            city = city.present? ? city : '--'
            state = state.present? ? state : '--'
            district = district.present? ? district : '--'
            commune = commune.present? ? commune : '--'
            pincode = pincode.present? ? pincode : '--'
            patient_mr_no = patient_mr_no.present? ? patient_mr_no : '--'
            role_tat = list[:patient_role_wise_tat_secs] || {}
            @data_array << [date, name&.titleize, phone, age, gender, area, city, state, district,
                            commune, pincode, patient_id, patient_mr_no, appointment_id, 
                            to_mins(role_tat[:receptionist]), to_mins(role_tat[:optometrist]),
                            to_mins(role_tat[:doctor]), to_mins(role_tat[:counsellor]), 
                            to_mins(role_tat[:tpa]), to_mins(role_tat[:cashier]),
                            to_mins(role_tat[:ar_nct]), to_mins(role_tat[:nurse]), 
                            to_mins(role_tat[:floormanager]), to_mins(role_tat[:pharmacist]), 
                            to_mins(role_tat[:optician]), to_mins(role_tat[:technician]),
                            to_mins(role_tat[:ophthalmology_technician]), 
                            to_mins(role_tat[:radiologist]), 
                            " #{total_time_mins}", total_time]
          else
            patient_details = "<b> #{name&.titleize} </b>" + '<br>' + phone + '<br>'  + age.to_s + '<br>' + Mis::Constants::Badge.gender_type(gender)
            patient_details = "<span class='style=text-align: justify'>"+patient_details+"</span>"
            role_tat = list[:patient_role_wise_tat_secs] || {}
            @data_array << [date, patient_details, patient_id, patient_mr_no, area, 
                            location, appointment_id,to_mins(role_tat[:receptionist]), 
                            to_mins(role_tat[:optometrist]), to_mins(role_tat[:doctor]), 
                            to_mins(role_tat[:counsellor]), to_mins(role_tat[:tpa]), 
                            to_mins(role_tat[:cashier]), to_mins(role_tat[:ar_nct]), 
                            to_mins(role_tat[:nurse]), to_mins(role_tat[:floormanager]), 
                            to_mins(role_tat[:pharmacist]), to_mins(role_tat[:optician]), 
                            to_mins(role_tat[:technician]), 
                            to_mins(role_tat[:ophthalmology_technician]), 
                            to_mins(role_tat[:radiologist]), total_time ]
          end
        end
      end
      def appointment_list_query
        Mis::ClinicalService::PatientQueryBuilder.call(@mis_params, @request)
      end

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

      def convert_date(datetime)
        Time.zone.parse(datetime.to_s).to_s(:hg_history_date_time)
      end
      # EOF convert_date

      def format_tat(tat)
        if tat.present? && tat != '-'
          arr = tat.split(':')
          return "#{arr[0]} H #{arr[1]} M"
        else
          return '-'
        end
      end

      def to_mins(secs)
        mins = (secs.to_f / 60).round() || 0
        mins > 0 ? mins : '-'
      end
    end
  end
end
