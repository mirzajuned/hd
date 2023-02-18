class Inventory::Items::CreateService
  include Inventory::ItemsHelper
  def self.call(transaction_item_id, store_id)
    # category_model_type = params[:inventory_item][:category].singularize.titleize.camelize.gsub(' ', '::')
    transfer_store_item = Inventory::Item.find_by(id: transaction_item_id)

    item = Inventory::Item.new(
      transfer_store_item.attributes.except(
        :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at
      )
    )
    item.store_id = store_id
    item.save!
    item
  end
end
