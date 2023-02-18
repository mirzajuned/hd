require 'date'
require 'time'
require 'mime/types'
require 'open-uri'

class PaperrecordsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def upload
    @patient = Patient.find(params[:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def save
    @patient = Patient.find(paper_report_params[:patient_id])
    patientasset = Patientasset.new()
    patientasset.patient = @patient
    patientasset.extension = MIME::Types["#{paper_report_params[:reportfile].content_type}"].first.sub_type
    patientasset.assetpath.create_directory(patientasset.assetpath.set_store_dir("patients", "photos"))
    patientasset.patientassetid = _patientassetid
    patientasset.assetpath = paper_report_params[:reportfile]
    patientasset.contenttype = paper_report_params[:reportfile].content_type
    patientasset.assettype = MIME::Types["#{paper_report_params[:reportfile].content_type}"].first.media_type
    patientasset.assetextension = MIME::Types["#{paper_report_params[:reportfile].content_type}"].first.sub_type
    patientasset.reporteddate = paper_report_params[:reporteddate]
    patientasset.reportedtime = paper_report_params[:reportedtime]
    patientasset.patient_id = @patient.patientid
    patientasset.assetpath.store!(paper_report_params[:reportfile])
    if patientasset.save!
      respond_to do |format|
        format.js {}
      end
    end
  end

  def ai_evaluation;
  @patient = Patient.find_by(id: params[:patientid])
  end

  def evaluate_image
    file_name = params[:file_name]
    eye_image = params[:image]

    api_key = 'swkSTOEIXhKemrHSaGKmeIfH4oo12z'
    url = 'https://myhealth.co.bd/api/dr-prediction'

    require "uri"
    require "net/http"

    payload = {'api_key' => api_key,
              'file_name' => file_name,
              'eye_image' => eye_image
    }
    request = RestClient::Request.execute(method: :post, url: url, payload: payload, headers: { 'Content-Type' => 'application/json' })

    response = JSON.parse(request)["response"]

    if response.present? && response["code"] == "200"
      @evaluation_response = response
    end
  end

  def upload_patient_asset
    @record_id = params[:recordid]
    @patient = Patient.find(params[:patientid])
    @investigation = Investigation::InvestigationDetail.find_by(id: params[:investigation_id])
    @type = params[:type]
    @category = params[:category]
    @specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])

    respond_to do |format|
      format.html { render layout: 'upload_files' }
    end
  end

  def save_uploaded_asset
    if params[:patient_summary_asset_upload][:asset_path].present?
      params[:patient_summary_asset_upload][:parent_id] = params[:patient_summary_asset_upload][:folder]
      params[:patient_summary_asset_upload][:parent_folder_id] = params[:patient_summary_asset_upload][:folder]
      params[:patient_summary_asset_upload][:original_filename] = params[:patient_summary_asset_upload][:asset_path].original_filename
      @patient_summary_asset = PatientSummaryAssetUpload.new(asset_upload_params)
      if @patient_summary_asset.save
        if params[:patient_summary_asset_upload][:comment].present?
          @patient_summary_asset.comments.create(comment_text: params[:patient_summary_asset_upload][:comment], created_by: current_user.id, upload_id: @patient_summary_asset.id, investigation_id: params[:patient_summary_asset_upload][:investigation_id])
        end
        @patient_summary_asset.update(organisation_id: current_facility.organisation_id, facility_id: current_facility.id, user_id: current_user.id)
        PatientSummaryAssetUpload.compute_mongoid_for_tags(params[:patient_summary_asset_upload][:tagids], params[:patient_summary_asset_upload][:tagnames], @patient_summary_asset.specialty_id, current_user.organisation.id.to_s, current_user.id.to_s, @patient_summary_asset.id.to_s)

        # if params[:patient_summary_asset_upload][:folder] == '560cc6f72b2e26135d000008'
        #   @record_id = BSON::ObjectId.from_string(params[:patient_summary_asset_upload][:opdrecord_id])
        #   @assessment = PatientOphthalAssessment.find_by(:record_id => @record_id)
        #   @investigations = @assessment.ophthal_investigations
        #   new_investigation = []
        #   if investigation[:investigationname].to_s == params[:investigationName].to_s
        #     @investigations.each do |investigation|
        #       puts @patient_summary_asset.asset_path.url
        #       new_investigation = investigation
        #       new_investigation[:asset_path].push(@patient_summary_asset.asset_path.url)
        #     end
        #   end
        # end

        @patient_summary_asset_upload = PatientSummaryAssetUpload.find_by(id: @patient_summary_asset.id)
        if @patient_summary_asset_upload.asset_path.file.exists?
          @patient_summary_asset_upload.update(upload_retry_counter: 0)
          render json: { 'success': true }
        else
          retry_image_upload(@patient_summary_asset_upload, params[:patient_summary_asset_upload][:asset_path], 1)
        end

        # respond_to do |format|
        #   format.js {render "save_uploaded_asset", :layout => false}
        # end
        Patients::Summary::TimelineWorker.call({ event_name: "UPLOAD", sub_event_name: "ADDED", asset_id: @patient_summary_asset.id, user_id: current_user.id, user_name: current_user.fullname, facility_id: current_facility.id })
      end
    else
      head :ok
    end
  end

  def search_upload_tags
    @results_upload_tags = PatientAssetUploadTag.any_of(tag_name_lcase: /#{Regexp.escape(params[:q])}/i, :specialty_id.in => current_user.specialty_ids, :organisation_id.in => [nil, current_user.organisation_id.to_s], :is_custom.in => ["N", "Y"])
    respond_to do |format|
      format.json { render "result_upload_tags", :layout => false }
    end
  end

  def save_uploaded_asset_dropzone
    @patient_summary_asset = PatientSummaryAssetUpload.new(asset_upload_params_dropzone)
    if @patient_summary_asset.save
      respond_to do |format|
        format.js { render "save_uploaded_asset", :layout => false }
      end
    end
  end

  def edit
    @specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @asset = PatientSummaryAssetUpload.find_by(id: params[:id])
  end

  def update
    @asset = PatientSummaryAssetUpload.find_by(id: params[:id])
    @asset&.update_attributes(update_asset_upload_params)
    @patientfiles = PatientSummaryAssetUpload.where(:patient_id => @asset&.patient_id, is_deleted: false).order(:reported_date => :desc)
    respond_to do |format|
      format.js
    end

    PatientSummaryTimeline.where(event_name: "UPLOAD", query: { _id: params[:id].to_s }).delete_all
    Patients::Summary::TimelineWorker.call({ event_name: "UPLOAD", sub_event_name: "ADDED", asset_id: @asset&.id, user_id: current_user.id, user_name: current_user.fullname, facility_id: current_facility.id })
  end

  def destroy
    @asset = PatientSummaryAssetUpload.find_by(id: params[:id])
    # @asset.try(:delete)
    @asset.update!(is_deleted: true)
    @patientfiles = PatientSummaryAssetUpload.where(:patient_id => @asset.try(:patient_id), is_deleted: false).order(:reported_date => :desc)
    if @investigation == 'investigation'
      @image = PatientSummaryAssetUpload.where(opdrecord_id: params[:opdrecord_id], is_deleted: false).group_by { |x| x.name }
    end
    respond_to do |format|
      format.js
    end

    PatientSummaryTimeline.find_by(query: { _id: params[:id] }).try(:delete)
  end

  # Brakeman Solution: https://github.com/presidentbeef/brakeman/issues/337
  # As we're getting path from DB, this should not be considered as security threat
  def download_asset
    @asset = PatientSummaryAssetUpload.find_by(id: params[:id])
    file_url = @asset.asset_path_url
    # filename = file_url.split("/").last
    filename = @asset.asset_path.current_path.split("/").last
    download_filename = Rails.root.to_s + '/public/uploads/tmp/download_' + filename
    if Rails.env == 'development'
      send_file(
        @asset.asset_path.current_path,
        filename: filename,
        type: @asset.content_type
      )
    elsif ['stage', 'preprod', 'preproduction', 'production'].include?(Rails.env)
      IO.copy_stream(open(file_url), download_filename)
      send_file(
        download_filename,
        filename: filename,
        type: @asset.content_type
      )
    end
  end

  private

  def asset_upload_params
    params.require(:patient_summary_asset_upload).permit(:name, :patient_id, :parent_id, :specialty_id, :reported_date, :reported_time, :asset_path, :investigation_id, :type, :investigation_detail_id, :loinc_code, :parent_folder_id, :category, :opdrecord_id, :tagnames, :original_filename).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N")
  end

  def asset_upload_params_dropzone
    params.require(:patient_summary_asset_upload).permit(:name, :patient_id, :parent_id, :asset_path, :parent_folder_id).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N")
  end

  def update_asset_upload_params
    params.require(:patient_summary_asset_upload).permit(:name, :reported_date, :specialty_id, :reported_time, :parent_folder_id).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N")
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
