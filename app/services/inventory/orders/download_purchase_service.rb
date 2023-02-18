class Inventory::Orders::DownloadPurchaseService
  class << self
    def call(params, department_id)
      @purchase_params = params
      @department_id = department_id
      @data_array = []
      @data_array << ['VENDOR NAME', 'TOTAL COST', 'TRANSACTION DATE', 'ENTERED BY', 'ENTRY TYPE']
      purchase_lists = Inventory::Order::Purchase.collection.aggregate(purchase_list_query).to_a[0] || {}
      @purchase_lists = purchase_lists[:purchase_lists] || []
      purchase_list_data

      @data_array
    end

    private

    def purchase_list_data
      @purchase_lists.each do |purchase_list|
        vendor_name = purchase_list[:vendor_name]
        total_cost = purchase_list[:total_cost]
        order_date = purchase_list[:order_date]&.strftime('%d/%m/%Y')
        entered_by = purchase_list[:entered_by]
        entry_type = purchase_list[:entry_type]

        @data_array << [vendor_name, total_cost, order_date, entered_by, entry_type]
      end
    end

    def purchase_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]
      aggregation_query
    end

    def match_options
      match_options = { store_id: BSON::ObjectId(@purchase_params[:store_id]) }
      match_options[:order_date] = { "$gte": @purchase_params[:start_date].beginning_of_day,
                                     "$lte": @purchase_params[:end_date].end_of_day }
      match_options
    end

    def group_options
      {
        _id: 'null',
        purchase_lists: { "$push": { vendor_name: '$vendor_name', total_cost: '$total_cost',
                                     order_date: '$order_date', entered_by: '$entered_by',
                                     entry_type: '$entry_type' } }
      }
    end
  end
end
