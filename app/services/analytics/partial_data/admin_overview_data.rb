module Analytics::PartialData
  class AdminOverviewData
    def self.appointment_admission_data(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

      from_date = to_date - 6.days if from_date == to_date
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      user_id = BSON::ObjectId(user_id.to_s) if user_id.present?
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('user_id') unless user_id.present?

      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      appointment_admission_data = Analytics::GeneralOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$match' => {
              '$or' => match_with_this2
            }
          },
          {
            '$sort' => { "start_date": -1 }
          },
          {
            '$project' => {
              'appointment_created_count' => 1,
              'appointment_arrived_count' => 1,
              'opd_new_patient_count' => 1,
              'opd_old_patient_count' => 1,
              'admission_created_count' => 1,
              'admission_admitted_count' => 1,
              'start_date' => 1,
              'end_date' => 1
            }
          },
          {
            '$group' => {
              '_id' => { group_by.to_s => '$start_date' },
              'appointment_created_count' => { '$sum' => '$appointment_created_count' },
              'appointment_arrived_count' => { '$sum' => '$appointment_arrived_count' },
              'opd_new_patient_count' => { '$sum' => '$opd_new_patient_count' },
              'opd_old_patient_count' => { '$sum' => '$opd_old_patient_count' },
              'admission_created_count' => { '$sum' => '$admission_created_count' },
              'admission_admitted_count' => { '$sum' => '$admission_admitted_count' },
              'start_date' => { '$addToSet' => '$start_date' },
              'end_date' => { '$addToSet' => '$end_date' }
            }
          },
          {
            '$sort' => { "start_date": -1 }
          }

        ]
      ).to_a

      appointment_created_count = []
      appointment_arrived_count = []

      opd_new_patient_count   = []
      opd_old_patient_count   = []

      admission_created_count   = []
      admission_admitted_count  = []

      appointment_admission_data = appointment_admission_data.reverse

      if group_by == '$dayOfMonth'
        appointment_admission_data = from_date.upto(to_date).to_a.map { |date| (appointment_admission_data.find { |set| set['_id'].to_i == date.strftime('%d').to_i }) || {} }
        appointment_admission_data.each_with_index do |row, _indx|
          if row.present?
            appointment_created_count << row['appointment_created_count']
            appointment_arrived_count << row['appointment_arrived_count']
            opd_new_patient_count <<  row['opd_new_patient_count']
            opd_old_patient_count <<  row['opd_old_patient_count']
            admission_created_count <<  row['admission_created_count']
            admission_admitted_count << row['admission_admitted_count']
          else
            appointment_created_count << 0
            appointment_arrived_count << 0
            opd_new_patient_count <<  0
            opd_old_patient_count <<  0
            admission_created_count <<  0
            admission_admitted_count << 0
          end
        end
      elsif group_by == '$week'

        appointment_admission_data = appointment_admission_data.each { |set| (set['_id'] = set['_id'].to_i + 1) if set['_id'].present? }
        appointment_admission_data.each_with_index do |row, _indx|
          if row.present?
            appointment_created_count << row['appointment_created_count']
            appointment_arrived_count << row['appointment_arrived_count']
            opd_new_patient_count <<  row['opd_new_patient_count']
            opd_old_patient_count <<  row['opd_old_patient_count']
            admission_created_count <<  row['admission_created_count']
            admission_admitted_count << row['admission_admitted_count']
          else
            appointment_created_count << 0
            appointment_arrived_count << 0
            opd_new_patient_count <<  0
            opd_old_patient_count <<  0
            admission_created_count <<  0
            admission_admitted_count << 0
          end
        end
      elsif group_by == '$month'
        appointment_admission_data.each_with_index do |row, _indx|
          if row.present?
            appointment_created_count << row['appointment_created_count']
            appointment_arrived_count << row['appointment_arrived_count']
            opd_new_patient_count <<  row['opd_new_patient_count']
            opd_old_patient_count <<  row['opd_old_patient_count']
            admission_created_count <<  row['admission_created_count']
            admission_admitted_count << row['admission_admitted_count']
          else
            appointment_created_count << 0
            appointment_arrived_count << 0
            opd_new_patient_count <<  0
            opd_old_patient_count <<  0
            admission_created_count <<  0
            admission_admitted_count << 0
          end
        end
      elsif group_by == '$year'
        appointment_admission_data.each_with_index do |row, _indx|
          if row.present?
            appointment_created_count << row['appointment_created_count']
            appointment_arrived_count << row['appointment_arrived_count']
            opd_new_patient_count <<  row['opd_new_patient_count']
            opd_old_patient_count <<  row['opd_old_patient_count']
            admission_created_count <<  row['admission_created_count']
            admission_admitted_count << row['admission_admitted_count']
          else
            appointment_created_count << 0
            appointment_arrived_count << 0
            opd_new_patient_count <<  0
            opd_old_patient_count <<  0
            admission_created_count <<  0
            admission_admitted_count << 0
          end
        end

      end

      [appointment_created_count, appointment_arrived_count, opd_new_patient_count, opd_old_patient_count, admission_created_count, admission_admitted_count]
    end

    def self.financial_data(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      currency_id = nil # params_hash['currency_id']
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id.to_s,
        'facility_id' => facility_id.to_s,
        'specialty_id' => specialty_id.to_s,
        'currency_id' => currency_id,
        'user_id' => user_id
      }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('currency_id') unless currency_id.present?
      match_with_this.except!('user_id') unless user_id.present?

      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      financial_data = Analytics::Financial::FinancialOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$match' => { '$or' => match_with_this2 }
          }, {
            '$group' => {
              '_id' => 'null',
              'pharmacy_old_patient_amount' => { '$sum' => '$pharmacy_old_patient_amount' },
              'pharmacy_new_patient_amount' => { '$sum' => '$pharmacy_new_patient_amount' },

              'optical_old_patient_amount' => { '$sum' => '$optical_old_patient_amount' },
              'optical_new_patient_amount' => { '$sum' => '$optical_new_patient_amount' },

              'opd_new_patient_amount' => { '$sum' => '$opd_new_patient_amount' },
              'opd_old_patient_amount' => { '$sum' => '$opd_old_patient_amount' },

              'ipd_new_patient_amount' => { '$sum' => '$ipd_new_patient_amount' },
              'ipd_old_patient_amount' => { '$sum' => '$ipd_old_patient_amount' }
            }
          }

        ]
      ).to_a

      pharmacy_old_patient_amount = 0.0
      pharmacy_new_patient_amount = 0.0

      optical_old_patient_amount = 0.0
      optical_new_patient_amount = 0.0

      opd_new_patient_amount = 0.0
      opd_old_patient_amount = 0.0

      ipd_new_patient_amount = 0.0
      ipd_old_patient_amount = 0.0

      financial_data.each do |row|
        pharmacy_old_patient_amount += row['pharmacy_old_patient_amount']
        pharmacy_new_patient_amount += row['pharmacy_new_patient_amount']

        optical_old_patient_amount += row['optical_old_patient_amount']
        optical_new_patient_amount += row['optical_new_patient_amount']

        opd_new_patient_amount += row['opd_new_patient_amount']
        opd_old_patient_amount += row['opd_old_patient_amount']

        ipd_new_patient_amount += row['ipd_new_patient_amount']
        ipd_old_patient_amount += row['ipd_old_patient_amount']
      end

      [pharmacy_old_patient_amount, pharmacy_new_patient_amount, optical_old_patient_amount, optical_new_patient_amount, opd_new_patient_amount, opd_old_patient_amount, ipd_new_patient_amount, ipd_old_patient_amount]
    end

    def self.over_all_earnings(params_hash = {})
      daily_report_aggregated_data = daily_report_data(params_hash)

      advance_payment_aggregated_data = advance_payment_data(params_hash)

      optical_invoice_aggregated_data = optical_invoice_earnings(params_hash)

      pharmacy_invoice_aggregated_data = pharmacy_invoice_earnings(params_hash)

      over_all_earnings_total = daily_report_aggregated_data.to_f + advance_payment_aggregated_data.to_f + optical_invoice_aggregated_data.to_f + pharmacy_invoice_aggregated_data.to_f

      [over_all_earnings_total, advance_payment_aggregated_data.to_f]
    end

    def self.pharmacy_invoice_earnings(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id.to_s,
        'specialty_id' => specialty_id.to_s,
        'user_id' => user_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        '_type' => 'Invoice::Inventories::Department::PharmacyInvoice'
      }

      match_with_this.except!('user_id') unless user_id.present?
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      pharmacy_data = Invoice.collection.aggregate(
        [
          {
            '$match' => match_with_this
          },
          {
            '$group' => {
              '_id' => 'null',
              'total_pharmacy_amount' => { '$sum' => '$total' }
            }
          }
        ]
      ).to_a

      total_pharmacy_amount = 0
      pharmacy_data.each do |row|
        total_pharmacy_amount += row['total_pharmacy_amount']
      end

      total_pharmacy_amount
    end

    def self.optical_invoice_earnings(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        '_type' => 'Invoice::Inventories::Department::OpticalInvoice'
      }

      match_with_this.except!('user_id') unless user_id.present?
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      optical_invoice_data = Invoice.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$group' => {
              '_id' => 'null',
              'total_optical_amount' => { '$sum' => '$total' }
            }
          }
        ]
      ).to_a

      total_optical_amount = 0
      optical_invoice_data.each do |row|
        total_optical_amount += row['total_optical_amount']
      end

      total_optical_amount
    end

    def self.advance_payment_data(params_hash)
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id,
        'created_at' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        },
        'is_deleted' => false
      }

      match_with_this.except!('user_id') unless user_id.present?
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      advance_payments_data = AdvancePayment.collection.aggregate(
        [
          { '$match' => match_with_this },
          {
            '$project' => {
              'advance_state' => 1,
              'amount' => 1,
              'type' => 1
            }
          }, {
            '$group' => {
              '_id' => '$advance_state',
              'amount' => { '$sum' => '$amount' }
            }
          }
        ]
      ).to_a

      settled_amount = 0
      none_amount = 0
      refund_amount = 0
      advance_payments_data.each do |row|
        if row['_id'].to_s.casecmp('settled').zero?
          settled_amount += row['amount']
        elsif row['_id'].to_s.casecmp('refund').zero?
          refund_amount += row['amount']
        elsif row['_id'].to_s.casecmp('none').zero?
          none_amount += row['amount']
        end
      end
      amount_earned = (settled_amount + none_amount) - refund_amount

      amount_earned
    end

    def self.daily_report_data(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id.to_s,
        'facility_id' => facility_id.to_s,
        'specialty_id' => specialty_id.to_s,
        'user_id' => user_id,
        'date' => {
          '$gte' => from_date.beginning_of_day,
          '$lte' => to_date.end_of_day
        }
      }

      match_with_this.except!('user_id') unless user_id.present?
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      daily_report_aggregated_data = DailyReport.collection.aggregate(
        [
          { '$match' => match_with_this },
          {
            '$project' => {
              'opd_invoice_payment_received' => 1,
              'opd_cash_reg_transaction' => 1,
              'ipd_invoice_payment_received' => 1,
              'ipd_cash_reg_transaction' => 1
            }
          },
          {
            '$group' => {
              '_id' => 'null',
              'opd_invoice_payment_received' => { '$sum' => '$opd_invoice_payment_received' },
              'opd_cash_reg_transaction' => { '$sum' => '$opd_cash_reg_transaction' },
              'ipd_invoice_payment_received' => { '$sum' => '$ipd_invoice_payment_received' },
              'ipd_cash_reg_transaction' => { '$sum' => '$ipd_cash_reg_transaction' }
            }
          }, {
            '$group' => {
              '_id' => 'null',
              'daily_report_earning' => {
                '$sum' => { '$add' =>
                                  ['$opd_invoice_payment_received', '$opd_cash_reg_transaction', '$ipd_invoice_payment_received', '$ipd_cash_reg_transaction'] }
              }
            }
          }
        ]
      ).to_a

      daily_data = 0.0
      daily_report_aggregated_data.each do |row|
        daily_data += row['daily_report_earning']
      end

      daily_data
    end

    def self.appointments_facility_data(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, user_id, from_date, to_date = params_fetch(params_hash)
      data_type = params_hash['data_type']
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id
      }
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('user_id') unless user_id.present?

      appointments_facility_data = Analytics::GeneralOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this

          }, {
            '$match' => { '$or' => match_with_this2 }
          }, {
            '$project' => {
              'appointment_created_count' => 1,
              'appointment_arrived_count' => 1,
              'opd_new_patient_count' => 1,
              'opd_old_patient_count' => 1,
              'admission_created_count' => 1,
              'admission_admitted_count' => 1,
              'facility_id' => 1,
              'data_type' => 1
            }
          }, {
            '$group' => {
              '_id' => { 'facility' => '$facility_id' },
              'appointment_created_count' => { '$sum' => '$appointment_created_count' },
              'appointment_arrived_count' => { '$sum' => '$appointment_arrived_count' },
              'opd_new_patient_count' => { '$sum' => '$opd_new_patient_count' },
              'opd_old_patient_count' => { '$sum' => '$opd_old_patient_count' },
              'admission_created_count' => { '$sum' => '$admission_created_count' },
              'admission_admitted_count' => { '$sum' => '$admission_admitted_count' }
            }
          }

        ]
      ).to_a

      facility_names_abbr = []
      facility_names_full = []
      appointment_not_arrived_count = []
      appointment_arrived_count = []

      appointments_facility_data = appointments_facility_data.sort_by { |k| k['appointment_created_count'] }.reverse
      appointments_facility_data.each do |app_data|
        fac_id = app_data['_id']['facility']
        facility = Facility.find_by(id: fac_id)
        facility_names_abbr.push(facility.try(:abbreviation))
        facility_names_full.push(facility.try(:name))
        appointment_not_arrived_count.push(app_data['appointment_created_count'].to_i - app_data['appointment_arrived_count'].to_i)
        appointment_arrived_count.push(app_data['appointment_arrived_count'])
      end

      top_5_facility_names_abbr = facility_names_abbr.take(5)
      top_5_facility_names_full = facility_names_full.take(5)
      top_5_appointment_not_arrived_count = appointment_not_arrived_count.take(5)
      top_5_appointment_arrived_count = appointment_arrived_count.take(5)

      [top_5_facility_names_abbr, top_5_facility_names_full, top_5_appointment_not_arrived_count, top_5_appointment_arrived_count, facility_names_abbr, facility_names_full, appointment_not_arrived_count, appointment_arrived_count]
    end

    def self.filter_group_by(from_date, to_date, label_on)
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

    def self.params_fetch(params_hash)
      organisation_id = params_hash['organisation_id']
      facility_id = params_hash['facility_id']
      specialty_id = params_hash['specialty_id']
      user_id = params_hash['user_id']
      from_date = params_hash['analytics_from_date']
      to_date = params_hash['analytics_to_date']

      [organisation_id, facility_id, specialty_id, user_id, from_date, to_date]
    end
  end
end
