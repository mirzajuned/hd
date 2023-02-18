class CaseSheetsController < ApplicationController
  before_action :authorize_webview_session
  before_action :session_variables
  before_action :find_case_sheet, only: [:edit, :update, :get_case_sheet_details]
  before_action :find_patient, only: [:index, :new, :get_case_sheet_details]
  before_action :find_case_sheets, only: [:index, :new]

  layout "mobile_layout"

  def index
  end

  def new
    @case_sheet = CaseSheet.new
  end

  def create
    @case_sheet = CaseSheet::ChangeCaseService.call(params, current_user) if params[:case_selected].present?
  end

  def edit
    @patient = Patient.find_by(id: @case_sheet.patient_id)
  end

  def update
    unless @case_sheet.update(case_sheet_params)
      render 'edit'
    end
  end

  def get_case_sheet_details
  end

  private

  def session_variables
    @current_user = current_user
    @current_facility = current_facility
  end

  def case_sheet_params
    params.require(:case_sheet).permit(:case_name, :start_date)
  end

  def find_case_sheet
    @case_sheet = CaseSheet.find_by(id: params[:id]) || CaseSheet.new
  end

  def find_case_sheets
    @case_sheets = CaseSheet.where(patient_id: params[:patient_id]).order(start_date: :desc)
  end

  def find_patient
    @patient = Patient.find_by(id: params[:patient_id])
  end
end
