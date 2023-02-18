module Analytics::PartialData
  class FinanceOverviewData
    class << self
      def call(params_hash = {})
        label_on = params_hash['label_on']
        organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
        group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
        currency_id = nil # params_hash['currency_id']
        organisation_id = BSON::ObjectId(organisation_id.to_s)
        facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
        user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id
        # if from_date == to_date
        #   from_date = from_date - 7.days
        # end
        match_with_this = {
          'organisation_id' => organisation_id.to_s,
          'facility_id' => facility_id.to_s,
          'specialty_id' => specialty_id,
          'currency_id' => currency_id,
          'user_id' => user_id
        }
        match_with_this.except!('facility_id') if facility_id == 'all'
        match_with_this.except!('specialty_id') if specialty_id == 'all'
        match_with_this.except!('currency_id') unless currency_id.present?
        match_with_this.except!('user_id') unless user_id.present?

        match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

        finance_analytics = Analytics::Financial::FinancialOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            },
            {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$sort' => { "start_date": -1 }
            },
            {
              '$group' => {
                '_id' => { group_by.to_s => '$start_date' },
                'opd_new_patient_amount' => { '$sum' => '$opd_new_patient_amount' },
                'opd_old_patient_amount' => { '$sum' => '$opd_old_patient_amount' },
                'opd_invoice_count' => { '$sum' => '$opd_invoice_count' },
                'ipd_new_patient_amount' => { '$sum' => '$ipd_new_patient_amount' },
                'ipd_old_patient_amount' => { '$sum' => '$ipd_old_patient_amount' },
                'ipd_invoice_count' => { '$sum' => '$ipd_invoice_count' },
                'pharmacy_new_patient_amount' => { '$sum' => '$pharmacy_new_patient_amount' },
                'pharmacy_old_patient_amount' => { '$sum' => '$pharmacy_old_patient_amount' },
                'pharmacy_invoice_count' => { '$sum' => '$pharmacy_invoice_count' },
                'optical_new_patient_amount' => { '$sum' => '$optical_new_patient_amount' },
                'optical_old_patient_amount' => { '$sum' => '$optical_old_patient_amount' },
                'optical_invoice_count' => { '$sum' => '$optical_invoice_count' },
                'start_date' => { '$addToSet' => '$start_date' },
                'end_date' => { '$addToSet' => '$end_date' }
              }
            },
            {
              '$sort' => { "start_date": -1 }
            }
          ]
        ).to_a

        weekly_financial_overview_grp_by_date = Analytics::Financial::FinancialOverview.collection.aggregate(
          [
            {
              '$match' => match_with_this
            },
            {
              '$match' => { '$or' => match_with_this2 }
            },
            {
              '$group' => {
                '_id' => { group_by.to_s => '$start_date' },
                'opd_new_patient_amount' => { '$sum' => '$opd_new_patient_amount' },
                'opd_old_patient_amount' => { '$sum' => '$opd_old_patient_amount' },
                'opd_invoice_count' => { '$sum' => '$opd_invoice_count' },
                'ipd_new_patient_amount' => { '$sum' => '$ipd_new_patient_amount' },
                'ipd_old_patient_amount' => { '$sum' => '$ipd_old_patient_amount' },
                'ipd_invoice_count' => { '$sum' => '$ipd_invoice_count' },
                'pharmacy_new_patient_amount' => { '$sum' => '$pharmacy_new_patient_amount' },
                'pharmacy_old_patient_amount' => { '$sum' => '$pharmacy_old_patient_amount' },
                'pharmacy_invoice_count' => { '$sum' => '$pharmacy_invoice_count' },
                'optical_new_patient_amount' => { '$sum' => '$optical_new_patient_amount' },
                'optical_old_patient_amount' => { '$sum' => '$optical_old_patient_amount' },
                'optical_invoice_count' => { '$sum' => '$optical_invoice_count' },
                'start_date' => { '$addToSet' => '$start_date' },
                'end_date' => { '$addToSet' => '$end_date' }
              }
            },
            {
              '$sort' => { "start_date": -1 }
            }
          ]
        ).to_a

        appointment_chart_labels = []
        weekly_financial_overview_grp_by_date = weekly_financial_overview_grp_by_date.reverse
        finance_analytics = finance_analytics.reverse

        if group_by == '$dayOfMonth'
          weekly_financial_overview_grp_by_date = from_date.upto(to_date).to_a.map { |date| (weekly_financial_overview_grp_by_date.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
          next_date = from_date
          finance_analytics = from_date.upto(to_date).to_a.map { |date| (finance_analytics.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
          weekly_financial_overview_grp_by_date.each_with_index do |row, _indx|
            if row.present?
              appointment_chart_labels << row['start_date'][0].strftime('%d %a')
              next_date = row['start_date'][0] + 1.day
            else
              appointment_chart_labels << next_date.strftime('%d %a')
              next_date += 1.day
            end
          end
        elsif group_by == '$week'
          weekly_financial_overview_grp_by_date = weekly_financial_overview_grp_by_date.each { |set| (set['_id'] = set['_id'].to_i) if set['_id'].present? }
          finance_analytics = finance_analytics.each { |set| (set['_id'] = set['_id'].to_i) if set['_id'].present? }
          weekly_financial_overview_grp_by_date.each_with_index do |row, _indx|
            start_date = row['start_date'][0]
            end_date = row['end_date'][0]
            appointment_chart_labels << "#{start_date.strftime('%d %b')}-#{end_date.strftime('%d %b')}"
          end
        elsif group_by == '$month'
          weekly_financial_overview_grp_by_date.each_with_index do |row, _indx|
            appointment_chart_labels << row['start_date'][0].strftime('%b %Y')
          end
        elsif group_by == '$year'
          weekly_financial_overview_grp_by_date.each_with_index do |row, _indx|
            appointment_chart_labels << row['start_date'][0].strftime('%b %Y')
          end
        end

        [appointment_chart_labels, finance_analytics, weekly_financial_overview_grp_by_date]
      end

      def periodic_outpatient_data(weekly_financial_overview)
        @weekly_opd_new_patient_amount = weekly_financial_overview.map { |el| el['opd_new_patient_amount'].to_f }
        @weekly_opd_old_patient_amount = weekly_financial_overview.map { |el| el['opd_old_patient_amount'].to_f }
        @weekly_opd_amount = weekly_financial_overview.map { |el| el['opd_new_patient_amount'].to_f + el['opd_old_patient_amount'].to_f }
        @weekly_opd_invoice_count = weekly_financial_overview.map { |el| el['opd_invoice_count'].to_f }
        [@weekly_opd_new_patient_amount, @weekly_opd_old_patient_amount, @weekly_opd_amount, @weekly_opd_invoice_count]
      end

      def periodic_inpatient_data(weekly_financial_overview)
        @weekly_ipd_new_patient_amount = weekly_financial_overview.map { |el| el['ipd_new_patient_amount'].to_f }
        @weekly_ipd_old_patient_amount = weekly_financial_overview.map { |el| el['ipd_old_patient_amount'].to_f }
        @weekly_ipd_amount = weekly_financial_overview.map { |el| el['ipd_new_patient_amount'].to_f + el['ipd_old_patient_amount'].to_f }
        @weekly_ipd_invoice_count = weekly_financial_overview.map { |el| el['ipd_invoice_count'].to_f }
        [@weekly_ipd_new_patient_amount, @weekly_ipd_old_patient_amount, @weekly_ipd_amount, @weekly_ipd_invoice_count]
      end

      def periodic_pharmacy_data(weekly_financial_overview)
        @weekly_pharmacy_new_patient_amount = weekly_financial_overview.map { |el| el['pharmacy_new_patient_amount'].to_f }
        @weekly_pharmacy_old_patient_amount = weekly_financial_overview.map { |el| el['pharmacy_old_patient_amount'].to_f }
        @weekly_pharmacy_amount = weekly_financial_overview.map { |el| el['pharmacy_new_patient_amount'].to_f + el['pharmacy_old_patient_amount'].to_f }
        @weekly_pharmacy_invoice_count = weekly_financial_overview.map { |el| el['pharmacy_invoice_count'].to_f }
        [@weekly_pharmacy_new_patient_amount, @weekly_pharmacy_old_patient_amount, @weekly_pharmacy_amount, @weekly_pharmacy_invoice_count]
      end

      def periodic_optical_data(weekly_financial_overview)
        @weekly_optical_new_patient_amount = weekly_financial_overview.map { |el| el['optical_new_patient_amount'].to_f }
        @weekly_optical_old_patient_amount = weekly_financial_overview.map { |el| el['optical_old_patient_amount'].to_f }
        @weekly_optical_amount = weekly_financial_overview.map { |el| el['optical_new_patient_amount'].to_f + el['optical_old_patient_amount'].to_f }
        @weekly_optical_invoice_count = weekly_financial_overview.map { |el| el['optical_invoice_count'].to_f }

        [@weekly_optical_new_patient_amount, @weekly_optical_old_patient_amount, @weekly_optical_amount, @weekly_optical_invoice_count]
      end

      def total_outpatient_data(finance_analytics)
        opd_new_patient_amount = []
        opd_old_patient_amount = []
        opd_invoice_count      = []
        finance_analytics.each do |row|
          if row.present?
            opd_new_patient_amount << row['opd_new_patient_amount'].to_f
            opd_old_patient_amount << row['opd_old_patient_amount'].to_f
            opd_invoice_count << row['opd_invoice_count'].to_i
          else
            opd_new_patient_amount << 0.0
            opd_old_patient_amount << 0.0
            opd_invoice_count << 0
          end
        end
        [opd_new_patient_amount, opd_old_patient_amount, opd_invoice_count]
      end

      def total_inpatient_data(finance_analytics)
        ipd_new_patient_amount = []
        ipd_old_patient_amount = []
        ipd_invoice_count      = []
        finance_analytics.each do |row|
          if row.present?
            ipd_new_patient_amount << row['ipd_new_patient_amount'].to_f
            ipd_old_patient_amount << row['ipd_old_patient_amount'].to_f
            ipd_invoice_count << row['ipd_invoice_count'].to_i
          else
            ipd_new_patient_amount << 0.0
            ipd_old_patient_amount << 0.0
            ipd_invoice_count << 0
          end
        end

        [ipd_new_patient_amount, ipd_old_patient_amount, ipd_invoice_count]
      end

      def total_pharmacy_data(finance_analytics)
        pharmacy_new_patient_amount = []
        pharmacy_old_patient_amount = []
        pharmacy_invoice_count      = []
        finance_analytics.each do |row|
          if row.present?
            pharmacy_new_patient_amount << row['pharmacy_new_patient_amount'].to_f
            pharmacy_old_patient_amount << row['pharmacy_old_patient_amount'].to_f
            pharmacy_invoice_count << row['pharmacy_invoice_count'].to_i
          else
            pharmacy_new_patient_amount << 0.0
            pharmacy_old_patient_amount << 0.0
            pharmacy_invoice_count << 0
          end
        end

        [pharmacy_new_patient_amount, pharmacy_old_patient_amount, pharmacy_invoice_count]
      end

      def total_optical_data(finance_analytics)
        optical_new_patient_amount = []
        optical_old_patient_amount = []
        optical_invoice_count      = []
        finance_analytics.each do |row|
          if row.present?
            optical_new_patient_amount << row['optical_new_patient_amount'].to_f
            optical_old_patient_amount << row['optical_old_patient_amount'].to_f
            optical_invoice_count << row['optical_invoice_count'].to_i
          else
            optical_new_patient_amount << 0.0
            optical_old_patient_amount << 0.0
            optical_invoice_count << 0
          end
        end

        [optical_new_patient_amount, optical_old_patient_amount, optical_invoice_count]
      end

      private

      def fetch_params_hash(params_hash = {})
        organisation_id = params_hash['organisation_id']
        facility_id = params_hash['facility_id']
        specialty_id = params_hash['specialty_id']
        from_date = params_hash['analytics_from_date']
        to_date = params_hash['analytics_to_date']

        [organisation_id, facility_id, specialty_id, from_date, to_date]
      end

      def filter_group_by(from_date, to_date, label_on)
        from_date = Date.parse(from_date)
        to_date = Date.parse(to_date)

        group_by = case label_on
                   when 'days'
                     '$dayOfMonth'
                   when 'weeks'
                     '$week'
                   when 'months'
                     '$month'
                   else
                     '$year'
                   end

        [group_by, from_date, to_date]
      end
    end
  end
end
