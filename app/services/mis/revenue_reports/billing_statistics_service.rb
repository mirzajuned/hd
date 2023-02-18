# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
module Mis::RevenueReports
  class BillingStatisticsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        invoices = Finance::StatisticData.collection.aggregate(statistic_query).to_a || {}
        @invoices = if @request == 'xls'
            invoices || []
          else
            invoices[0][:data] || []
          end

        total_records = if invoices.present? && @request == 'xls'
            invoices[0][:total] || 0
          elsif invoices.present? && invoices[0][:metadata].present?
            invoices[0][:metadata][0][:total]
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
          receipt_date = invoice[:_id].to_s(:hg_date_format)
          invoices = invoice['data']

          invoices.sort_by{ |inv| inv['department_order'] }.group_by{ |inv| inv['department_name'] }.each do |department_name, inv|
            inv.each do |invce|
              @data_array << generate_table_data(invce, receipt_date, department_name)
              receipt_date = ''
            end
          end
        end
      end
      # EOF invoice_data

      def statistic_query
        # Finance::StatisticData Query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF invoice_query

      def generate_table_data(invoice, receipt_date, department_name)
        forward_params_without_department = forward_params(invoice['facility_id'], invoice['receipt_date'])

        forward_params_without_bill_type = forward_params(
          invoice['facility_id'], invoice['receipt_date'], invoice['department_id']
        )
        forward_params_with_cash = forward_params(
          invoice['facility_id'], invoice['receipt_date'], invoice['department_id'], 'cash'
        )
        forward_params_with_credit = forward_params(
          invoice['facility_id'], invoice['receipt_date'], invoice['department_id'], 'credit'
        )

        href_without_department = @mis_params[:url] + forward_params_without_department + back_params
        href_without_bill_type = @mis_params[:url] + forward_params_without_bill_type + back_params
        href_with_cash = @mis_params[:url] + forward_params_with_cash + back_params
        href_with_credit = @mis_params[:url] + forward_params_with_credit + back_params

        total_no_of_bills = invoice['total_bill_count']
        cash_no_of_bills = invoice['cash_bill_count']
        credit_no_of_bills = invoice['credit_bill_count']

        cash_collection = (invoice['cash_bill_amount'].present?) ? invoice['cash_bill_amount'].round(2) : 0.00
        credit_colloection = (invoice['credit_bill_amount'].present?) ? invoice['credit_bill_amount'].round(2) : 0.00
        total_bill_amount = (invoice['total_bill_amount'].present?) ? invoice['total_bill_amount'].round(2) : 0.00

        cash_refund_bill_amount = (invoice['cash_refund_bill_amount'].present?) ? invoice['cash_refund_bill_amount'].round(2) : 0.00
        credit_refund_bill_amount = (invoice['credit_refund_bill_amount'].present?) ? invoice['credit_refund_bill_amount'].round(2) : 0.00
        refund_bill_amount = cash_refund_bill_amount + credit_refund_bill_amount

        total_bill_discount = (invoice['total_bill_discount'].present?) ? invoice['total_bill_discount'].round(2) : 0.00
        cash_bill_discount = (invoice['cash_bill_discount'].present?) ? invoice['cash_bill_discount'].round(2) : 0.00
        credit_bill_discount = (invoice['credit_bill_discount'].present?) ? invoice['credit_bill_discount'].round(2) : 0.00

        total_bill_offer = (invoice['total_bill_offer'].present?) ? invoice['total_bill_offer'].round(2) : 0.00
        cash_bill_offer = (invoice['cash_bill_offer'].present?) ? invoice['cash_bill_offer'].round(2) : 0.00
        credit_bill_offer = (invoice['credit_bill_offer'].present?) ? invoice['credit_bill_offer'].round(2) : 0.00

        gross_amount = ((total_bill_amount + total_bill_discount + total_bill_offer) - refund_bill_amount).round(2)
        
        credit_pending_amount = (invoice['credit_pending_amount'].present?) ? invoice['credit_pending_amount'].round(2) : 0.00
        
        if @request == 'json'
          receipt_date = "<a href='#{href_without_department}' "\
          "data-remote='true'>#{receipt_date}</a>"
          department_name = "<a href='#{href_without_bill_type}' "\
          "data-remote='true'>#{department_name}</a>"
          cash_no_of_bills = "<a href='#{href_with_cash}' "\
          "data-remote='true'>#{cash_no_of_bills}</a>" if cash_no_of_bills > 0
          credit_no_of_bills = "<a href='#{href_with_credit}' "\
          "data-remote='true'>#{credit_no_of_bills}</a>" if credit_no_of_bills > 0
        end

        t_data = [
          receipt_date, department_name, total_no_of_bills, gross_amount, total_bill_amount, 
          refund_bill_amount, total_bill_offer, total_bill_discount, cash_no_of_bills, cash_collection, 
          cash_refund_bill_amount, cash_bill_offer, cash_bill_discount, credit_no_of_bills,
          credit_colloection, credit_refund_bill_amount, credit_bill_offer, credit_bill_discount, credit_pending_amount
        ]

        t_data
      end
      # EOF generate_table_data

      def forward_params(facility_id, receipt_date, department_id = nil, bill_type = nil)
        department_id_filter = ''
        department_id_filter = department_id if department_id.present?
        bill_type_filter = if bill_type.present?
                             bill_type
                           else
                             @mis_params[:bill_type]
                           end
        params_str = "&start_date=#{receipt_date}"
        params_str += "&end_date=#{receipt_date}"
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
