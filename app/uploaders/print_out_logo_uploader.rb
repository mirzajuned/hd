class PrintOutLogoUploader < ApplicationAssetUploader
  storage :file
  def store_dir
    'patient-summary-assets'
  end
  # def scale(width, height)

  # end
  def filename
    original_filename
  end
end
