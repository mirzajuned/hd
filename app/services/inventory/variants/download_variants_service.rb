class Inventory::Variants::DownloadVariantsService
  class << self
    def call(store_id, stock, category)
      @data_array = []
      variant_list_data(store_id, stock, category)

      @data_array
    end

    private

    def variant_list_data(store_id, stock, category)
      options = { store_id: store_id }
      unless (category.include? 'all_item') || category.blank?
        options = options.merge(:category.in => [category].flatten)
      end
      if stock == 'out_stock'
        options = options.merge(empty: true)
      elsif stock == 'running_low'
        options = options.merge(running_low: true)
      end
      @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc')
      return if @variants.empty?

      @variants.each do |variant|
        variant_code = variant[:variant_code]
        custom_field = variant[:custom_field_tags]&.reject(&:blank?)&.join(',')
        description = if custom_field.present?
                        variant[:description] + ' (' + custom_field + ')'
                      else
                        variant[:description]
                      end
        stock = variant[:stock]
        category = variant[:category]
        model_no = variant[:model_no] || 'NA'
        @data_array << [variant_code, description, model_no, stock, category]
      end
    end
  end
end
