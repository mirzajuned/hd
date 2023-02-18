# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/BlockLength
module Mis::RevenueReports
  class BillsByPayerService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        invoices = Finance::StatisticPayer.collection.aggregate(statistic_query).to_a || {}
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

      def statistic_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF invoice_query

      def invoice_data
        t_day = DateTime.current
        @invoices.try(:each) do |invoice|
          p_name = invoice['_id'].titleize
          invoices = invoice['data']

          one_to_fifteen = previous_invoices(t_day, invoices, 0, 15)
          one_to_fifteen_no_of_bills = invoices_inject_and_sum(one_to_fifteen, 'total_no_of_bills')
          one_to_fifteen_revenue = invoices_inject_and_sum(one_to_fifteen, 'total_payment_received').round(2)
          one_to_fifteen_pending = invoices_inject_and_sum(one_to_fifteen, 'total_pending_amount').round(2)

          sixteen_to_thirty = previous_invoices(t_day, invoices, 16, 30)
          sixteen_to_thirty_no_of_bills = invoices_inject_and_sum(sixteen_to_thirty, 'total_no_of_bills')
          sixteen_to_thirty_revenue = invoices_inject_and_sum(sixteen_to_thirty, 'total_payment_received').round(2)
          sixteen_to_thirty_pending = invoices_inject_and_sum(sixteen_to_thirty, 'total_pending_amount').round(2)

          thirtyone_to_fourtyfive = previous_invoices(t_day, invoices, 31, 45)
          thirtyone_to_fourtyfive_no_of_bills = invoices_inject_and_sum(thirtyone_to_fourtyfive, 'total_no_of_bills')
          thirtyone_to_fourtyfive_revenue = invoices_inject_and_sum(thirtyone_to_fourtyfive, 'total_payment_received').round(2)
          thirtyone_to_fourtyfive_pending = invoices_inject_and_sum(thirtyone_to_fourtyfive, 'total_pending_amount').round(2)

          fourtysix_to_sixty = previous_invoices(t_day, invoices, 46, 60)
          fourtysix_to_sixty_no_of_bills = invoices_inject_and_sum(fourtysix_to_sixty, 'total_no_of_bills')
          fourtysix_to_sixty_revenue = invoices_inject_and_sum(fourtysix_to_sixty, 'total_payment_received').round(2)
          fourtysix_to_sixty_pending = invoices_inject_and_sum(fourtysix_to_sixty, 'total_pending_amount').round(2)

          above_sixty = previous_invoices(t_day, invoices, 61)
          above_sixty_no_of_bills = invoices_inject_and_sum(above_sixty, 'total_no_of_bills')
          above_sixty_revenue = invoices_inject_and_sum(above_sixty, 'total_payment_received').round(2)
          above_sixty_pending = invoices_inject_and_sum(above_sixty, 'total_pending_amount').round(2)

          total_no_of_bills = one_to_fifteen_no_of_bills + sixteen_to_thirty_no_of_bills +
                              thirtyone_to_fourtyfive_no_of_bills + fourtysix_to_sixty_no_of_bills +
                              above_sixty_no_of_bills
          total_revenue = one_to_fifteen_revenue + sixteen_to_thirty_revenue +
                          thirtyone_to_fourtyfive_revenue + fourtysix_to_sixty_revenue + above_sixty_revenue
          total_pending_amount = one_to_fifteen_pending + sixteen_to_thirty_pending +
                                 thirtyone_to_fourtyfive_pending + fourtysix_to_sixty_pending + above_sixty_pending

          href = @mis_params[:url] + forward_params(@mis_params[:facility_id]) + back_params

          @data_array << [
            p_name, total_no_of_bills, total_revenue, total_pending_amount,
            one_to_fifteen_no_of_bills, one_to_fifteen_pending, sixteen_to_thirty_no_of_bills,
            sixteen_to_thirty_pending, thirtyone_to_fourtyfive_no_of_bills, thirtyone_to_fourtyfive_pending,
            fourtysix_to_sixty_no_of_bills, fourtysix_to_sixty_pending, above_sixty_no_of_bills,
            above_sixty_pending
          ]
        end
      end
      # EOF invoice_data

      def forward_params(facility_id)
        params_str = "&start_date=#{@mis_params[:start_date]}"
        params_str += "&end_date=#{@mis_params[:end_date]}"
        params_str += "&time_period=#{@mis_params[:time_period]}"
        params_str += "&bill_type=credit"
        params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
        params_str += "&facility_id=#{facility_id}"
        params_str += "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        params_str += '&group=revenue'
        params_str += '&title=revenue_report'
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

      def previous_invoices(t_day, invoices, start_day, end_day = nil)
        invs = invoices.select { |x| (x[:receipt_date] <= (t_day - start_day.to_i.days)) }
        invs = invs.select { |x| (x[:receipt_date] >= (t_day - end_day.to_i.days)) } if end_day.present?
        invs
      end
      # EOF previous_invoices

      def invoices_inject_and_sum(invoices, field_name)
        invoices.inject(0) { |sum, hash| sum + hash[:payer_stats_fields][field_name.to_sym] }
      rescue StandardError
        0.00
      end
      # EOF previous_invoices
    end
  end
end

# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
