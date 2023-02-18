# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Mis::RevenueReports
  class ReceiptSummaryByUserService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        invoices = Finance::CollectionTransactionData.collection.aggregate(invoice_query).to_a[0] || {}
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
          @data_array << generate_table_data(invoice)
        end
      end
      # EOF invoice_data

      def invoice_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF invoice_query

      def generate_table_data(invoice)
        receipt_type = invoice[:receipt_type]
        invoice_patient = invoice[:patient_display_fields]
        invoice_user = invoice[:user_display_fields]
        receipt_data = invoice[:receipt_display_fields]
        current_time(receipt_data['facility_timezone'])
        bill_date = convert_date(invoice[:receipt_time])
        bill_no = if invoice[:is_advance] == true || invoice[:is_refund] == true
                    receipt_data['receipt_no']
                  else
                    receipt_data['bill_no']
                  end
        mode_of_payment = receipt_data['mode_of_payment']
        comments = if receipt_data['comments'].present?
                      receipt_data['comments'].titleize
                   else
                      '-'
                   end
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

        user_name = if invoice_user['name'].present?
                      invoice_user['name'].titleize
                    else
                      '-'
                    end
        user_designation = if invoice_user['designation'].present?
                             invoice_user['designation']
                           else
                             '-'
                           end

        if @request == 'json'
          if invoice[:is_advance] == true
            bill_no = "<a href='/invoice/advance_payments/#{invoice[:receipt_id]}?reports=true' "\
                      "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          elsif receipt_data['type'].in?(['ipd', 'opd'])
            bill_no = "<a href='/invoice/#{receipt_data['type']}/#{invoice[:invoice_id]}?reports=true' "\
            "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          elsif invoice['is_refund'] == true
            bill_no = "<a href='/invoice/refund_payments/#{invoice[:receipt_id]}?reports=true' "\
            "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          else
            bill_no = "<a href='/invoice/inventory_invoices/show_modal?id="\
            "#{invoice[:invoice_id]}&reports=true' data-remote='true' "\
            "data-toggle='modal' data-target='#invoice-modal'>#{bill_no}</a>"
          end
          bill_details = "<b>#{bill_no}</b><br>#{bill_date}"
          receipt_type = "<span class='badge #{receipt_type.downcase}'>#{receipt_type}</span>"
          mode_of_payment = "<span class='badge #{mode_of_payment.downcase}'>#{mode_of_payment}</span>"
          patient_details = "<b>#{patient_name}</b><br>#{patient_age}<br>"\
          "#{patient_gender}<br>#{patient_identifier_id}<br>#{patient_mrn}"
          user_details = "<b><font class='text-green'>#{user_name}</font></b><br>#{user_designation}<br>#{bill_date}"
          t_data = [user_details, receipt_data['department_name'], patient_details, area,
                    location, receipt_type, bill_details, mode_of_payment, comments, 
                    receipt_data['receipt_amount']]
        else
          t_data = [user_name, user_designation, receipt_data['department_name'], patient_name, 
                    patient_age, patient_gender, patient_identifier_id, patient_mrn, area, city,
                    state, district, commune, pincode, receipt_type, bill_no, bill_date, 
                    mode_of_payment, comments, receipt_data['receipt_amount']]
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
