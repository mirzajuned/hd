# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
require 'csv'

module Mis::ClinicalReports
  class VisionImprovementService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        dummy_log = InvoiceLog.where(organisation_id: @mis_params[:organisation_id], facility_id: @mis_params[:facility_id]).last

        input_csv = File.read(Rails.root.join("public", "patient_outcomes", "vision_improvement.csv"))
        table = CSV.parse(input_csv, headers: true)
        table.each do |row|
          data_row = [row['DATE'], row['PAT_DETAILS'], row['PAT_ID'], row['MRN_NO'], row['ADMISSION_DATE'], row['DISCHARGE_DATE'],
                      row['SURGERY'], row['LAT'], row['PRE_VA'], row['PRE_BCVA'], row['PRE_DOC'], row['PRE_LOGMAR'], row['PRE_VAS'],
                      row['POST_12_VA'], row['POST_12_BCVA'], row['POST_12_DOC'], row['POST_12_LOGMAR'], row['POST_12_VAS'],
                      row['POST_57_VA'], row['POST_57_BCVA'], row['POST_57_DOC'], row['POST_57_LOGMAR'], row['POST_57_VAS'],
                      row['POST_2535_VA'], row['POST_2535_BCVA'], row['POST_2535_DOC'], row['POST_2535_LOGMAR'], row['POST_2535_VAS'],
                      row['POST_8595_VA'], row['POST_8595_BCVA'], row['POST_8595_DOC'], row['POST_8595_LOGMAR'], row['POST_8595_VAS'],
                      'This is log'
                      ]
          @data_array << data_row
        end
        total_records = @data_array.count
        [@data_array, total_records]
      end
      # EOF call

      private

      def invoice_data
        @invoices.try(:each) do |invoice|
          invoice_date = invoice[:_id].to_s(:hg_date_format)
          invoices = invoice['data']

          invoices.sort_by{ |inv| inv['department_order'] }.group_by{ |inv| inv['department_name'] }.each do |department_name, inv|
            inv.each do |invce|
              @data_array << generate_table_data(invce, invoice_date, department_name)
              invoice_date = ''
            end
          end
        end
      end
      # EOF invoice_data

      def statistic_query
        Mis::ClinicalService::VisionImprovementQueryBuilder.call(@mis_params, @request)
      end
      # EOF invoice_query

      def generate_table_data(invoice, invoice_date, department_name)
        forward_params_without_department = forward_params(invoice['facility_id'], invoice['invoice_date'])

        forward_params_without_bill_type = forward_params(
          invoice['facility_id'], invoice['invoice_date'], invoice['department_id']
        )
        forward_params_with_cash = forward_params(
          invoice['facility_id'], invoice['invoice_date'], invoice['department_id'], 'cash'
        )
        forward_params_with_credit = forward_params(
          invoice['facility_id'], invoice['invoice_date'], invoice['department_id'], 'credit'
        )

        href_without_department = @mis_params[:url] + forward_params_without_department + back_params
        href_without_bill_type = @mis_params[:url] + forward_params_without_bill_type + back_params
        href_with_cash = @mis_params[:url] + forward_params_with_cash + back_params
        href_with_credit = @mis_params[:url] + forward_params_with_credit + back_params

        total_no_of_bills = invoice['total_bill_count']
        cash_no_of_bills = invoice['cash_bill_count']
        credit_no_of_bills = invoice['credit_bill_count']

        cash_collection = invoice['cash_bill_amount'].round(2)
        credit_colloection = invoice['credit_bill_amount'].round(2)
        total_bill_amount = invoice['total_bill_amount'].round(2)

        total_bill_discount = invoice['total_bill_discount'].round(2)
        cash_bill_discount = invoice['cash_bill_discount'].round(2)
        credit_bill_discount = invoice['credit_bill_discount'].round(2)
        
        credit_pending_amount = invoice['credit_pending_amount'].round(2)
        
        if @request == 'json'
          invoice_date = "<a href='#{href_without_department}' "\
          "data-remote='true'>#{invoice_date}</a>"
          department_name = "<a href='#{href_without_bill_type}' "\
          "data-remote='true'>#{department_name}</a>"
          cash_no_of_bills = "<a href='#{href_with_cash}' "\
          "data-remote='true'>#{cash_no_of_bills}</a>" if cash_no_of_bills > 0
          credit_no_of_bills = "<a href='#{href_with_credit}' "\
          "data-remote='true'>#{credit_no_of_bills}</a>" if credit_no_of_bills > 0
        end

        t_data = [
          invoice_date, department_name, total_no_of_bills, total_bill_amount, total_bill_discount,
          cash_no_of_bills, cash_collection, cash_bill_discount, credit_no_of_bills,
          credit_colloection, credit_bill_discount, credit_pending_amount
        ]

        t_data
      end
      # EOF generate_table_data

      def forward_params(facility_id, invoice_date, department_id = nil, bill_type = nil)
        department_id_filter = ''
        department_id_filter = department_id if department_id.present?
        bill_type_filter = if bill_type.present?
                             bill_type
                           else
                             @mis_params[:bill_type]
                           end
        params_str = "&start_date=#{invoice_date}"
        params_str += "&end_date=#{invoice_date}"
        params_str += "&time_period=#{@mis_params[:time_period]}"
        params_str += "&bill_type=#{bill_type_filter}"
        params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
        params_str += "&facility_id=#{facility_id}"
        params_str += "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        params_str += "&department_id=#{department_id_filter}"
        params_str += '&group=finance'
        params_str += '&title=billing_summary'
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
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
