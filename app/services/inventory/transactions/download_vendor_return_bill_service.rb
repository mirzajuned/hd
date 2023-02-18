class Inventory::Transactions::DownloadVendorReturnBillService
  class << self
    def call(params, department_id, user_id)
      @user_id = user_id
      @return_params = params
      @department_id = department_id
      @data_array = []
      return_lists = Inventory::Transaction::VendorReturn.collection.aggregate(return_list_query).to_a[0] || {}
      @return_lists = return_lists[:return_lists] || []
      return_list_data

      [@data_array, @total_array]
    end

    private

    def return_list_data
      @total_array = []
      @gross_total_cost = 0
      @gross_total_discount = 0
      @gross_return_amount = 0
      @gross_paid_amount = 0
      @gross_debit_amount = 0
      @return_lists.each do |return_list|
        purchase_return = Inventory::Transaction::VendorReturn.find_by(id: return_list[:id])
        purchase = Inventory::Transaction::Purchase.find_by(id: purchase_return.purchase_transaction_id)
        transaction_date = purchase_return.transaction_time&.strftime('%d/%m/%Y  %I:%M %p')
        purchase_bill_no = purchase.present? ? purchase.purchase_display_id : 'Return Against Multiple Purchase'
        purchase_return_id = purchase_return.purchase_return_id
        entered_by = purchase_return.entered_by&.titleize
        comments = purchase_return.comments
        note = purchase_return.note
        vendor_name = purchase_return.vendor_name&.titleize
        vendor_mobile = purchase_return.vendor_mobile
        status = purchase_return.full_settlement ? 'Payment Done' : 'Payment Partially Done'
        total_cost = purchase_return.total_cost
        return_discount = purchase_return.return_discount
        return_amount = purchase_return.return_amount
        paid_amount = purchase_return.paid_amount
        debit_amount = purchase_return.debit_amount
        @gross_total_cost += total_cost || 0
        @gross_total_discount += return_discount || 0
        @gross_return_amount += return_amount || 0
        @gross_paid_amount += paid_amount || 0
        @gross_debit_amount += debit_amount || 0
        @data_array << [
          transaction_date, purchase_bill_no, purchase_return_id, entered_by, note, comments, vendor_name, vendor_mobile, status,
          total_cost, return_discount, return_amount, paid_amount, debit_amount
        ]
      end
      @total_array << @gross_total_cost << @gross_total_discount << @gross_return_amount << @gross_paid_amount << @gross_debit_amount
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
