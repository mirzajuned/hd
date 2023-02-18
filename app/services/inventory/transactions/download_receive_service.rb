class Inventory::Transactions::DownloadReceiveService
  class << self
    def call(params, department_id, received_by)
      @received_by = received_by
      @receive_params = params
      @department_id = department_id
      @data_array = []
      receive_lists = Inventory::Transaction::Receive.collection.aggregate(receive_list_query).to_a[0] || {}
      @receive_lists = receive_lists[:receive_lists] || []
      receive_list_data

      [@data_array, @grand_total]
    end

    private

    def receive_list_data
      @grand_total = 0
      @receive_lists.each do |receive_list|
        receive = Inventory::Transaction::Receive.find_by(id: receive_list[:id])
        transfer = Inventory::Transaction::Transfer.find_by(id: receive.transfer_id)
        transfer_items = transfer.items
        next unless transfer_items.present?

        transfer_items.each do |item|
          received_on = receive.transaction_time&.strftime('%d/%m/%Y  %I:%M%p') || '--'
          transfer_id = transfer.transfer_display_id
          received_id = receive.receive_display_id
          transfer_store = receive.transfer_store_name
          received_by = receive.user_id.present? ? User.find(receive.user_id).fullname&.titleize : '--'
          note = transfer.note
          status = receive.status
          transfer_date = receive.transfer_date&.strftime('%d/%m/%Y')
          transfer_by = receive.transfer_user_name
          description = item.description&.titleize
          custom_field_tags = item.custom_field_tags&.reject(&:blank?)&.join(', ')
          item_name = custom_field_tags.present? ? "#{description} (#{custom_field_tags})" : description
          code = item.variant_code
          category = item.category&.titleize
          batch = item.batch_no
          model = item.model_no
          qty = item.stock
          unit_cost = item.unit_cost&.round(2)
          total_cost = item.total_cost&.round(2)
          @grand_total += total_cost
          expiry = item.expiry&.strftime('%d/%m/%Y')
          @data_array << [
            received_on, transfer_id, received_id, transfer_store, received_by, note, status, transfer_date, transfer_by, item_name,
            code, category, batch, model, expiry, qty, unit_cost, total_cost
          ]
        end
      end
    end

    def receive_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]
      aggregation_query
    end

    def match_options
      options = { store_id: BSON::ObjectId(@receive_params[:store_id]) }
      options = options.merge(status: 'Received') if @received_by == 'all_user'
      if @received_by != 'undefined' && @received_by != 'all_user'
        options = options.merge(user_id: BSON::ObjectId(@received_by))
      end
      options[:created_at] = { "$gte": @receive_params[:start_date].utc, "$lte": @receive_params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        receive_lists: { "$push": { id: '$_id' } }
      }
    end
  end
end
