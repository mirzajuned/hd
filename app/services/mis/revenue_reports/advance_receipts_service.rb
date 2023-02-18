# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Mis::RevenueReports
  class AdvanceReceiptsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        invoices = Finance::ReportData.collection.aggregate(invoice_query).to_a[0] || {}
        @invoices = invoices[:data] || []

        total_records = if @request == 'xls'
            invoices[:total] || 0
          elsif invoices[:metadata].present?
            invoices[:metadata][0][:total]
          else
            0
          end
         
        invoice_data
        
        [@data_array, total_records]
      end
      # EOF call

      private

      def invoice_data
        @invoices.try(:each) do |invoice|
          # Table Data
          @data_array << generate_table_data(invoice)
        end
      end
      # EOF invoice_data

      def invoice_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF invoice_query

      def generate_table_data(invoice)
        invoice_patient = invoice[:patient_display_fields]
        invoice_user = invoice[:user_display_fields]
        invoice_data = invoice[:receipt_display_fields]
        current_time(invoice_data['facility_timezone'])
        bill_date = convert_date(invoice_data['bill_date_time'])
        bill_no = invoice_data['bill_no']

        is_cancelled = invoice_data['is_cancelled'].present?
        is_refunded = (is_cancelled == true) ? false : (invoice_data['is_refunded'].present?)
        
        reason = bill_status = '-'
        if is_refunded == true && is_cancelled == false
          bill_status = 'Refunded'
          reason = invoice_data['refund_reason'] || '-'
        elsif is_cancelled == true
          bill_status = 'Cancelled'
          reason = invoice_data['refund_reason'] || '-'
        end

        is_deleted = invoice_data['is_deleted'].in?([nil, false]) ? false : true
        
        patient_name = invoice_patient['patient_name'].titleize
        area = invoice_patient['area_manager_name'].present? ? invoice_patient['area_manager_name'] : '-'
        commune = (invoice_patient['commune'].present?) ? invoice_patient['commune'] : ''
        city = (invoice_patient['city']. present?) ? invoice_patient['city'] : ''
        district = (invoice_patient['district'].present?) ? invoice_patient['district'] : ''
        state = (invoice_patient['state'].present?) ? invoice_patient['state'] : ''
        pincode = if invoice_patient['pincode'].present? && invoice_patient['pincode'] != 0
                    invoice_patient['pincode'].to_s 
                  else
                    ''
                  end
        location = display_location(city, state, commune, district, pincode)
        patient_age = if invoice_patient['age'].present?
                        invoice_patient['age']
                      else
                        '-'
                      end
        patient_gender = if invoice_patient['gender'].present?
                          invoice_patient['gender']
                        else
                          '-'
                        end
        patient_identifier_id = if invoice_patient['patient_identifier_id'].present?
                                  invoice_patient['patient_identifier_id']
                                else
                                  '-'
                                end
        patient_mrn = if invoice_patient['patient_mrn'].present?
                        invoice_patient['patient_mrn']
                      else
                        '-'
                      end

        i_type = invoice_data['mode_of_payment'].titleize

        user_name = invoice_user['name'].titleize
        user_designation = if invoice_user['designation'].present?
                              invoice_user['designation']
                           else
                            '-'
                           end

        amount_received = invoice_data['amount'].to_i
        amount_remaining = invoice_data['amount_remaining'].to_i
        amount_settled = (amount_received - amount_remaining) rescue 0

        advance_state = Mis::FinancialReportsHelper.rename_advance_state(amount_settled, invoice_data['state'])

        receipt_reason = invoice_data['reason'].humanize

        if @request == 'json'
          bill_no = "<a href='/invoice/advance_payments/#{invoice[:invoice_id]}?reports=true' "\
                      "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          settled_class = if amount_settled == amount_received
            'text-green'
          elsif amount_settled > 0
            'discount'
          end
          i_type = "<span class='badge #{invoice_data['mode_of_payment']}'>#{i_type}</span>"
          user_details = "<b><font class='text-green'>#{user_name}</font></b><br>#{user_designation}<br>#{bill_date}"
          patient_details = "<b>#{patient_name}</b><br>#{patient_age}<br>#{patient_gender}<br>#{patient_identifier_id}<br>#{patient_mrn}"
          
          amount_settled = "<font class='#{settled_class}'>#{amount_settled}</font>"
          bill_details = "<b>#{bill_no}</b><br>#{bill_date}"
          table_date = [invoice_data['department_name'], bill_details, patient_details, area, 
                        location, i_type, advance_state, receipt_reason, amount_received, 
                        amount_settled, amount_remaining, user_details, bill_status, reason]
        else
          table_date = [invoice_data['department_name'], bill_no, bill_date, patient_name, 
                        patient_age, patient_gender, patient_identifier_id, patient_mrn, area, city,
                        state, district, commune, pincode, i_type, advance_state, receipt_reason, 
                        amount_received, amount_settled, amount_remaining, user_name, 
                        user_designation, bill_status, reason]
        end

        table_date
      end
      # EOF generate_table_data

      def current_time(facility_id_timezone, is_id=false)
        if is_id.present?
          facility_timezone = Facility.find_by(id: facility_id_timezone).try(:time_zone)
        else
          facility_timezone = facility_id_timezone
        end
        Time.zone = facility_timezone
      end
      # EOF current_time

      def convert_date(dateTime)
        Time.zone.parse(dateTime.to_s).to_s(:hg_history_date_time)
      end
      # EOF convert_date

      def display_location(city, state, commune, district, pincode)
        location = ''
        location += city.titleize if city.present?
        location += "<br>" + state.titleize if state.present?
        location += "<br>" + commune.titleize if commune.present?
        location += "<br>" + district.titleize if district.present?
        location += "<br>" + pincode if pincode.present?
        location.present? ? location.sub('<br>','') : '-'
      end
      # EOF display_location
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
