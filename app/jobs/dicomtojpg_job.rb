require 'open-uri'
require 'dicom'
include DICOM
require 'rmagick'
include Magick

class DicomtojpgJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    # convert -limit memory 32 -limit map 64 input.tif -units PixelsPerInch -density 72 -quality 60 -resize 535 output.jpg
    @dicom_image = PatientSummaryAssetUpload.find_by(id: args[0])
    dcm_fileurl = @dicom_image.asset_path_url
    dcm_filename = dcm_fileurl.split('/').last
    IO.copy_stream(open(dcm_fileurl), Rails.root.to_s + '/public/uploads/tmp/' + dcm_filename)
    dcm_filepath = Rails.root.to_s + '/public/uploads/tmp/' + dcm_filename
    dcm = DObject.read(dcm_filepath)
    dcm_image = dcm.image

    filename = dcm_filename.split(".")
    jpg_filename = filename[0] + ".jpg"

    dcm_image.normalize.write(Rails.root.to_s + '/public/uploads/' + jpg_filename)
    jpg_filename_path = Rails.root.to_s + '/public/uploads/' + jpg_filename
    File.delete(Rails.root.to_s + '/public/uploads/tmp/' + dcm_filename)
    media = File.open(jpg_filename_path)
    # puts jpg_filename
    File.delete(Rails.root.to_s + '/public/uploads/' + jpg_filename) if File.exist?(Rails.root.to_s + '/public/uploads/' + jpg_filename)
    @dicom_image.update(asset_path: media, format: 'dicom')
  end
end
