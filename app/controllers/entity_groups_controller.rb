class EntityGroupsController < ApplicationController
  before_action :authorize
  before_action :find_entity_group, only: [:show, :edit, :update, :destroy, :activate]
  before_action :form_params, only: [:new, :edit]
  before_action :set_entity_group, only: [:edit, :update, :destroy]

  def index
    # @entity_groups = EntityGroup.where(organisation_id: current_organisation['_id'])
    @entity_groups = EntityGroup.where(
                      organisation_id: current_organisation['_id']
                    ).order_by(country_id: :asc, name: :asc, is_active: :desc
                    ).group_by(&:country_id)
  end

  def data
    @entity_groups = EntityGroup.where(organisation_id: current_organisation['_id'])
    @all_entity_groups_count = @entity_groups.count
    # @found_entity_groups = @entity_groups.where(name: /#{Regexp.escape(params[:sSearch])}/i)
    # @entity_groups_count = @found_entity_groups.count
    # @entity_groups = @found_entity_groups.limit(params[:iDisplayLength])
    #                                .offset(params[:iDisplayStart])
    #                                .order('name ' + params[:sSortDir_0])
  end

  def new
    @entity_group = EntityGroup.new(organisation_id: current_organisation['_id'])
  end

  def create
    entity_group = EntityGroup.new(entity_group_params)
    if entity_group.save!
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'new'
    end
  end

  def edit; end

  def update
    if @entity_group.update(entity_group_params)
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'edit'
    end
  end

  def show; end

  def destroy
    @entity_group&.update_attributes(is_active: false)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def activate
    @entity_group&.update_attributes(is_active: true)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def validate_entity_group
    entity_group = params[:entity_group]
    if entity_group.present?
      if entity_group[:display_name].present?
        if params[:existing_display_name] != entity_group[:display_name]
          @entity_group = EntityGroup.find_by(display_name: entity_group[:display_name], organisation_id: params[:organisation_id])
        end
      end
      if entity_group[:abbreviation].present?
        if params[:existing_abbreviation] != entity_group[:abbreviation]
          @entity_group = EntityGroup.find_by(abbreviation: entity_group[:abbreviation], organisation_id: params[:organisation_id])
        end
      end
    end
    respond_to do |format|
      format.json { render json: !@entity_group.present? }
    end
  end

  private

  def form_params
    @countries = Country.all
  end
  # EOF form_params

  def entity_group_params
    params.require(:entity_group).permit(
      :name, :display_name, :abbreviation, :address, :city, :state, 
      :pincode, :commune, :district, :organisation_id, :country_id
    )
  end
  # EOF entity_group_params

  def set_entity_group
    @entity_group = EntityGroup.find_by(id: params[:id])
  end
  # EOF set_entity_group

  def find_entity_group
    @entity_group = EntityGroup.find_by(id: params[:id])
  end
  # EOF find_entity_group
end
