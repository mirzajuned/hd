module Mis::RevenueReports
  class ServiceSummaryService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []
        @country_id = Facility.find_by(id: @mis_params[:facility_id]).country_id rescue 'IN_108'
        services = Finance::InvoiceServiceSummary.collection.aggregate(service_query).to_a[0] || {}
        @services = services[:data] || []
        total_records = if @request == 'xls'
                          services[:total] || 0
                        elsif services[:metadata].present?
                          services[:metadata][0][:total]
                        else
                          0
                        end
        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'
        service_data

        [@data_array, total_records]
      end
      # EOF call

      private

      def service_data
        @services.try(:each) do |service|
          # Table Data
          @data_array << generate_table_data(service)
        end
      end
      # EOF invoice_data

      def service_query
        Mis::ServiceQueryBuilderService.call(@mis_params, @request)
      end
      # EOF service_query

      def generate_table_data(service)
        invoice_data = service[:invoice_display_fields]
        payer_data = service[:payer_display_fields]
        patient_data = service[:patient_display_fields]
        added_by_data = service[:added_by_display_fields]

        service_name = (service['service_name'].present?) ? service['service_name'] : '-'
        service_created = convert_date(service['service_entry_datetime'])
        invoice_number = invoice_data['bill_number']

        patient_name = (patient_data['fullname'].present?) ? patient_data['fullname'].titleize : '-'
        patient_age = (patient_data['age'].present?) ? patient_data['age'] : '-'
        patient_gender = (patient_data['gender'].present?) ? patient_data['gender'] : '-'
        patient_display_id = (patient_data['patient_identifier_id'].present?) ? patient_data['patient_identifier_id'] : '-'
        patient_mrn = (patient_data['patient_mrn'].present?) ? patient_data['patient_mrn'] : '-'

        addedby_name = (added_by_data['fullname'].present?) ? added_by_data['fullname'].titleize : '-'
        addedby_roles = added_by_data['roles'].count > 0 ? (added_by_data['roles'].pluck(:label).join(', ')) : '-'
        addedby_time = convert_date(service['service_entry_datetime'])

        discount_type = service['discount_type']
        sub_specialty_name = (service['sub_specialty_name'].present?) ? service['sub_specialty_name'] : '-'
        discount_percentage = (service['percentage_off'].present?) ? service['percentage_off'].round(2) : 'NA'
        i_type = if invoice_data['bill_type'].present?
                  invoice_data['bill_type'].titleize
                else
                  '-'
                end
        payer_details = if payer_data.present?
                          payer_data['payer_name'].titleize
                        else
                          '-'
                        end
        invoice_created = convert_date(invoice_data['created_at'])
        area = patient_data['area_manager_name'].present? ? patient_data['area_manager_name'] : '-'
        address_1 = (patient_data['address_1']. present?) ? patient_data['address_1'] : ''
        address_2 = (patient_data['address_2']. present?) ? patient_data['address_2'] : ''
        city = (patient_data['city']. present? && patient_data['city'] != 'null') ? patient_data['city'] : ''
        district = (patient_data['district'].present? && patient_data['district'] != 'null') ? patient_data['district'] : ''
        state = (patient_data['state'].present? && patient_data['state'] != 'null') ? patient_data['state'] : ''
        commune = patient_data['commune']
        pincode = (patient_data['pincode'].present? && patient_data['pincode'] != 0) ? patient_data['pincode'].to_s : ''
        location = display_location(address_1, address_2, city, state, commune, district, pincode)
        if @request == 'json'
          service_details = "<b>#{service_name}</b><br>#{service_created}"
          patient_details = "<b>#{patient_name}</b><br>#{patient_age}<br>#{patient_gender}<br>#{patient_display_id}<br>#{patient_mrn}"
          addedby_details = "<b>#{addedby_name}</b><br>#{addedby_roles}<br>#{addedby_time}"
          discount_type = "<span class='badge #{discount_type}'>#{discount_type.try(:titlecase)}</span>"
          if service['department_id'].in?([485396012, 486546481])
            bill_no = "<a href='/invoice/#{invoice_data['type']}/#{service[:invoice_id]}?reports=true' "\
            "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{invoice_number}</a>"
          else
            bill_no = "<a href='/invoice/inventory_invoices/show_modal?id="\
            "#{service[:invoice_id]}&reports=true' data-remote='true' "\
            "data-toggle='modal' data-target='#invoice-modal'>#{invoice_number}</a>"
          end
          bill_details = "<b>#{bill_no}</b><br>#{invoice_created}"
          i_type = "<span class='badge #{invoice_data['bill_type']}'>#{i_type}</span>"
          t_data = [service_details, bill_details, i_type, payer_details, sub_specialty_name, 
                    service['department_name'], service['service_unit_price'], 
                    service['invoice_unit_price'], service['unit_cost_difference'], service['offer_code'], service['offer_amount'], 
                    service['discount_amount'], service['net_item_price'], discount_percentage, 
                    discount_type, patient_details, area, location, addedby_details]
        else
          loc2 = (@country_id == 'VN_254') ? commune : state
          loc3 = (@country_id == 'VN_254') ? district : pincode
          t_data = [service_name, service_created, invoice_number, invoice_created, 
                    i_type, payer_details, sub_specialty_name, service['department_name'], 
                    service['service_unit_price'], service['invoice_unit_price'], 
                    service['unit_cost_difference'], service['offer_code'], service['offer_amount'], service['discount_amount'], 
                    service['net_item_price'], discount_percentage, 
                    discount_type.try(:titlecase), patient_name, 
                    patient_age, patient_gender, patient_display_id, patient_mrn, area, address_1, 
                    address_2, city, loc2, loc3, addedby_name, addedby_roles, addedby_time]
        end

        table_date = t_data.flatten
        table_date
      end
      # EOF generate_table_data

      def current_time(facility_timezone)
        Time.zone = facility_timezone
      end
      # EOF current_time

      def convert_date(datetime)
        Time.zone.parse(datetime.to_s).to_s(:hg_history_date_time)
      end
      # EOF convert_date

      def display_location(address_1, address_2, city, state, commune, district, pincode)
        location = ''
        location += address_1 if city.present?
        location += "<br>" + address_2 if city.present?
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
