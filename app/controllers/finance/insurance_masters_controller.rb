class Finance::InsuranceMastersController < ApplicationController
  before_action :authorize
  before_action :fetch_insurance, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_insurances
  end

  def new
    fetch_users
    @finance_insurance = Finance::InsuranceMaster.new
  end

  def create
    @finance_insurance = Finance::InsuranceMaster.new(insurance_params)
    @finance_insurance.save!
    fetch_insurances
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @finance_insurance.update(insurance_params)
    fetch_insurances
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:finance_insurance_master][:name].to_s.strip.downcase

    if existing_name != name
      @finance_insurance = Finance::InsuranceMaster.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@finance_insurance.try(:to_a).present? }
    end
  end

  def toggle_disable
    @finance_insurance.set(is_disable: params[:is_disable])
  end

  private

  def insurance_params
    params.require(:finance_insurance_master).permit(
        :name, :description, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable
    )
  end

  def fetch_insurance
    @finance_insurance = Finance::InsuranceMaster.find_by(id: params[:id])
  end

  def fetch_insurances
    @finance_insurances = Finance::InsuranceMaster.where(organisation_id: current_organisation['_id'].to_s)
                                .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
