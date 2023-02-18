# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Mis::RevenueReports
  class CollectionByUserService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        invoices = Finance::StatisticCollectionTransactionData.collection.aggregate(statistic_query).to_a || {}
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

          mop_list = Mis::FinancialReportsHelper.mop_fields(@mis_params[:country_id])

          invoices.group_by { |inv| inv['user_name'] }.each do |user_name, user_invoices|
            user_name = user_name.titleize
            user_invoices.sort_by { |inv| inv['department_order'] }
                         .group_by { |inv| inv['department_name'] }.each do |department_name, inv|
              inv.each do |invce|
                @data_array << generate_table_data(invce, receipt_date, user_name, department_name, mop_list)
                receipt_date = department_name = user_name = ''
              end
            end
          end
        end
      end
      # EOF invoice_data

      def statistic_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF statistic_query

      def generate_table_data(invoice, receipt_date, user_name, department_name, mop_list)
        data_receipt_date = invoice['receipt_date'].strftime('%Y/%m/%d')
        forward_params_date = forward_params(invoice['facility_id'], data_receipt_date)
        forward_params_user = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['user_id']
        )
        forward_params_department = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['user_id'], invoice['department_id']
        )
        forward_params_advance = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['user_id'], invoice['department_id'],
          ['is_bill', 'is_refund']
        )
        forward_params_bill = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['user_id'], invoice['department_id'],
          ['is_advance', 'is_refund']
        )
        forward_params_refund = forward_params(
          invoice['facility_id'], data_receipt_date, invoice['user_id'], invoice['department_id'],
          ['is_advance', 'is_bill']
        )

        href_date = @mis_params[:url] + forward_params_date + back_params
        href_user = @mis_params[:url] + forward_params_user + back_params
        href_department = @mis_params[:url] + forward_params_department + back_params
        href_advance = @mis_params[:url] + forward_params_advance + back_params
        href_bill = @mis_params[:url] + forward_params_bill + back_params
        href_refund = @mis_params[:url] + forward_params_refund + back_params

        final_collection = invoice['net_collection']&.round(2)
        advance_receipts_count = invoice['advance_receipts_count']
        advance_receipts_amount = invoice['advance_receipts_amount']&.round(2)
        bills_count = invoice['bills_count']
        bills_amount = invoice['bills_amount']&.round(2)
        final_count = advance_receipts_count + bills_count
        final_amount = (advance_receipts_amount + bills_amount)&.round(2)
        refund_count = invoice['refund_advance_count'] + invoice['refund_bills_count']
        refund_bills_amount = (invoice['refund_advance_amount'] + invoice['refund_bills_amount'])&.round(2)

        advance_info = invoice['advance_info']
        bills_info = invoice['bills_info']
        advance_bills_refund_info = invoice['advance_bills_refund_info']

        if @request == 'json'
          receipt_date = "<a href='#{href_date}' data-remote='true'>#{receipt_date}</a>"
          user_name = "<a href='#{href_user}' data-remote='true'>#{user_name}</a>"
          department_name = "<a href='#{href_department}' data-remote='true'>#{department_name}</a>"
          final_collection = "<a href='/reports/collection_stats_mop?stats_id=#{invoice['_id']}&reports=true' "\
                      "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{final_collection}</a>"
          if advance_receipts_count > 0
            advance_receipts_count = "<a href='#{href_advance}' " \
            "data-remote='true'>#{advance_receipts_count}</a>"
          end
          if bills_count > 0
            bills_count = "<a href='#{href_bill}' data-remote='true'"\
            ">#{bills_count}</a>"
          end
          if refund_count > 0
            refund_count = "<a href='#{href_refund}' data-remote='true'"\
            ">#{refund_count}</a>"
          end
          t_data = [
            receipt_date, user_name, department_name, final_collection, advance_receipts_count, advance_receipts_amount,
            bills_count, bills_amount, final_count, final_amount, refund_count, refund_bills_amount
          ]
        else
          t_data = [receipt_date, user_name, department_name, final_collection]
          ['advance_receipts', 'bills', 'refund_advance_bills'].each do |bill_receipt|
            mop_list.each do |mop|
              t_data << invoice["#{bill_receipt}_#{mop}"]
            end
          end
        end
        t_data.flatten
      end
      # EOF generate_table_data

      def forward_params(facility_id, receipt_date, user_id = nil, department_id = nil, extra_conditions = [])
        department_id_filter = @mis_params[:department_id]
        department_id_filter = department_id if department_id.present?
        user_id_filter = @mis_params[:user_id]
        user_id_filter = user_id if user_id.present?
        params_str = "&start_date=#{receipt_date}"
        params_str += "&end_date=#{receipt_date}"
        params_str += "&time_period=#{@mis_params[:time_period]}"
        params_str += "&bill_type=#{@mis_params[:bill_type]}"
        params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
        params_str += "&facility_id=#{facility_id}"
        params_str += "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        params_str += "&department_id=#{department_id_filter}"
        params_str += "&user_id=#{user_id_filter}"
        params_str += '&group=finance'
        params_str += '&title=receipt_summary_by_user'
        params_str += '&has_params=true'
        if extra_conditions.present?
          extra_conditions.each do |key|
            params_str += "&#{key}=false"
          end
        end
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
