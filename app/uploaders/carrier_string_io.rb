class CarrierStringIO < StringIO
  def original_filename
    # the real name does not matter
    "photo.png"
  end

  def content_type
    # this should reflect real content type, but for this example it's ok
    "image/png"
  end
end
