class Analytics::Invoice::BillData
  class << self
    def call(params)
      result = Invoice.collection.aggregate(query(params)).to_a
      data = Hash[result.collect{ |item| [ item["_id"], item ] }]
      [ 
        collection(data, "Pharmacy"),
        collection(data, "Optical"),
        collection(data, "OPD"),
        collection(data, "IPD")
      ]
    end

    def collection(data, type)
      inventory = data[type]
      if inventory.blank?
        {
          cash: {},
          credit: {}
        }
      else
        cash = inventory["invoice_types"].detect { |i| i["invoice_type"] == "cash" } || {}
        credit = inventory["invoice_types"].detect { |i| i["invoice_type"] == "credit" } || {}
        { 
          total_gross_amount: inventory['total_gross_amount'].round(2),
          total_net_amount: inventory["total_net_amount"].round(2),
          cash: cash,
          credit: credit
        }
      end
    end

    def query(params)
      options = {
        organisation_id: params['organisation_id'],
        created_at: {
          :$gte => Date.parse(params['analytics_from_date']).beginning_of_day,
          :$lte => Date.parse(params['analytics_to_date']).end_of_day
        },
        is_draft: false
      }
      if params['facility_id'].present? && params['facility_id'] != 'all'
        facility_id = params['facility_id'].to_s
        options['$or'] = [ {facility_id: facility_id},
                           {facility_id: BSON::ObjectId(facility_id)} ] 
      end
      if params['filtered_specialty'].present? && params['filtered_specialty'] != 'all'
        options[:specialty_id] = params['filtered_specialty']
      end
      [
        { '$match' => options },
        { '$group': group },
        { '$group': group_by }
      ]
    end

    def group
      {
        _id: {department_name: '$department_name', invoice_type: '$invoice_type'},
        department_name: { '$first': '$department_name' },
        invoice_type: { '$first': "$invoice_type" },
        total_gross_amount: { '$sum': "$total" },
        total_net_amount: { '$sum': "$net_amount" }
      }
    end

    def group_by
      {
        _id: '$department_name',
        invoice_types: {
          '$push': {
            invoice_type: '$invoice_type',
            total_gross_amount: '$total_gross_amount',
            total_net_amount: '$total_net_amount'
          },
        },
        total_gross_amount: { '$sum': "$total_gross_amount" },
        total_net_amount: { '$sum': '$total_net_amount' }
      }
    end


  end
end