class RegionMastersController < ApplicationController
  before_action :authorize
  before_action :form_params, only: [:new, :edit]
  before_action :set_region_master, only: [:edit, :update, :destroy, :enable_region]

  def index
    @region_masters = RegionMaster.where(
                        organisation_id: current_organisation['_id']
                      ).order_by(country_id: :asc, name: :asc, is_active: :desc
                      ).group_by(&:country_id)
  end

  def new
    @region_master = RegionMaster.new(
                      organisation_id: current_organisation['_id'],
                      country_id: current_facility['country_id']
                    )
  end

  def create
    region_master = RegionMaster.new(region_master_params)
    if region_master.save!
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
      SequenceManagers::UpdateSequenceService.call('region', region_master.id.to_s)
    else
      render 'new'
    end
  end

  def edit; end

  def update
    if @region_master.update(region_master_params)
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
      SequenceManagers::UpdateSequenceService.call('region', @region_master.id.to_s)
    else
      render 'edit'
    end
  end

  def destroy
    @region_master&.update_attributes(is_active: false)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def enable_region
    @region_master&.update_attributes(is_active: true)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
    SequenceManagers::UpdateSequenceService.call('region', @region_master.id.to_s)
  end

  def validate_region_master
    region_master = params[:region_master]
    if region_master.present?
      if region_master[:name].present?
        if params[:existing_name] != region_master[:name]
          @region_master = RegionMaster.find_by(name: region_master[:name], organisation_id: params[:organisation_id])
        end
      end
      if region_master[:abbreviation].present?
        if params[:existing_abbreviation] != region_master[:abbreviation]
          @region_master = RegionMaster.find_by(abbreviation: region_master[:abbreviation], organisation_id: params[:organisation_id])
        end
      end
    end
    respond_to do |format|
      format.json { render json: !@region_master.present? }
    end
  end

  private

  def form_params
    @countries = Country.all
  end
  # EOF form_params

  def region_master_params
    params.require(:region_master).permit(
      :organisation_id, :name, :abbreviation, :country_id
    )
  end
  # EOF region_master_params

  def set_region_master
    @region_master = RegionMaster.find_by(id: params[:id])
  end
  # EOF set_region_master
end
