class Finance::PanelMastersController < ApplicationController
  before_action :authorize
  before_action :fetch_panel, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_panels
  end

  def new
    fetch_users
    fetch_dispensaries
    @finance_panel = Finance::PanelMaster.new
  end

  def create
    @finance_panel = Finance::PanelMaster.new(panel_params)
    @finance_panel.save!
    fetch_panels
  end

  def show; end

  def edit
    fetch_users
    fetch_dispensaries
  end

  def update
    @finance_panel.update(panel_params)
    fetch_panels
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:finance_panel_master][:name].to_s.strip.downcase

    if existing_name != name
      @finance_panel = Finance::PanelMaster.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@finance_panel.try(:to_a).present? }
    end
  end

  def toggle_disable
    @finance_panel.set(is_disable: params[:is_disable])
  end

  private

  def panel_params
    params.require(:finance_panel_master).permit(
        :name, :description, :dispensary_master_id, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable
    )
  end

  def fetch_panel
    @finance_panel = Finance::PanelMaster.find_by(id: params[:id])
  end

  def fetch_panels
    @finance_panels = Finance::PanelMaster.includes(:dispensary_master).where(organisation_id: current_organisation['_id'].to_s)
                              .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end

  def fetch_dispensaries
    @finance_dispensaries = Finance::DispensaryMaster.where(organisation_id: current_organisation['_id'].to_s)
                                .order_by(name: :asc)
  end
end
