# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Mis::RevenueReports
  class OpticalConversionSummaryService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        patient_presciptions = Inventory::StoreConversion.collection.aggregate(patient_presciption_query).to_a[0] || {}
        @patient_presciptions = patient_presciptions[:data] || []

        total_records = if @request == 'xls'
                          patient_presciptions[:total] || 0
                        elsif patient_presciptions[:metadata].present?
                          patient_presciptions[:metadata][0][:total]
                        else
                          0
                        end

        patient_presciptions_data

        [@data_array, total_records]
      end
      # EOF call

      private

      def patient_presciptions_data
        @patient_presciptions.try(:each) do |patient_presciption|
          # Table Data
          @data_array << generate_table_data(patient_presciption)
        end
      end
      # EOF patient_presciptions_data

      def patient_presciption_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF patient_presciption_query

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def generate_table_data(patient_presciption)
        # current_time(patient_presciption[:facility_timezone])
        advised_on = convert_date(patient_presciption[:advised_on_datetime])
        conversion_status = Inventory::StoreConversion.converted(patient_presciption[:is_converted])
        patient = patient_presciption[:patient_details]
        advised_by = patient_presciption[:advised_by_details]
        converted_by = patient_presciption[:converted_by_details]
        invoice_details = patient_presciption[:invoice_details]
        store_comment = patient_presciption['not_converted_to_converted'] ? '' : patient_presciption[:store_comment]
        patient_id = patient['identifier_id'] || '-'
        patient_mrn = patient['mrn'] || '-'
        patient_name = patient['name'].titleize || '-'
        patient_age = patient['exact_age'] || '-'
        patient_age_year_only = patient['age'] || '-'
        patient_gender = patient['gender'] || '-'
        patient_mobilenumber = patient['mobilenumber'] || '-'
        area = patient['area_manager_name'].present? ? patient['area_manager_name'] : '-'
        address_1 = patient['address_1']
        address_2 = patient['address_2']
        commune = patient['commune']
        city = patient['city']
        district = patient['district']
        state = patient['state']
        pincode = patient['pincode'].to_s
        patient_address = display_location(address_1, address_2, city, state, commune, district, pincode)
        patient_name_details = "#{patient_id}<br>#{patient_mrn}<br>#{patient_name}<br>#{patient_age}<br>#{patient_gender}<br>#{patient_mobilenumber}"
        conversion_remark = patient_presciption['not_converted_to_converted'] ? 'Earlier Marked as Not Converted' : ''

        advised_by_name = advised_by['name'].titleize rescue '-'
        advised_by_details = "#{advised_by_name}"

        converted_by_name = converted_by['name'].titleize rescue '-'
        converted_on = if patient_presciption[:converted_on_datetime].present?
                          if patient_presciption[:converted_on_datetime].try(:hour) != 0
                            convert_date(patient_presciption[:converted_on_datetime])
                          elsif patient_presciption[:converted_on_datetime].try(:hour) == 0 && patient_presciption[:invoice_details].present?
                            convert_date(patient_presciption[:invoice_details]['bill_date'])
                          else
                            convert_date_only(patient_presciption[:converted_on_datetime])
                          end
                       else
                        '-'
                       end
        converted_at = (patient_presciption[:converted_at_store_name].present?) ? patient_presciption[:converted_at_store_name] : '-'
        converted_by_details = "#{converted_by_name}<br>#{converted_on}<br>#{converted_at}"

        bill_date = (invoice_details['bill_date'].present?) ? convert_date(invoice_details['bill_date']) : '-'

        is_cancelled = invoice_details['is_cancelled'].present?
        is_refunded = (is_cancelled == true) ? false : (invoice_details['is_refunded'].present?)
        
        reason = bill_status = 'NA'

        if patient_presciption[:is_converted] == true
          if is_refunded == true && is_cancelled == false
            bill_status = 'Refunded'
            reason = invoice_details['refund_reason'] || '-'
          elsif is_cancelled == true
            bill_status = 'Cancelled'
            reason = invoice_details['refund_reason'] || '-'
          else
            bill_status = 'Billed'
          end
        end
        
        bill_no = (invoice_details['bill_no'].present?) ? invoice_details['bill_no'] : '-'
        discount = (invoice_details['additional_discount'].present?) ? invoice_details['additional_discount'] : '-'
        total_offer = (invoice_details['total_offer'].present?) ? invoice_details['total_offer'] : '-'
        invoice_total = (invoice_details['total'].present?) ? invoice_details['total'] : '-'
        invoice_tax = (invoice_details['tax'].present?) ? invoice_details['tax'] : '-'
        invoice_gross = (invoice_details['gross_amount'].present?) ? invoice_details['gross_amount'] : '-'
        payment_received = '-'

        conversion_in_days = (patient_presciption['conversion_time_days'].present?) ? patient_presciption['conversion_time_days'] : '-'

        if invoice_gross.present?
          advance_payment = (invoice_details['advance_payment'].present?) ? invoice_details['advance_payment'] : 0
          invoice_payment_received = (invoice_details['payment_received'].present?) ? invoice_details['payment_received'] : 0
          payment_received = if invoice_payment_received > 0
                                invoice_payment_received
                              elsif advance_payment > 0
                                advance_payment
                              else
                                0
                              end
              
        end
        current_state = (invoice_details['state'].present?) ? invoice_details['state'].titleize : '-'
        
        if @request == 'json'
          discount = "<font class='discount'>#{discount}</font>" if discount != '-' && discount > 0
          total_offer = "<font class='discount'>#{total_offer}</font>" if total_offer != '-' && total_offer > 0
          conversion_status = "<span class='badge #{conversion_status.parameterize.underscore}'>#{conversion_status}</span>"
          if patient_presciption['not_converted_to_converted']
            conversion_status += '</br><strong style="font-size: 12px; font-style: italic;">Earlier Marked as Not Converted</strong>'
          end
          bill_status = "<span class='badge billed-#{bill_status.parameterize}'>#{bill_status}</span>"
          current_state = "<span class='badge #{current_state.downcase}'>#{current_state}</span>" unless current_state == '-'
          if invoice_details['type'].in?(['ipd', 'opd'])
            bill_no = "<a href='/invoice/#{invoice_details['type']}/#{patient_presciption[:invoice_id]}?reports=true' "\
            "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          else
            bill_no = "<a href='/invoice/inventory_invoices/show_modal?id="\
            "#{patient_presciption[:invoice_id]}&reports=true' data-remote='true' "\
            "data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          end
          bill_details = "<b>#{bill_no}</b><br>#{bill_date}"
          t_data = [ 
            advised_on, conversion_status, store_comment, patient_name_details, area,
            patient_address, advised_by_details, converted_by_details, current_state, 
            bill_details, bill_status, invoice_total, discount, total_offer, invoice_tax, 
            invoice_gross, payment_received, conversion_in_days
           ]
        else
          t_data = [
            advised_on, conversion_status, conversion_remark, store_comment, patient_id, 
            patient_mrn, patient_name, patient_age_year_only, patient_gender,
            patient_mobilenumber, area, city, state, pincode, commune, district, advised_by_name,
            converted_by_name, converted_on, converted_at, current_state, bill_no, bill_status, 
            invoice_total, discount, total_offer, invoice_tax, invoice_gross, payment_received, 
            conversion_in_days
          ]
        end

        table_date = t_data.flatten
        table_date
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # EOF generate_table_data

      def current_time(facility_timezone)
        Time.zone = facility_timezone
      end
      # EOF current_time

      def convert_date(datetime)
        Time.zone.parse(datetime.to_s).to_s(:hg_history_date_time) if datetime.present?
        # datetime.to_s(:hg_history_date_time) if datetime.present?
      end
      # EOF convert_date

      def convert_date_only(datetime)
        Time.zone.parse(datetime.to_s).to_s(:hg_dmy_format) if datetime.present?
      end
      # EOF convert_date_only

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
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
