module Mis::FinancialReports
  class AdvanceReceivedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        if @request == 'xls'
          @data_array << ['TYPE', 'DATE', 'RECEIPT ID', 'PATIENT DETAILS', 'AMOUNT RECEIVED', 'AMOUNT REMAINING']
        end

        advance_payments = AdvancePayment.collection.aggregate(advance_payment_query).to_a[0] || {}

        @advance_payments = advance_payments[:advance_payments] || []
        total_records = advance_payments[:advance_payment_count].to_i

        advance_payment_patient_ids = @advance_payments.map { |ap| ap[:patient_id] }
        if advance_payment_patient_ids.present? && advance_payment_patient_ids.count > 0
          get_patient_fields(advance_payment_patient_ids)
        end

        advance_payment_data

        [@data_array, total_records]
      end

      private

      def advance_payment_data
        @advance_payments.try(:each) do |advance_payment|
          # Patient Details
          patient_field = @patient_fields.to_a.find { |patient| patient[:id] == advance_payment[:patient_id].to_s }
          patient_fullname = patient_field[:fullname] if patient_field.present?

          # Currency
          advance_payment_currency_symbol = advance_payment[:currency_symbol].to_s

          # Table Data
          type = advance_payment[:type]
          date = advance_payment[:payment_date].strftime('%d/%m/%Y')
          receipt_id = "<a href='/invoice/advance_payments/#{advance_payment[:_id]}?reports=true' data-remote='true' \
                        data-toggle='modal' data-target='#invoice-modal'>#{advance_payment[:advance_display_id]}</a>"
          patient_details = patient_fullname
          if @request == 'json'
            amount_received = advance_payment_currency_symbol + advance_payment[:amount].to_f.to_s
            amount_remaining = advance_payment_currency_symbol + advance_payment[:amount_remaining].to_f.to_s
          else
            amount_received = advance_payment[:amount].to_f
            amount_remaining = advance_payment[:amount_remaining].to_f
          end

          @data_array << [type, date, receipt_id, patient_details, amount_received, amount_remaining]
        end
      end

      def advance_payment_query
        # AdvancePayment Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { payment_time: -1 } },
          { "$group": { _id: 'null', advance_payments: { "$push": '$$ROOT' }, advance_payment_count: { "$sum": 1 } } },
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
        match_options = match_options.merge(payment_time: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                            "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000
        { advance_payment_count: 1,
          advance_payments: {
            "$slice": ['$advance_payments', @mis_params[:iDisplayStart].to_i, length]
          } }
      end

      def get_patient_fields(patient_ids)
        patients = Patient.where(:id.in => patient_ids)
        @patient_fields = patients.map { |patient| { id: patient.id.to_s, fullname: patient.fullname } }
      end
    end
  end
end
