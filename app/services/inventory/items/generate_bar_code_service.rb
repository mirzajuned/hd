class Inventory::Items::GenerateBarCodeService
  require 'barby'
  require 'barby/barcode'
  require 'barby/outputter/png_outputter'
  require 'barby/barcode/code_128'

  class << self
    def call(item_code, facility_id)
      organisation_prefix = Facility.find_by(id: facility_id).organisation.identifier_prefix
      code = "#{organisation_prefix}-#{Time.current.strftime('%H:%M:%S')}-#{item_code}"
      text = code.gsub!(/[^0-9A-Za-z]/, '')
      Barby::Code128B.new(text)
    end
  end
end
