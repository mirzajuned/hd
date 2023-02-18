# INV-M-001
# Crocin (500) tablets
# 134678914144
# AV traders
class Inv
  attr_accessor :inventory_code, :category, :vendors, :tablets, :dosage, :dispensing_unit, :quantity, :stock, :barcode, :price, :mark_up
  def initialize
    @inventory_code = %w(M I S C)
    @category = %w(medication stockable implant consumable)
    @vendors = %w(Wheaton\ Industries Cascade\ TEK Labocon\ Systems\ Limited X\ RAY\ Supply Carr\ Corporation)
    @tablets = %w(Nexium Humira Crestor Advair\ Diskus Enbrel Remicade Cymbalta Copaxone Neulasta Lantus\ Solostar Rituxan Spiriva\ Handihaler Januvia Atripla Lantus Avastin Lyrica Oxycontin Epogen Celebrex Truvada Diovan Gleevec Herceptin Lucentis Namenda Vyvanse Zetia)
    @dosage = %w(500mg 250mg 100mg 300mg 1000mg 150mg)
    @dispensing_unit = %w(tablets pills syrup injection saline)
    @quantity = [2, 5, 10, 15, 20] # sample
    @stock = [50, 100, 150, 200, 250] # sample

    @barcode = 134678910000
    # rand(0...5)
    @price = [10, 20, 29, 30, 50, 100, 150, 160]
    @mark_up = [10, 15, 20, 30, 50]
  end

  # @mrp = [15, 25, 35, 38, 55, 115, 168, 180]
  # @list_price = [14, 23, 33, 35, 49, 110, 161, 170]
  # Time.at(rand(10000000..190000000) + Time.current.to_i)
  def create_items
    @tablets.each do |t|
      item = Inventory::Item.new({
                                   item_code: "INV-#{@inventory_code.sample}-#{rand(10..100)}",
                                   category: "#{@category.sample}",
                                   description: "#{t} #{@dosage.sample}",
                                   barcode: @barcode + rand(1000.9999),
                                   vendor: @vendors.sample,
                                   date_of_entry: Date.current.to_s,
                                   dosage: @dosage.sample,
                                   dispensing_unit: @dispensing_unit.sample,
                                   quantity: @quantity.sample,
                                   stock: @stock.sample,
                                   inventory_capacity: @stock.sample + 100,
                                   threshold: 20 + rand(1..10),
                                   price: @price.sample,
                                   mark_up: @mark_up.sample,
                                   expiry_date: Time.at(rand(10000000..190000000) + Time.current.to_i).to_s
                                 })
      item.mrp = item.price + 20
      item.list_price = item.price + 10
      item.save
    end
  end
end
