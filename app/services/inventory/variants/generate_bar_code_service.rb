class Inventory::Variants::GenerateBarCodeService
  require 'barby'
  require 'barby/barcode'
  require 'barby/outputter/png_outputter'
  require 'barby/barcode/code_128'

  class << self
    def call(variant_code, organisation_id)
      organisation_prefix = Organisation.find_by(id: organisation_id).try(:identifier_prefix)
      code = "#{organisation_prefix}-#{Time.current.strftime('%H:%M:%S')}-#{variant_code}"
      text = code.gsub!(/[^0-9A-Za-z]/, '')
      Barby::Code128B.new(text)
    end
  end
end
