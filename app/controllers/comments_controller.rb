class CommentsController < ApplicationController
  before_action :authorize
  before_action :set_patient_asset, only: [:new, :show, :edit, :update, :destroy]
  def index
    @comments = @patient_asset.comments
  end

  # def new
  #   @comment = @patient_asset.comments.new
  #   respond_to do |format|
  #     format.js {}
  #   end
  # end

  def show
  end

  def edit
    @comment = @patient_asset.comments.find_by(id: params[:id])
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @patient_asset = PatientSummaryAssetUpload.find_by(id: params[:comment][:upload_id])
    @comment = @patient_asset.comments.create(comment_params)
    @tags = PatientAssetUploadTag.where(patient_summary_asset_upload_id: @patient_asset.id)
    @all_comments = @patient_asset.comments.where(is_deleted: false)
  end

  def update
    @patient_asset = PatientSummaryAssetUpload.find_by(id: params[:comment][:upload_id])
    @comment = @patient_asset.comments.find_by(id: params[:id])
    @comment.update(update_comment_params)
    @tags = PatientAssetUploadTag.where(patient_summary_asset_upload_id: @patient_asset.id)
    @all_comments = @patient_asset.comments.where(is_deleted: false)
  end

  def destroy
    @comment = @patient_asset.comments.find_by(id: params[:id])
    @comment.update(is_deleted: true)
    @all_comments = @patient_asset.comments.where(is_deleted: false)
    respond_to do |format|
      format.js {}
    end
  end

  private

  def set_patient_asset
    @patient_asset = PatientSummaryAssetUpload.find_by(id: params[:upload_id])
  end

  def update_comment_params
    params.require(:comment).permit(:comment_text)
  end

  def comment_params
    params.require(:comment).permit(:comment_text, :upload_id, :investigation_id, :created_by)
  end
end
