class Inventory::Transactions::DownloadAdjustmentService
  class << self
    def call(params, _department_id, user_id)
      @params = params
      @user_id = user_id
      @data_array = []
      adjustment_lists = Inventory::Transaction::Adjustment.collection.aggregate(adjustment_list_query).to_a[0] || {}
      @adjustment_lists = adjustment_lists[:adjustment_lists] || []
      adjustment_list_data

      @data_array
    end

    private

    def adjustment_list_data
      @adjustment_lists.each do |adjustment_list|
        adjustment = Inventory::Transaction::Adjustment.find_by(id: adjustment_list[:id])
        adjustment_items = adjustment.items
        next unless adjustment_items.present?

        adjustment_items.each do |item|
          transaction_date = adjustment.created_at&.strftime('%d/%m/%Y  %I:%M%p') || '--'
          adjustment_id = adjustment.adjustment_display_id
          user = adjustment.entered_by
          note = adjustment.note
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
          expiry = item.expiry&.strftime('%d/%m/%Y')
          @data_array << [transaction_date, adjustment_id, user, note, item_name, code, category, batch, model_no,
                          expiry, qty, unit_cost, total_cost]
        end
      end
    end

    def adjustment_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]

      aggregation_query
    end

    def match_options
      options = { store_id: BSON::ObjectId(@params[:store_id]) }
      options = options.merge(user_id: BSON::ObjectId(@user_id)) if @user_id != 'all_user'
      options[:created_at] = { "$gte": @params[:start_date].utc, "$lte": @params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        adjustment_lists: { "$push": { id: '$_id' } }
      }
    end
  end
end
