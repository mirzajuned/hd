class Inventory::Transactions::DownloadTransferService
  class << self
    def call(params, department_id, user_id)
      @user_id = user_id
      @transfer_params = params
      @department_id = department_id
      @data_array = []
      transfer_lists = Inventory::Transaction::Transfer.collection.aggregate(transfer_list_query).to_a[0] || {}
      @transfer_lists = transfer_lists[:transfer_lists] || []
      transfer_list_data

      [@data_array, @grand_total]
    end

    private

    def transfer_list_data
      @grand_total = 0
      @transfer_lists.each do |transfer_list|
        transfer = Inventory::Transaction::Transfer.find_by(id: transfer_list[:id])
        receive = Inventory::Transaction::Receive.find_by(id: transfer.receive_id)
        transfer_items = transfer.items
        next unless transfer_items.present?

        transfer_items.each do |item|
          transfer_date = transfer.transaction_time&.strftime('%d/%m/%Y  %I:%M%p')
          transfer_id = transfer.transfer_display_id
          receiving_store = transfer.receive_store_name&.titleize
          transferred_by = transfer.entered_by
          transfer_note = transfer.note || '--'
          status = transfer.status_text
          receive_status = transfer.receive_status_text
          received_on = receive&.transaction_date&.strftime('%d/%m/%Y') || '--'
          received_by = receive&.user_id.present? ? User.find(receive.user_id).fullname&.titleize : '--'
          description = item.description&.titleize
          custom_field_tags = item.custom_field_tags&.reject(&:blank?)&.join(', ')
          item_name = custom_field_tags.present? ? "#{description} (#{custom_field_tags})" : description
          code = item.variant_code
          category = item.category&.titleize
          batch = item.batch_no
          model_no = item.model_no
          qty = item.stock
          unit_cost = item.unit_cost&.round(2)
          total_cost = item.total_cost&.round(2)
          @grand_total += total_cost
          expiry = item.expiry&.strftime('%d/%m/%Y')
          @data_array << [
            transfer_date, transfer_id, receiving_store, transferred_by, transfer_note, status, receive_status,
            received_on, received_by, item_name, code, category, batch, model_no, expiry, qty, unit_cost, total_cost
          ]
        end
      end
    end

    def transfer_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]
      aggregation_query
    end

    def match_options
      options = { store_id: BSON::ObjectId(@transfer_params[:store_id]) }
      options = options.merge(user_id: BSON::ObjectId(@user_id)) if @user_id != 'all_user'
      options[:created_at] = { "$gte": @transfer_params[:start_date].utc, "$lte": @transfer_params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        transfer_lists: { "$push": { id: '$_id' } }
      }
    end
  end
end
