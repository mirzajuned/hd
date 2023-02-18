module Mis::FinancialReports
  class ModeByPayerService
    class << self
      def call(mis_params)
        @mis_params = mis_params

        @data_array = []

        aggregation_query, aggregation_query_count = payment_received_query

        @payment_receiveds = Invoice::PaymentReceived.collection.aggregate(aggregation_query).to_a || []
        payment_receiveds_count = Invoice::PaymentReceived.collection.aggregate(aggregation_query_count).to_a
        total_records = (payment_receiveds_count[0][:payment_received_count] if payment_receiveds_count.count > 0) || 0

        # Get Patient Details & Contacts for all Payement Received
        if @payment_receiveds.count > 0
          received_from_ids = @payment_receiveds.map { |pr| pr[:_id] }
          if received_from_ids.present? && received_from_ids.count > 0
            get_patient_fields(received_from_ids)
            get_payer_master_fields(received_from_ids)
          end
        end

        payment_received_data

        [@data_array, total_records]
      end

      private

      def payment_received_data
        currency_symbol = @mis_params[:currency_symbol].to_s

        @payment_receiveds.each do |payment_received|
          received_from = @patient_fields.to_a.find { |rf| rf if rf[:id] == payment_received[:_id].to_s }
          if received_from.present?
            received_from = received_from[:fullname].to_s
          else
            received_from = @payer_master_fields.to_a.find { |rf| rf if rf[:id] == payment_received[:_id].to_s }
            received_from = received_from[:display_name].to_s + ' (Contact)' if received_from.present?
          end

          amount = currency_symbol + payment_received[:amount].to_s
          @data_array << [received_from, amount]
        end
      end

      def payment_received_query
        match_options = {}

        # Currency
        match_options = match_options.merge(currency_id: @mis_params[:currency_id])

        # Facility/Organisation
        if @mis_params[:facility_id].present?
          match_options = match_options.merge(facility_id: { "$in": [@mis_params[:facility_id],
                                                                     BSON::ObjectId(@mis_params[:facility_id])] })
        else
          match_options = match_options.merge(
            organisation_id: { "$in": [@mis_params[:organisation_id], BSON::ObjectId(@mis_params[:organisation_id])] }
          )
        end

        # Date/Time
        match_options = match_options.merge(
          date: { "$gte": @mis_params[:start_date].beginning_of_day, "$lte": @mis_params[:end_date].end_of_day }
        )

        # PaymentMode
        if @mis_params[:payment_mode].present?
          match_options = match_options.merge(mode_of_payment: @mis_params[:payment_mode].to_s.titleize)
        end

        # PaymentMode Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": { _id: '$received_from', amount: { "$sum": '$amount' } } },
          { "$skip": @mis_params[:iDisplayStart].to_i },
          { "$limit": @mis_params[:iDisplayLength].to_i }
        ]

        # PaymentMode Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": { _id: '$received_from', amount: { "$sum": '$amount' } } },
          { "$group": { _id: 'null', payment_received_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
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
