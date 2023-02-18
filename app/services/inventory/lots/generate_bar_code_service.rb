class Inventory::Lots::GenerateBarCodeService
  require 'barby'
  require 'barby/barcode'
  require 'barby/outputter/png_outputter'
  require 'barby/barcode/code_128'

  class << self
    def default(item_code, organisation_id)
      organisation_prefix = Organisation.find_by(id: organisation_id).identifier_prefix
      code = "#{organisation_prefix}-#{Time.current.strftime('%H:%M:%S')}-#{item_code}"
      text = code.gsub!(/[^0-9A-Za-z]/, '')
      Barby::Code128B.new(text)
    end

    def call(code)
      data = code.gsub!(/[^0-9A-Za-z]/, '') || code
      Barby::Code128B.new(data)
    end
  end
end
