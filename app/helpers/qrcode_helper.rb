module QrcodeHelper
  require 'barby'
  require 'barby/barcode'
  require 'barby/barcode/qr_code'
  require 'barby/outputter/png_outputter'

  def render_qr_code text, size = 17
    return if text.to_s.empty?

    barcode = Barby::QrCode.new(text, level: :q, size: size)
    base64_output = Base64.encode64(barcode.to_png({ xdim: 5 }))
    "data:image/png;base64,#{base64_output}"
  end

  def make_qr_token
    SecureRandom.hex(10)
  end

  def facility_name(facility_id)
    name = Facility.find(facility_id).name
  end
end
