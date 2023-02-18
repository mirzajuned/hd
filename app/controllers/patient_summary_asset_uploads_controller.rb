class PatientSummaryAssetUploadsController < ApplicationController
  # ***************************************************************
  #   only new method is there
  # ***************************************************************

  before_action :authorize

  def new
    @path = 'paperrecords_save_uploaded_asset_path(format: :json)'
    @investigation_detail = Investigation::InvestigationDetail.find_by(id: params[:investigation_id])
    @patient = Patient.find_by(id: @investigation_detail.patient_id)
    @type = @investigation_detail._type.split("::")[1].downcase
    get_investigation_type_id
    @category = params[:category]
    @patient_summary_asset_upload = PatientSummaryAssetUpload.new
    respond_to do |format|
      format.html { render layout: 'upload_files' }
    end
  end

  def new_dicom_upload
    @path = 'dicomrecords_save_uploaded_asset_path(format: :json)'
    @investigation_detail = Investigation::InvestigationDetail.find_by(id: params[:investigation_id])
    @patient = Patient.find_by(id: @investigation_detail.patient_id)
    @type = @investigation_detail._type.split("::")[1].downcase
    get_investigation_type_id
    @category = params[:category]
    @patient_summary_asset_upload = PatientSummaryAssetUpload.new
    respond_to do |format|
      format.html { render layout: 'upload_files' }
    end
  end

  private

  def get_investigation_type_id
    if @type == 'ophthal'
      @type_id = '560cc6f72b2e26135d000008'
    elsif @type == 'radiology'
      @type_id = '560cc6f72b2e26135d000001'
    elsif @type == 'laboratory'
      @type_id = '560cc6f72b2e26135d000002'
    end
  end
end
