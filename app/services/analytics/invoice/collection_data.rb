class Analytics::Invoice::CollectionData
  class << self
  	def call(params)
  	  result = Finance::CollectionTransactionData.collection.aggregate(query(params)).to_a
      data = Hash[result.collect{ |a| 
        [
          a['_id'],
          Hash[a['data'].collect { |d| [ d['type'], d['total_receipt_amount'] ] }]
        ]
      }]
      
      ipd = net_amount(data['IPD'] || {})
      opd = net_amount(data["OPD"] || {})
      optical = net_amount(data['Optical'] || {})
      pharmacy = net_amount(data['Pharmacy'] || {})

      total_net_amount = ipd['net_amount'] + opd['net_amount'] + optical['net_amount'] + pharmacy['net_amount']
      total_gross_amount = ipd['gross_amount'] + opd['gross_amount'] + optical['gross_amount'] + pharmacy['gross_amount']

      [
        { 'gross_amount' => total_gross_amount,
          'net_amount' => total_net_amount,
          'Refund' => total_gross_amount - total_net_amount
        },
        ipd, opd, optical, pharmacy
      ]
  	end

    def net_amount(data)
      data['gross_amount'] = gross_amount(data).round(2) || 0
      data['net_amount'] = (data['gross_amount'].to_f - data['Refund'].to_f).round(2)
      data
    end

    def gross_amount(data)
      data['Bill'].to_f + data['Advance'].to_f
    end

    def query(params)
      options = {
        organisation_id: params['organisation_id'].to_s,
        created_at: {
          :$gte => Date.parse(params['analytics_from_date']).beginning_of_day,
          :$lte => Date.parse(params['analytics_to_date']).end_of_day
        }
      }
      if params['facility_id'].present? && params['facility_id'] != 'all'
        options[:facility_id] = params['facility_id'].to_s
      end
      if params['filtered_specialty'].present? && params['filtered_specialty'] != 'all'
        options['receipt_display_fields.specialty_id'] = params['filtered_specialty']
      end
      [
        { '$match' => options },
        { '$group': group },
        { '$group': group_by_type }
      ]
    end

    def group
      {
        _id: {
          department: '$receipt_display_fields.department_name',
          type: '$receipt_type'
        },
        total_receipt_amount: { '$sum': "$receipt_display_fields.receipt_amount" }
      }
    end

    def group_by_type
      {
        _id: '$_id.department',
        data: {
          '$push': {
            type: '$_id.type',
            total_receipt_amount: '$total_receipt_amount'
          }
        }
      }
    end
  end
end
