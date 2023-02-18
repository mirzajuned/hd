# encoding: utf-8

class PatientSummaryUploader < ApplicationAssetUploader
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if @model.uploaded_via_backend == "Y"
      @model.store_directory
    else
      'patient-summary-assets'
    end
  end
  process :set_custom_fields

  def set_custom_fields
    model.content_type = file.content_type if file.content_type
    model.asset_type = MIME::Types[file.content_type].first.media_type if file.content_type
    model.extension = file.extension if file.extension
    model.file_size = file.size
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :thumb, :if => :is_thumbable? do
    process :resize_to_fit => [110, 110]
  end
  version :api_thumb, :if => :is_thumbable? do
    process :resize_to_fit => [60, 60]
  end

  # process :convert_and_scale
  process :convert => :jpg, :if => :is_tiff?
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    if @model.uploaded_via_backend == "Y"
      "#{@model.name}"
    elsif (@model.diagram_type == nil || @model.diagram_type == "") && @model.uploaded_via_backend != "Y"
      "#{@model.id}_#{@model.patient.id}_photo_#{Date.current.strftime('%Y%m%d')}_#{Time.current.strftime('%H%M%S')}.#{file.extension}" if original_filename
    else
      "Patient_#{@model.diagram_type}_#{Date.current.strftime('%Y%m%d')}_#{Time.current.strftime('%H%M%S')}.png" if original_filename
    end
  end

  protected

  def is_thumbable?(file)
    file.content_type.include? 'image'
  end

  def is_tiff?(file)
    file.content_type.include? 'tiff'
  end
end
