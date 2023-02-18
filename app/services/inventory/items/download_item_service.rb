class Inventory::Items::DownloadItemService
  class << self
    def call(store_id, stock, category)
      @data_array = []
      item_list_data(store_id, stock, category)

      @data_array
    end

    private

    def item_list_data(store_id, stock, category)
      options = { store_id: store_id }
      unless (category.include? 'all_item') || category.blank?
        options = options.merge(:category.in => [category].flatten)
      end
      if stock == 'out_stock'
        options = options.merge(empty: true)
      elsif stock == 'running_low'
        options = options.merge(running_low: true)
      end
      @items = Inventory::Item.where(options).is_active.order_by(created_at: 'desc')
      return if @items.empty?

      @items.each do |item|
        item_code = item[:item_code]
        category = item[:category]
        description = item[:description]
        model_no = item[:model_no] || 'NA'
        tax_rate = item[:tax_rate]
        stock = item[:stock]
        @data_array << [item_code, category, description, model_no, tax_rate, stock]
      end
    end
  end
end
