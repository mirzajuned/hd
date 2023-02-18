require 'fileutils'
require 'carrierwave/processing/rmagick'
require 'carrierwave/processing/mini_magick'

class ApplicationAssetUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # include CarrierWave::MimeTypes

  # include CarrierWave::MimeTypes

  attr_accessor :asset_directory_path, :extension
  # process :set_content_type

  # Choose what kind of storage to use for this uploader:
  # if Rails.env.development? || Rails.env.test? || ['cicd1', 'cicd2', 'cicd3'].include?(Rails.env)
  if Rails.env.test? || ['development', 'cicd1', 'cicd2', 'cicd3'].include?(Rails.env)
    storage :file
  else
    storage :fog
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    @asset_directory_path
  end

  def set_store_dir(folder, assetname)
    # folder = respond_to?(:asset_uploader_folder) ? asset_uploader_folder(folder, assetname) : model.class.to_s.underscore
    @asset_directory_path = _base_upload_dir
  end

  def create_directory(directory)
    _make_directory(directory)
  end

  def create_asset_directories
    directories = ["photos", "audios", "videos"]
    directories.each do |directory|
      FileUtils.mkdir_p("#{@rootpath}#{@folder}/#{@patientid}/#{directory}")
    end
  end

  private

  def _base_upload_dir
    (Rails.root + "app/assets/patients").to_s
  end

  def _make_directory(path)
    FileUtils.mkdir_p(path)
  end
end
