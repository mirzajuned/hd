json.array!(@optical_items) do |item|
  json.extract! item, :id, :item_code, :category, :description, :barcode, :checkoutable, :manufacturer
  case item.category
  when 'medication'
    json.extract! item, :dosage, :sub_units, :dispensing_unit, :inventory_capacity, :threshold, :stock, :packaging_type
    json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry
  when 'stockable'
    json.extract! item, :inventory_capacity, :threshold, :stock
    json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry
  when 'implant'
    json.extract! item, :inventory_capacity, :threshold, :stock
    json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry
  when 'consumable'
    json.extract! item, :inventory_capacity, :threshold, :stock, :packaging_type, :sub_units
    json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry
  when 'miscellaneous'
    json.extract! item, :inventory_capacity, :threshold, :stock
    json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :expiry
  when 'asset'
    json.extract! item, :price, :manufacturer, :vendor, :expiry, :warranty_expiry, :maintained_on, :maintainance_due
  when 'optical'
    json.extract! item, :stock, :item_type
    json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :list_price, :mrp, :mark_up, :vendor
    case item.item_type
    when 'contact'
      json.extract! item, :contact_type, :material, :replacement, :wearing_period, :power, :brand, :color, :gender, :pricing_index, :model_no
      json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :expiry
    when 'frame'
      json.extract! item, :reference_no, :brand, :color, :gender, :pricing_index, :model_no, :frame_type, :frame_material
      # :color_code, :label_color, :temple, :a, :b
    when 'other'
      json.extract! item, :threshold
      json.extract! item.lots.where('stock' => { '$gte' => 1 }, is_deleted: false).order_by('created_at asc').first, :expiry, :batch_no
    end
  end
  json.url inventory_item_url(item, format: :json)
end
