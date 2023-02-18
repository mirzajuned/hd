# 3   Metrics/AbcSize
# 3   Metrics/CyclomaticComplexity
# 3   Metrics/MethodLength
# 3   Metrics/PerceivedComplexity
# 1   Metrics/BlockLength
# 1   Metrics/ClassLength
# --
# 14  Total
module Mis::FinancialReports
  class MisRevenueService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []
        invoices = Finance::ReportData.collection.aggregate(invoice_query).to_a[0] || {}

        @invoices = invoices[:invoices]
        total_records = invoices[:invoice_count].to_i
        invoice_data
        [@data_array, total_records]
      end

      private

      def invoice_data
        @invoices.try(:each) do |invoice|
          # Table Data
          @data_array << generate_table_data(@mis_params[:group], invoice)
        end
      end

      def invoice_query
        # Finance::ReportData Query
        Mis::QueryBuilderService.call(@mis_params, 'mis_revenue')
      end
      # EOF invoice_query

      def generate_table_data(report_group, invoice)
        # invoice_patient_payer
        invoice_patient = invoice[:patient_display_fields]
        invoice_payer = invoice[:payer_display_fields]
        patient_details = invoice_patient['patient_name']
        patient_details = patient_details + "/#{invoice_patient['age']}" if invoice_patient['age'].present?
        patient_details = patient_details + "/#{invoice_patient['gender']}" if invoice_patient['gender'].present?
        patient_details = patient_details + "/#{invoice_patient['patient_identifier_id']}" if invoice_patient['patient_identifier_id'].present?
        patient_details = patient_details + "/#{invoice_patient['patient_mrn']}" if invoice_patient['patient_mrn'].present?
        payer_details = '-'
        payer_details = invoice_payer['payer_name'] if invoice_payer && invoice_payer['payer_name']
        # EOF invoice_patient_payer
        t_data = [patient_details, payer_details]

        # invoice_user
        invoice_user = invoice[:user_display_fields]
        user_details = invoice_user['name']
        user_details = user_details + "/#{invoice_user['designation']}"
        # EOF invoice_user

        # invoice
        invoice_data = invoice[:receipt_display_fields]
        # EOF invoice

        # invoice_commmon
        invoice_commmon = invoice[:common_display_fields]
        common_details = invoice_commmon['display_id']
        common_details = common_details + "<br><b>#{invoice_commmon['appointmenttype']}</b>" if invoice_commmon['appointmenttype'].present?
        common_details = common_details + "<br><u>#{invoice_commmon['reason']}</u>" if invoice_commmon['reason'].present?
        # EOF invoice_commmon

        t_data << [ invoice_data['bill_no'], invoice_data['bill_date_time'], invoice_data['type'].upcase, invoice_data['total'], invoice_data['advance_payment'], invoice_data['amount_remaining'], invoice_data['payment_received'], invoice_data['invoice_type'], user_details, common_details ]

        t_data.flatten
      end
    end
  end
end