# 1  Metrics/AbcSize
# --
# 1  Total
module Mis::FinancialReports
  class PaymentReceivedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'TYPE', 'RECEIVED FROM', 'PAYMENT MODE', 'INVOICE AMOUNT'] if @request == 'xls'

        payment_receiveds = Invoice::PaymentReceived.collection.aggregate(payment_received_query).to_a[0] || {}

        @payment_receiveds = payment_receiveds[:payment_receiveds]
        total_records = payment_receiveds[:payment_received_count].to_i

        # Get Patient Details & Contacts for all Payement Received
        received_from_ids = @payment_receiveds.map { |pr| pr[:received_from] }
        if received_from_ids.present? && received_from_ids.count > 0
          get_patient_fields(received_from_ids)
          get_payer_master_fields(received_from_ids)
        end

        payment_received_data

        [@data_array, total_records]
      end

      private

      def payment_received_data(date = '')
        @payment_receiveds.try(:each) do |payment_received|
          received_date = (payment_received[:date].try(:strftime, '%d/%m/%Y') if date != payment_received[:date]) || ''
          date = payment_received[:date]

          invoice_type = payment_received[:invoice_type].to_s.upcase

          received_from_id = payment_received[:received_from].to_s
          received_data = @patient_fields.find { |rf| rf[:id] == received_from_id }
          received_data = @payer_master_fields.find { |rf| rf[:id] == received_from_id } if received_data.nil?

          received_from = received_data[:fullname] || received_data[:display_name] if received_data.present?

          mode_of_payment = payment_received[:mode_of_payment].to_s

          amount_received = payment_received[:currency_symbol].to_s + payment_received[:amount].to_s

          @data_array << [received_date, invoice_type, received_from, mode_of_payment, amount_received]
        end
      end

      def payment_received_query
        # PaymentReceived Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: -1 } },
          { "$group": group_options },
          { "$project": project_options }
        ]

        aggregation_query
      end

      def match_options
        # Currency
        match_options = { currency_id: @mis_params[:currency_id] }

        # Facility/Organisation
        if @mis_params[:facility_id].present?
          facility_ids = [@mis_params[:facility_id], BSON::ObjectId(@mis_params[:facility_id])]
          match_options = match_options.merge(facility_id: { "$in": facility_ids })
        else
          organisation_ids = [@mis_params[:organisation_id], BSON::ObjectId(@mis_params[:organisation_id])]
          match_options = match_options.merge(organisation_id: { "$in": organisation_ids })
        end

        # Date/Time
        match_options = match_options.merge(date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                    "$lte": @mis_params[:end_date].end_of_day })

        # IsActive
        match_options = match_options.merge(is_active: true)

        match_options
      end

      def group_options
        { _id: 'null', payment_receiveds: { "$push": '$$ROOT' }, payment_received_count: { "$sum": 1 } }
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000
        { payment_received_count: 1,
          payment_receiveds: { "$slice": ['$payment_receiveds', @mis_params[:iDisplayStart].to_i, length] } }
      end

      def get_patient_fields(patient_ids)
        patients = Patient.where(:id.in => patient_ids)
        @patient_fields = patients.map { |patient| { id: patient.id.to_s, fullname: patient.fullname } }
      end

      def get_payer_master_fields(payer_master_ids)
        payer_masters = PayerMaster.where(:id.in => payer_master_ids)
        @payer_master_fields = payer_masters.map { |payer_master| { id: payer_master.id.to_s, display_name: payer_master.display_name } }
      end
    end
  end
end
