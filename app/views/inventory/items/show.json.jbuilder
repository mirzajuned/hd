# not in use anymore

json.extract! @inventory_item, :id, :item_code, :category, :description, :barcode, :checkoutable, :manufacturer
case @inventory_item.category
when 'medication'
  json.extract! @inventory_item, :dosage, :sub_units, :dispensing_unit, :inventory_capacity, :threshold, :stock, :packaging_type
  json.extract! @inventory_item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry
when 'stockable'
  json.extract! @inventory_item, :inventory_capacity, :threshold, :stock
  json.extract! @inventory_item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry
when 'implant'
  json.extract! @inventory_item, :inventory_capacity, :threshold, :stock
  json.extract! @inventory_item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry
when 'consumable'
  json.extract! @inventory_item, :inventory_capacity, :threshold, :stock, :packaging_type, :sub_units
  json.extract! @inventory_item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry
when 'miscellaneous'
  json.extract! @inventory_item, :inventory_capacity, :threshold, :stock
  json.extract! @inventory_item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry
when 'asset'
  json.extract! @inventory_item, :price, :vendor, :expiry, :warranty_expiry, :maintained_on, :maintainance_due, :condition
when 'optical'
  json.extract! @inventory_item, :stock, :item_type
  json.extract! @inventory_item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).first, :list_price, :mrp, :mark_up, :vendor
  case @inventory_item.item_type
  when 'contact'
    json.extract! @inventory_item, :contact_type, :material, :brand, :color, :gender, :pricing_index, :model_no
  when 'frame'
    json.extract! @inventory_item, :reference_no, :frame_type, :frame_material
    # :color_code, :label_color, :temple, :a, :b
  when 'other'
    json.extract! @inventory_item, :threshold
  end
end

json.url inventory_item_url(@inventory_item, format: :json)
