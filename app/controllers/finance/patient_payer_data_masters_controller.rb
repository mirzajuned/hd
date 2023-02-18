class Finance::PatientPayerDataMastersController < ApplicationController
  before_action :authorize
  before_action :fetch_patient_payer, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_patient_payers
  end

  def new
    fetch_users
    @finance_patient_payer = Finance::PatientPayerDataMaster.new
  end

  def create
    @finance_patient_payer = Finance::PatientPayerDataMaster.new(patient_payer_params)
    @finance_patient_payer.save!
    fetch_patient_payers
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @finance_patient_payer.update(patient_payer_params)
    fetch_patient_payers
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:finance_patient_payer_data_master][:name].to_s.strip.downcase

    if existing_name != name
      @finance_patient_payer = Finance::PatientPayerDataMaster.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@finance_patient_payer.try(:to_a).present? }
    end
  end

  def toggle_disable
    @finance_patient_payer.set(is_disable: params[:is_disable])
  end

  private

  def patient_payer_params
    params.require(:finance_patient_payer_data_master).permit(
        :name, :description, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable
    )
  end

  def fetch_patient_payer
    @finance_patient_payer = Finance::PatientPayerDataMaster.find_by(id: params[:id])
  end

  def fetch_patient_payers
    @finance_patient_payers = Finance::PatientPayerDataMaster.where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
