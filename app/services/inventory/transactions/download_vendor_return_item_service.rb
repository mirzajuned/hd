class Inventory::Transactions::DownloadVendorReturnItemService
  class << self
    def call(params, department_id, user_id)
      @user_id = user_id
      @return_params = params
      @department_id = department_id
      @data_array = []
      return_lists = Inventory::Transaction::VendorReturn.collection.aggregate(return_list_query).to_a[0] || {}
      @return_lists = return_lists[:return_lists] || []
      return_list_data

      [@data_array, @grand_total]
    end

    private

    def return_list_data
      @grand_total = 0
      @return_lists.each do |return_list|
        vendor_return = Inventory::Transaction::VendorReturn.find_by(id: return_list[:id])
        return_items = vendor_return.items
        next if return_items.empty?

        return_items.each do |item|
          transaction_date = vendor_return.transaction_time&.strftime('%d/%m/%Y  %I:%M %p')
          transaction_id = vendor_return.purchase_return_id
          entered_by = vendor_return.entered_by
          note = vendor_return.note
          vendor_name = vendor_return.vendor_name
          vendor_contact = vendor_return.vendor_mobile
          description = item.description&.titleize
          custom_field_tags = item.custom_field_tags&.reject(&:blank?)&.join(', ')
          item_name = custom_field_tags.present? ? "#{description} (#{custom_field_tags})" : description
          item_code = item.variant_code
          category = item.category&.titleize
          batch = item.batch_no
          model_no = item.model_no
          qty = item.stock
          unit_cost = item.unit_cost&.round(2)
          total_cost = item.total_cost&.round(2)
          @grand_total += total_cost
          expiry = item.expiry&.strftime('%d/%m/%Y')
          @data_array << [transaction_date, transaction_id, entered_by, note, vendor_name, vendor_contact, item_name,
                          item_code, category, batch, model_no, expiry, qty, unit_cost, total_cost]
        end
      end
    end

    def return_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]

      aggregation_query
    end

    def match_options
      options = { store_id: BSON::ObjectId(@return_params[:store_id]) }
      options = options.merge(user_id: BSON::ObjectId(@user_id)) if @user_id != 'all_user'
      options[:created_at] = { "$gte": @return_params[:start_date].utc, "$lte": @return_params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        return_lists: { "$push": { id: '$_id' } }
      }
    end
  end
end
