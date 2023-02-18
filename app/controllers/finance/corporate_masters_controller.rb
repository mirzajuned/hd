class Finance::CorporateMastersController < ApplicationController
  before_action :authorize
  before_action :fetch_corporate, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_corporates
  end

  def new
    fetch_users
    @finance_corporate = Finance::CorporateMaster.new
  end

  def create
    @finance_corporate = Finance::CorporateMaster.new(corporate_params)
    @finance_corporate.save!
    fetch_corporates
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @finance_corporate.update(corporate_params)
    fetch_corporates
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:finance_corporate_master][:name].to_s.strip.downcase

    if existing_name != name
      @finance_corporate = Finance::CorporateMaster.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@finance_corporate.try(:to_a).present? }
    end
  end

  def toggle_disable
    @finance_corporate.set(is_disable: params[:is_disable])
  end

  private

  def corporate_params
    params.require(:finance_corporate_master).permit(
        :name, :description, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable
    )
  end

  def fetch_corporate
    @finance_corporate = Finance::CorporateMaster.find_by(id: params[:id])
  end

  def fetch_corporates
    @finance_corporates = Finance::CorporateMaster.where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
