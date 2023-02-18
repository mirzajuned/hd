module Inventory::BarcodeHelper
   require 'barby'
   require 'barby/barcode/qr_code'
   require 'barby/outputter/svg_outputter'
   require 'barby/barcode/code_128'
   require 'barby/barcode'
   require 'barby/outputter/png_outputter'

	def get_barcode(organisation_id, item_code)
   organisation_prefix = Organisation.find_by(id: organisation_id).identifier_prefix
   code = "#{organisation_prefix}-#{Time.current.strftime('%H:%M:%S')}-#{item_code}"
   text = code.gsub!(/[^0-9A-Za-z]/, '')

   barcode = Barby::Code128B.new("#{text}")

   barcode.to_svg(xdim:1, height:40)
  end
end