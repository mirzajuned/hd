require 'date'
require 'time'
require 'mime/types'
# require 'dicom'
# include DICOM
require 'RMagick'
require 'dicom'

class DicomrecordsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def upload_patient_asset
    @patient = Patient.find(params[:patientid])
    @investigation = Investigation::InvestigationDetail.find_by(id: params[:investigation_id])
    @type = params[:type]
    @specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])

    respond_to do |format|
      format.html { render layout: 'upload_files' }
    end
  end

  def save_uploaded_asset
    params[:patient_summary_asset_upload][:parent_id] = params[:patient_summary_asset_upload][:folder]
    params[:patient_summary_asset_upload][:parent_folder_id] = params[:patient_summary_asset_upload][:folder]
    params[:patient_summary_asset_upload][:original_filename] = params[:patient_summary_asset_upload][:asset_path].try(:original_filename)
    @patient_summary_asset = PatientSummaryAssetUpload.new(asset_upload_params)
    if @patient_summary_asset.save
      if params[:patient_summary_asset_upload][:comment].present?
        @patient_summary_asset.comments.create(comment_text: params[:patient_summary_asset_upload][:comment], created_by: current_user.id, upload_id: @patient_summary_asset.id, investigation_id: params[:patient_summary_asset_upload][:investigation_id])
      end

      @patient_summary_asset_upload = PatientSummaryAssetUpload.find_by(id: @patient_summary_asset.id)
      if @patient_summary_asset_upload.asset_path.file.exists?
        @patient_summary_asset_upload.update(upload_retry_counter: 0)
        render json: { 'success': true }
      else
        retry_image_upload(@patient_summary_asset_upload, params[:patient_summary_asset_upload][:asset_path], 1)
      end

      if @patient_summary_asset.extension == "dcm"
        DicomtojpgJob.perform_later(@patient_summary_asset.id.to_s)
      end
      PatientSummaryAssetUpload.compute_mongoid_for_tags(params[:patient_summary_asset_upload][:tagids], params[:patient_summary_asset_upload][:tagnames], @patient_summary_asset.specialty_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, @patient_summary_asset.id.to_s)
      # respond_to do |format|
      #   format.js {render "save_uploaded_asset", :layout => false}
      # end
    end
  end

  # def save_uploaded_asset_dropzone #*************************# not working*****************************
  #   @patient_summary_asset = PatientSummaryAssetUpload.new(asset_upload_params_dropzone)
  #   if @patient_summary_asset.save
  #     respond_to do |format|
  #       format.js {render "save_uploaded_asset", :layout => false}
  #     end
  #   end
  # end

  private

  def asset_upload_params
    params.require(:patient_summary_asset_upload).permit(:name, :patient_id, :parent_id, :specialty_id, :reported_date, :reported_time, :asset_path, :investigation_id, :type, :investigation_detail_id, :loinc_code, :parent_folder_id, :original_filename).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N")
  end

  def asset_upload_params_dropzone
    params.require(:patient_summary_asset_upload).permit(:name, :patient_id, :parent_id, :asset_path, :parent_folder_id).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N")
  end

  def retry_image_upload(psau, file, counter)
    psau.update(asset_path: file, upload_retry_counter: counter)
    if PatientSummaryAssetUpload.find_by(id: psau.id).asset_path.file.exists?
      render json: { 'success': true }
    else
      counter = counter + 1
      if counter <= 5
        retry_image_upload(psau, file, counter)
      else
        PatientSummaryAssetUpload.find_by(id: psau.id).destroy
        render json: { 'success': false }
      end
    end
  end
end
