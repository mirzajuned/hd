class Inventory::Report::StockMovementReportService
  class << self
    def call(params)
      @store_id = params[:store_id]
      @data_array = []
      @params = params
      @daily_start_lots = Inventory::DailyLotStock.find_by(store_id: @store_id,
                                                           date: Date.parse(params[:start_date]) - 1.day)
      @end_date = Date.parse(params[:end_date])
      @start_date = Date.parse(params[:start_date])
      if @end_date == Date.current
        @lots = Inventory::Item::Lot.where(store_id: @store_id).order_by(created_at: 'desc')
        calculate_current_lot_movement
      else
        @daily_end_lot = Inventory::DailyLotStock.find_by(store_id: @store_id, date: params[:end_date])
        @daily_lot_stocks = Inventory::DailyLotStock.where(store_id: @store_id, date: @start_date..@end_date)
        calculate_lot_movement
      end
      @data_array
    end

    def calculate_lot_movement
      @total_in_out = []
      @daily_lot_stocks.each do |lot_stock|
        daily_lot_data = lot_stock.daily_lot_data
        daily_lot_data.each do |lot_data|
          @total_in_out << lot_data
        end
      end
      @data = @total_in_out.group_by(&:lot_id)
      @data.each_key do |key|
        lot = Inventory::Item::Lot.find_by(id: key)
        end_stock = if @daily_end_lot.present?
                      @daily_end_lot.daily_lot_data.find_by(lot_id: key).stock
                    else
                      lot.stock
                    end
        total_stock_in = @data[lot.id].pluck(:stock_in).compact.inject(:+) || 0
        total_stock_out = @data[lot.id].pluck(:stock_out).compact.inject(:+) || 0
        calculate_lot_movement_data(lot, total_stock_in, total_stock_out&.abs, end_stock)
      end
    end

    def calculate_current_lot_movement
      return unless @lots.present?

      @lots.each do |lot|
        stock_movement(lot.id, @store_id)
        stock_in = @audit_hash['In'] || 0
        stock_out = @audit_hash['Out']&.abs || 0
        calculate_lot_movement_data(lot, stock_in, stock_out, lot.stock)
      end
    end

    def calculate_lot_movement_data(lot, stock_in, stock_out, stock)
      lot_movement_data = {}
      description = lot.description
      lot_movement_data['lot_desc'] = description&.titleize
      custom_field_tags = lot.custom_field_tags&.reject(&:blank?)&.join(', ')
      variant = lot.custom_field_tags.present? ? "#{description} (#{custom_field_tags})" : description
      lot_movement_data['variant'] = variant
      lot_movement_data['category'] = lot.category&.titleize
      lot_movement_data['item_code'] = lot.variant_code
      lot_movement_data['batch_no'] = lot.batch_no || 'NA'
      lot_movement_data['model_no'] = lot.model_no || 'NA'
      list_price = lot.list_price&.round(2)
      lot_movement_data['cost_price'] = list_price
      start_lot_stock = stock + stock_out - stock_in
      lot_movement_data['opening_stock'] = start_lot_stock
      lot_movement_data['opening_value'] = start_lot_stock * list_price
      lot_movement_data['stock_in_qty'] = stock_in
      lot_movement_data['stock_in_val'] = stock_in * list_price
      lot_movement_data['stock_out_qty'] = stock_out
      lot_movement_data['stock_out_val'] = stock_out * list_price
      lot_movement_data['stock_end_qty'] = stock
      lot_movement_data['stock_end_val'] = stock * list_price
      @data_array << lot_movement_data
    end

    private

    def stock_movement(lot_id, store_id)
      audit_histories = Inventory::Audit::History.where(lot_id: lot_id, transaction_date: @start_date..@end_date,
                                                        store_id: store_id).pluck(:flow, :stock_value)
      @audit_hash = audit_histories.each_with_object(Hash.new(0)) { |(k, v), memo| memo[k] += v }
    end
  end
end
