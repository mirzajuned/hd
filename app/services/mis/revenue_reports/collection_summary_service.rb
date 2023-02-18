# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Mis::RevenueReports
  class CollectionSummaryService
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
          receipt_date = invoice['_id'].to_s(:hg_date_format)
          invoices = invoice['data']

          invoices.sort_by{ |inv| inv['department_order'] }.group_by { |inv| inv['department_name'] }.each do |department_name, inv|
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
        data_receipt_date = invoice['receipt_date'].strftime('%Y/%m/%d')
        forward_params_without_department = forward_params(invoice['facility_id'], data_receipt_date)
        forward_params_without_bill_type = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['department_id']
        )

        forward_params_advance = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['department_id'], 'advance_receipts'
        )

        forward_params_with_bill_type = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['department_id'], 'billing_summary', 'credit'
        )

        href_without_department = @mis_params[:url] + forward_params_without_department + back_params
        href_without_bill_type = @mis_params[:url] + forward_params_without_bill_type + back_params
        href_for_advance = @mis_params[:url] + forward_params_advance + back_params
        href_with_bill_type = @mis_params[:url] + forward_params_with_bill_type + back_params
        
        collection_total = invoice['collection_total'].round(2)
        receivable_total = invoice['receivable_total'].round(2)
        refund_total = invoice['refund_total'].round(2)
        final_collection = ((collection_total + receivable_total) - refund_total).round(2)

        cashsale_amount = invoice['cashsale_amount'].round(2)
        advance_amount = invoice['advance_amount'].round(2)

        creditsale_settle = invoice['creditsale_settle'].round(2)

        receivable_self_amount = invoice['receivable_self_amount'].round(2)
        receivable_other_amount = invoice['receivable_other_amount'].round(2)
        refund_cashsale_amount = invoice['refund_cashsale_amount'].round(2)
        refund_creditsale_amount = invoice['refund_creditsale_amount'].round(2)
        refund_advance_amount = invoice['refund_advance_amount']&.round(2) || 0.0

        if @request == 'json'
          receipt_date = "<a href='#{href_without_department}' "\
          "data-remote='true'>#{receipt_date}</a>"
          department_name = "<a href='#{href_without_bill_type}' "\
          "data-remote='true'>#{department_name}</a>"
          advance_amount = "<a href='#{href_for_advance}' "\
          "data-remote='true'>#{advance_amount}</a>" if advance_amount > 0
        end

        t_data = [
          receipt_date, department_name, final_collection, cashsale_amount, advance_amount, creditsale_settle,
          collection_total, receivable_self_amount, receivable_other_amount, receivable_total,
          refund_cashsale_amount, refund_creditsale_amount, refund_advance_amount, refund_total
        ]
        t_data
      end
      # EOF generate_table_data

      def forward_params(facility_id, receipt_date, department_id = nil, title='billing_summary', bill_type = nil)
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
        params_str += "&title=#{title}"
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
