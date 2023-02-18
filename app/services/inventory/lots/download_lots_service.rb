class Inventory::Lots::DownloadLotsService
  class << self
    def call(params)
      @store_id = params[:store_id]
      @end_date = params[:end_date]
      @data_array = []
      lot_list_data(@store_id, @end_date)

      [@data_array, @total_purchase_value, @total_selling_value]
    end

    private

    def lot_list_data(store_id, end_date)
      @total_purchase_value = 0
      @total_selling_value = 0
      stock_data = if Date.parse(end_date) == Date.current
                     Inventory::Item::Lot.where(store_id: store_id)
                   else
                     daily_lot_stock = Inventory::DailyLotStock.find_by(date: end_date, store_id: store_id)
                     daily_lot_stock.daily_lot_data if daily_lot_stock.present?
                   end

      return unless stock_data.present?

      stock_data.each do |data|
        item_name = data.description&.titleize
        batch_no = data.batch_no || 'NA'
        model_no = data.model_no || 'NA'
        stock = data.stock
        unit_cost = data.unit_cost || 0
        total_unit_cost = stock * unit_cost
        list_price = data.list_price || 0
        total_list_price = stock * list_price
        margin = total_list_price - total_unit_cost
        @total_purchase_value += unit_cost * stock
        @total_selling_value += list_price * stock

        @data_array << [item_name, batch_no, model_no, stock, unit_cost&.round(2), total_unit_cost&.round(2),
                        list_price&.round(2), total_list_price&.round(2), margin&.round(2)]
      end
    end
  end
end
