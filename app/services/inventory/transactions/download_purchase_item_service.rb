class Inventory::Transactions::DownloadPurchaseItemService
  class << self
    def call(params, user_id)
      @user_id = user_id
      @purchase_params = params
      @data_array = []
      purchase_lists = Inventory::Transaction::Purchase.collection.aggregate(purchase_list_query).to_a[0] || {}
      @purchase_lists = purchase_lists[:purchase_lists] || []
      purchase_list_data

      [@data_array, @grand_total]
    end

    private

    def purchase_list_data
      @grand_total = 0
      @purchase_lists.each do |return_list|
        purchase = Inventory::Transaction::Purchase.find_by(id: return_list[:id])
        vendor = Inventory::Vendor.find_by(id: purchase.vendor_id)
        purchase_items = purchase.items
        next if purchase_items.empty?

        purchase_items.each do |item|
          transaction_date = purchase.created_at&.strftime('%d/%m/%Y  %I:%M %p')
          transaction_id = purchase.purchase_display_id
          bill_number = purchase.bill_number
          challan_number = purchase.challan_number
          vendor_name = vendor.name
          vendor_contact = vendor.mobile_number
          dl_number = vendor.dl_number
          gst = vendor.gst_number
          description = item.description&.titleize
          custom_field_tags = item.custom_field_tags&.reject(&:blank?)&.join(', ')
          item_name = custom_field_tags.present? ? "#{description} (#{custom_field_tags})" : description
          item_code = item.item_code || item.default_variant_code
          category = item.category&.titleize
          batch = item.batch_no
          model_no = item.model_no
          qty = item.stock
          unit_cost = item.unit_cost&.round(2)
          total_cost = item.total_cost&.round(2)
          @grand_total += total_cost
          expiry = item.expiry&.strftime('%d/%m/%Y')
          @data_array << [transaction_date, transaction_id, bill_number, challan_number, vendor_name, vendor_contact, dl_number, gst, item_name,
                          item_code, category, batch, model_no, expiry, qty, unit_cost, total_cost]
        end
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
      options = { store_id: BSON::ObjectId(@purchase_params[:store_id]) }
      options = options.merge(user_id: BSON::ObjectId(@user_id)) if @user_id != 'all_user'
      options[:created_at] = { "$gte": @purchase_params[:start_date].utc, "$lte": @purchase_params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        purchase_lists: { "$push": { id: '$_id' } }
      }
    end
  end
end
