# 3   Metrics/AbcSize
# 3   Metrics/CyclomaticComplexity
# 3   Metrics/MethodLength
# 3   Metrics/PerceivedComplexity
# 1   Metrics/BlockLength
# 1   Metrics/ClassLength
# --
# 14  Total
module Mis::FinancialReports
  class SalesByInvoicesService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        if @request == 'xls'
          if @mis_params[:group] == 'sales'
            @data_array << ['TYPE', 'BILL DATE', 'INVOICE ID', 'PATIENT DETAILS',
                            'ADVANCE ADJUSTED', 'AMOUNT RECEIVED', 'AMOUNT PENDING', 'INVOICE AMOUNT']
          elsif @mis_params[:group] == 'receivables'
            @data_array << ['TYPE', 'BILL DATE', 'INVOICE ID', 'PATIENT DETAILS', 'INVOICE AMOUNT', 'AMOUNT PENDING']
          elsif @mis_params[:group] == 'payment_received'
            @data_array << ['TYPE', 'BILL DATE', 'INVOICE ID', 'PATIENT DETAILS', 'INVOICE AMOUNT', 'AMOUNT RECEIVED']
          end
        end

        invoices = Invoice.collection.aggregate(invoice_query).to_a[0] || {}

        @invoices = invoices[:invoices]
        total_records = invoices[:invoice_count].to_i

        if invoices.count > 0
          invoice_patient_ids = @invoices.map { |invoice| invoice[:patient_id] }
          get_patient_fields(invoice_patient_ids) if invoice_patient_ids.present? && invoice_patient_ids.count > 0
        end

        invoice_data

        [@data_array, total_records]
      end

      private

      def invoice_data
        @invoices.try(:each) do |invoice|
          patient_field = @patient_fields.to_a.find { |patient| patient[:id] == invoice[:patient_id].to_s }
          patient_fullname = patient_field[:fullname] if patient_field.present?

          invoice_currency_symbol = invoice[:currency_symbol].to_s

          advance_payment_array = []
          payment_received_array = []
          if @request == 'json'
            invoice[:advance_payment_breakups].to_a.each do |advance|
              text = "#{advance[:currency_symbol]} #{advance[:amount]} (#{advance[:mode_of_payment]})"
              advance_payment_array << text
            end

            invoice[:payment_received_breakups].to_a.each do |received|
              text = "#{received[:currency_symbol]} #{received[:amount]} (#{received[:mode_of_payment]})"
              payment_received_array << text
            end
            empty_payment_array = invoice_currency_symbol + '0.0'
          else
            invoice[:advance_payment_breakups].to_a.each do |advance|
              text = "#{advance[:amount]} (#{advance[:mode_of_payment]})"
              advance_payment_array << text
            end

            invoice[:payment_received_breakups].to_a.each do |received|
              text = "#{received[:amount]} (#{received[:mode_of_payment]})"
              payment_received_array << text
            end
            empty_payment_array = '0.0'
          end

          # Table Data
          type = invoice[:_type].to_s.split(':')[-1].upcase
          type = invoice[:department_name] if type == 'INVENTORYINVOICE'
          bill_date = invoice[:created_at].strftime('%d/%m/%Y')
          invoice_id = if type.in?(['OPD', 'IPD'])
                         "<a href='/invoice/#{type.downcase}/#{invoice[:_id]}?reports=true' data-remote='true' \
                          data-toggle='modal' data-target='#invoice-modal'>#{invoice[:bill_number]}</a>"
                      else
                        "<a href='/invoice/inventory_invoices/show_modal?id=#{invoice[:_id]}&reports=true' "\
                        "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{invoice[:bill_number]}</a>"
                      end
          patient_details = patient_fullname
          advance_adjusted = advance_payment_array.count > 0 ? advance_payment_array.join('<br>') : empty_payment_array
          amount_received = payment_received_array.count > 0 ? payment_received_array.join('<br>') : empty_payment_array
          pending_amount = invoice[:payment_pending_breakups].to_a.empty? ? '0.0' : invoice[:payment_pending].to_s
          # amount_pending = invoice_currency_symbol + pending_amount
          amount_pending = pending_amount
          # invoice_amount = invoice_currency_symbol + invoice[:net_amount].to_s
          invoice_amount = invoice[:net_amount].to_s

          if @mis_params[:group] == 'sales'
            @data_array << [type, bill_date, invoice_id, patient_details, advance_adjusted,
                            amount_received, amount_pending, invoice_amount]
          elsif @mis_params[:group] == 'receivables'
            @data_array << [type, bill_date, invoice_id, patient_details, invoice_amount, amount_pending]
          elsif @mis_params[:group] == 'payment_received'
            @data_array << [type, bill_date, invoice_id, patient_details, invoice_amount, amount_received]
          end
        end
      end

      def invoice_query
        # Invoice Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { created_at: -1 } },
          { "$group": { _id: 'null', invoices: { "$push": '$$ROOT' }, invoice_count: { "$sum": 1 } } },
          { "$project": project_options }
        ]

        aggregation_query
      end

      def match_options
        # Currency
        match_options = { is_draft: { "$in": [nil, false] }, is_deleted: false }
        match_options.merge!(currency_id: @mis_params[:currency_id]) if @mis_params[:currency_id].present?

        # Facility/Organisation
        if @mis_params[:facility_id].present?
          facility_ids = [@mis_params[:facility_id], BSON::ObjectId(@mis_params[:facility_id])]
          match_options = match_options.merge(facility_id: { "$in": facility_ids })
        else
          organisation_ids = [@mis_params[:organisation_id], BSON::ObjectId(@mis_params[:organisation_id])]
          match_options = match_options.merge(organisation_id: { "$in": organisation_ids })
        end

        # Date/Time
        match_options = match_options.merge(created_at: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                          "$lte": @mis_params[:end_date].end_of_day })

        # Invoice Type
        invoice_types = ['Invoice::Opd', 'Invoice::Ipd', 'Invoice::InventoryInvoice']
        invoice_type = @mis_params[:invoice_type]
        if invoice_types.include?('Invoice::' + invoice_type.titleize.to_s)
          match_options = match_options.merge(_type: 'Invoice::' + invoice_type.titleize.to_s)
        elsif invoice_type == 'all'
          match_options = match_options.merge(_type: { "$in": invoice_types })
        end

        # Group
        if @mis_params[:group] == 'receivables'
          if @mis_params[:payer_id].present? # Aging Summary
            payer_id = @mis_params[:payer_id]
            match_options = match_options.merge("payment_pending_breakups.received_from": BSON::ObjectId(payer_id))
          else
            match_options = match_options.merge(payment_pending_breakups: { "$exists": true })
          end
        elsif @mis_params[:group] == 'payment_received'
          match_options = match_options.merge(payment_received_breakups: { "$exists": true })
        end

        match_options
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000
        { invoice_count: 1,
          invoices: {
            "$slice": ['$invoices', @mis_params[:iDisplayStart].to_i, length]
          } }
      end

      def get_patient_fields(patient_ids)
        patients = Patient.where(:id.in => patient_ids)
        @patient_fields = patients.map { |patient| { id: patient.id.to_s, fullname: patient.fullname } }
      end
    end
  end
end
