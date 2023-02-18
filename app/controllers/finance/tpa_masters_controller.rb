class Finance::TpaMastersController < ApplicationController
  before_action :authorize
  before_action :fetch_tpa, only: [:edit, :update, :show, :toggle_disable, :edit_corporate_detail]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_tpas
  end

  def new
    fetch_users
    fetch_corporates
    fetch_insurances
    @finance_tpa = Finance::TpaMaster.new
  end

  def create
    @finance_tpa = Finance::TpaMaster.new(tpa_params)
    @finance_tpa.save!
    fetch_tpas
  end

  def show; end

  def edit
    fetch_corporates
    fetch_insurances
    fetch_users
  end

  def update
    @finance_tpa.update(tpa_params)
    fetch_tpas
  end

  def destroy; end

  def edit_corporate_detail
    fetch_corporates
    fetch_insurances
    @corporate_details = @finance_tpa&.corporate_details
  end

  def add_corporate_detail
    @finance_tpa = Finance::TpaMaster.build
    fetch_corporates
    fetch_insurances
  end

  # def save_corporate_detail
  #   @item = Inventory::Item.build
  # end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:finance_tpa_master][:name].to_s.strip.downcase

    if existing_name != name
      @finance_tpa = Finance::TpaMaster.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@finance_tpa.try(:to_a).present? }
    end
  end

  def toggle_disable
    @finance_tpa.set(is_disable: params[:is_disable])
  end

  private

  def tpa_params
    params.require(:finance_tpa_master).permit(
        :name, :description, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable,
        corporate_details_attributes: [:insurance_master_id, :insurance_master_name, :corporate_master_id,
                                       :corporate_master_name, :id, :_destroy]
    )
  end

  def fetch_tpa
    @finance_tpa = Finance::TpaMaster.find_by(id: params[:id])
  end

  def fetch_tpas
    @finance_tpas = Finance::TpaMaster.where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_insurances
    @finance_insurances = Finance::InsuranceMaster.where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_corporates
    @finance_corporates = Finance::CorporateMaster.where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
