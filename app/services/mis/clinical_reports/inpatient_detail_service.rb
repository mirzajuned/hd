# rubocop:disable all
module Mis::ClinicalReports
  class InpatientDetailService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.inpatient_filters(@mis_params)
        end
        aggregation_query = admission_list_query
        admission_list = MisClinical::Ipd::ClinicalReportIpd.collection.aggregate(aggregation_query).to_a[0] || {}
        @patient_list = admission_list[:data] || []
        total_records =unless @request == 'json'
                         admission_list[:total] || 0
                       else
                         admission_list[:metadata].present? ? admission_list[:metadata][0][:total] : 0
                       end
        patient_wise_list
        [@data_array, total_records]
      end

      private

      def patient_wise_list
        @patient_list.each do |list|
          scheduled_date = list[:scheduled_date]&.strftime('%d/%m/%Y')
          # scheduled_date = list[:admission_date]&.strftime('%d/%m/%Y')
          # scheduled_time = list[:admission_time]&.in_time_zone&.strftime('%I:%M %p')
          # scheduled_date_time = "#{scheduled_date}-#{scheduled_time}"
          admission_date = list[:admission_date]&.strftime('%d/%m/%Y')
          current_state = list[:current_state]
          admission_time = list[:admission_time]&.in_time_zone&.strftime('%I:%M %p')
          admission_date_time = "#{admission_date}-#{admission_time}"

          name = list[:patient_details][:patient_name]&.titleize|| '--'
          phone = list[:patient_details][:patient_mobilenumber] || '--'
          age = list[:patient_details][:patient_age] || '--'
          gender = list[:patient_details][:patient_gender] || '--'
          pincode = list[:patient_details][:pincode].present? ? list[:patient_details][:pincode] : ''
          area = list[:patient_details][:area_manager_name].present? ? list[:patient_details][:area_manager_name] : '-'
          city = list[:patient_details][:city].present? ? list[:patient_details][:city] : '-'
          state = list[:patient_details][:state].present? ? list[:patient_details][:state] : '-'
          district = list[:patient_details][:district].present? ? list[:patient_details][:district] : '-'
          commune = list[:patient_details][:commune].present? ? list[:patient_details][:commune] : '-'
          country_id = Facility.find_by(id: @mis_params[:facility_id]).country_id if @mis_params[:facility_id].present?
          location = display_location(city, state, commune, district, pincode)
          patient_id = list[:patient_details][:patient_display_id]
          patient_mr_no = list[:patient_details][:patient_mr_no]

          pre_op_diagnosis = list[:diagnoses].present? ? pre_op_diagnosis(list[:diagnoses]) : []
          admission_id = list[:admission_id]
          admission_display_id = list[:admission_display_id]
          admission_type = list[:admission_type]
          moh = list[:mode_of_hospitalization]
          insurance_details = ''
          if moh == 'Insured'
            insurance_details += "Insurance Person: #{list[:insurance_details][:insurance_contact_person] },</br>"
            insurance_details += "<b>Insurance Name: #{list[:insurance_details][:insurance_name] }<b>,</br>"
            insurance_details += "TPA-#{ Contact.find_by(id: list[:insurance_details][:tpa_contact_id])&.display_name },</br>"
          end
          insurance_details = "<span class='left-align' style='font-size: 12px;'> #{insurance_details}</span>"
          admitting_surgeon = list[:admitting_doctor]
          prc =  list[:procedures]
          surgery_details =  prc.present? ? surgery_details(prc) : '--'

          discharge_date_time = "#{list[:discharge_date]&.strftime('%d/%m/%Y')}-#{list[:discharge_time]&.in_time_zone&.strftime('%I:%M %p')}"
          ipd_notes ="<a href='/inpatient/ipd_records/show_all_notes?admission_id=#{admission_id.to_s}&patient_id=#{list[:patient_id].to_s}' "\
          "data-remote='true' data-toggle='modal' data-target='#templates-modal'>View</a>"
          ipd_notes = "" if current_state == 'Cancelled' || current_state == 'Deleted'

          opd_otes =  "<a href='/consolidate_reports/index?patient_id=#{list[:patient_id].to_s}&specialty_id=#{list[:specialty_id].to_s}' "\
          "data-remote='true' data-toggle='modal' data-target='#templates-modal'>View</a>"
          opd_otes = '' if current_state == 'Cancelled' || current_state == 'Deleted'

          complications = list[:intra_op_comlications][:complications]&.map{|arr| "#{arr}"}&.join(',<br>')
          comments = list[:intra_op_comlications][:comments]&.map {|ar| ar&.join(': ')}&.join('<br>')
          common_comment = trancate(list[:intra_op_comlications][:complication_comment])
          procedure_comment = "<strong>Comment:</strong><br>#{trancate(comments)}" if comments.present?
          intra_op_complications = "#{complications} <br>#{procedure_comment}<br>#{common_comment}"


          unless @request == 'json'
            age = list[:patient_details][:age]
            intra_op_complications = ActionView::Base.full_sanitizer.sanitize(intra_op_complications&.gsub("<br>", "\n"))
            insurance_details = ActionView::Base.full_sanitizer.sanitize(insurance_details&.gsub("<br>", "\n"))
            procedure, advised_by, advised_on, performed_by, operated_on  = surgery_for_download(prc) if prc.present?
            procedure = procedure.present? ? procedure&.join(",\n") : ''
            advised_by = advised_by.present? ?  advised_by&.join(",\n") : ''
            advised_on = advised_on.present? ?  advised_on&.join(",\n") : ''
            performed_by = performed_by.present? ? performed_by&.join(",\n") : ''
            operated_on = operated_on.present? ? operated_on&.join(",\n") : ''
            loc2 = country_id == 'VN_254' ? commune : state
            loc3 = country_id == 'VN_254' ? district : pincode
            # scheduled_date_time = "--" unless current_state == 'Admitted' || current_state == 'Discharged'
            admission_date_time = "--" unless current_state == 'Admitted' || current_state == 'Discharged'
            discharge_date_time = "--" unless current_state == 'Discharged'
            # scheduled_date_time
            @data_array << [scheduled_date, admission_date_time, discharge_date_time, current_state,
                            name.titleize, phone, age, gender, patient_id, patient_mr_no, area, 
                            city, loc2, loc3, pre_op_diagnosis&.join(''), admission_display_id, 
                            admission_type&.titleize, moh, insurance_details, admitting_surgeon, 
                            procedure, advised_by, advised_on, performed_by , operated_on,
                            intra_op_complications]
          else
            admission_type = Mis::Constants::Badge.admission_type(admission_type)
            moh = Mis::Constants::Badge.moh(list[:mode_of_hospitalization])
            patient_details = "<b> #{name.titleize} </b>" + '<br>' + phone + '<br>'  + age + '<br>' +
              Mis::Constants::Badge.gender_type(gender)
            patient_details = "<span class='style=text-align: justify'>" + patient_details  + "</span>"
            dates = format_dates(scheduled_date, admission_date_time, discharge_date_time , current_state) #scheduled_date_time
            current_state = Mis::Constants::Badge.current_state(current_state)
            pre_op_diagnosis = pre_op_diagnosis.each_with_index.map{ |val| "<li> #{val.titleize}</li>"}&.join('')

            @data_array << [dates, current_state, patient_details, patient_id, patient_mr_no, area,
                            location, pre_op_diagnosis, admission_display_id, admission_type, moh, 
                            insurance_details, admitting_surgeon, surgery_details, 
                            intra_op_complications, ipd_notes, opd_otes]
          end

        end
      end

      def admission_list_query
        Mis::ClinicalService::InpatientQueryBuilder.call(@mis_params, @request)
      end

      def pre_op_diagnosis(list)
        list = list.select{ |n| n[:is_disabled] ==  false }
        list&.map {|l| "#{l[:diagnosisname].capitalize}" + "(" + "#{l[:icddiagnosiscode].upcase.insert(3, '.')}" + ")"}

      end

      def surgery_details(procedures)
        arr = []
        procedures.map do |surgery|
          arr << [surgery[:procedurename], surgery[:procedureside],surgery[:procedurestage], surgery[:advised_by],
                  surgery[:performed_by], surgery[:advised_datetime], surgery[:performed_datetime] ]
        end
        surgery_details = ''
        arr.each do |surgery|
          surgery_details += "<strong>#{surgery[0]} ,#{procedure_side(surgery[1])}</strong>,<br>"
          surgery_details += "<div class='badge badge-success'> #{surgery[2]}</div>,<br>" if surgery[2] == 'Performed'
          surgery_details += "<div class='badge badge-yellow'> #{surgery[2]}</div>,<br>" if surgery[2] == 'Advised'
          surgery_details += "<strong>Advised By</strong>: #{surgery[3]},<br>"
          surgery_details += "<strong>Performed By</strong>: #{surgery[4]},<br>" if surgery[2] == 'Performed'
          surgery_details += "<strong>Advised On</strong>: #{surgery[5]&.in_time_zone.strftime('%F,%I %p')}<br>"
          if surgery[2] == 'Performed'
            surgery_details += "<strong>Operated On</strong>: #{surgery[6]&.in_time_zone&.strftime('%F,%I %p')}<br><br>"
          end
        end
        surgery_details = "<span class='left-align' style='font-size: 12px;'> #{surgery_details}</span>"
      end

      def surgery_for_download(prc)
       procedure = prc.map {|pro| "#{pro[:procedurename]}, #{procedure_side(pro[:procedureside])}"}
       advised_by = prc.pluck(:advised_by)
       performed_by = prc.pluck(:performed_by)
       advised_on = prc.pluck(:advised_datetime).map{|val| val&.in_time_zone&.strftime('%F,%I %p')}
       operated_on = prc.pluck(:performed_datetime).map{|val| val&.in_time_zone&.strftime('%F,%I %p')}
        [ procedure, advised_by, advised_on, performed_by, operated_on ]
      end

      def trancate(string, length = 100)
        if string.present?
          string.size > length+5 ? [string[0,length],string[-5,5]].join("...") : string
        else
          ""
        end
      end

      def format_dates(scheduled_date, admission_date, discharge_date_time, current_state)
        date_string = "<strong>Scheduled Date:</strong> #{scheduled_date} <br>"
        if current_state == 'Admitted' || current_state == 'Discharged'
          date_string += "<strong>Admission Date & Time:</strong> #{admission_date}<br>"
        end
        date_string +=  "<strong>Discharged Date & Time:</strong> #{discharge_date_time}" if current_state == 'Discharged'
        date_string
      end

      def procedure_side(side)
        case side
          when '8966001'
            'L'
          when '18944008'
            'R'
          else
            'BE'
        end
      end
      # EOF procedure_side

      def display_location(city, state, commune, district, pincode)
        location = ''
        location += "<br>" + city if city.sub('-','')&.present?
        location += "<br>" + state if state.sub('-','')&.present?
        location += "<br>" + commune if commune.sub('-','')&.present?
        location += "<br>" + district if district.sub('-','')&.present?
        location += "<br>" + pincode if pincode.sub('-','')&.present?
        location.present? ? location.sub('<br>','') : '-'
      end
      # EOF display_location
    end
  end
end



