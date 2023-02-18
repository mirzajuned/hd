class Finance::DispensaryMastersController < ApplicationController
  before_action :authorize
  before_action :fetch_dispensary, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_dispensaries
  end

  def new
    fetch_users
    @finance_dispensary = Finance::DispensaryMaster.new
  end

  def create
    @finance_dispensary = Finance::DispensaryMaster.new(dispensary_params)
    @finance_dispensary.save!
    fetch_dispensaries
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @finance_dispensary.update(dispensary_params)
    fetch_dispensaries
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:finance_dispensary_master][:name].to_s.strip.downcase

    if existing_name != name
      @finance_dispensary = Finance::DispensaryMaster.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@finance_dispensary.try(:to_a).present? }
    end
  end

  def toggle_disable
    @finance_dispensary.set(is_disable: params[:is_disable])
  end

  private

  def dispensary_params
    params.require(:finance_dispensary_master).permit(
        :name, :description, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable
    )
  end

  def fetch_dispensary
    @finance_dispensary = Finance::DispensaryMaster.find_by(id: params[:id])
  end

  def fetch_dispensaries
    @finance_dispensaries = Finance::DispensaryMaster.where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
