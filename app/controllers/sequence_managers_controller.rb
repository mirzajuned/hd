class SequenceManagersController < ApplicationController
  before_action :authorize
  before_action :sequence_manager, only: [:edit, :update, :disable_toggle]
  before_action :default_vals, only: [:new, :edit]
  # before_action :sequence_manager, only: [:create, :edit, :update, :disable_toggle]
  before_action :update_default_vals, only: [:edit]
  respond_to :js, :json, :html
  layout 'loggedin'

  def index
    current_entity_group = EntityGroup.find_by(organisation_id: current_organisation['_id'], country_id: current_facility.country_id, is_active:  true)
    @entity_group_id = current_entity_group.try(:id)
    @sequence_managers = SequenceManager.where(
      :facility_id.in => [nil, current_facility.id],
      :region_id.in => [nil, current_facility.region_master_id],
      :entity_group_id.in => [nil, @entity_group_id],
      organisation_id: current_organisation['_id'], is_deleted: false
    ).order_by(module_name: :asc, department_order: :asc, is_active: :desc, is_primary: :desc
    ).group_by(&:module_name)
  end

  def new
    department_id = params['department_id']
    @sequence_manager = SequenceManager.new
    @sequence_manager.module_name = @module_name
    @sequence_manager.department_id = department_id
    @sequence_manager.display_name = Global.sequence_manager.module_details[@module_name]['display_name']
    if @module_name == 'sales_order'
      @sequence_manager.organisation_counter = 1000001
    else
      @sequence_manager.organisation_counter = current_organisation.send("#{Global.sequence_manager.module_details[@module_name]['organisation_module']}_counter")
    end
    @facility_details = @current_organisation&.facilities.where(:id.ne => current_facility.id, is_active: true).map{|facility| ["#{facility.id.to_s}", 'name': facility.try(:name), 'prefix': facility.try(:abbreviation), 'abbreviation': facility.try(:abbreviation)]}.to_h
    @entity_group_details = @entity_groups.where(:id.ne => @current_entity_group.try(:id)).map{|entity_group| ["#{entity_group.id.to_s}", 'name': entity_group.name, 'prefix': entity_group.abbreviation, 'abbreviation': entity_group.abbreviation ]}.to_h
    @region_details = @region_masters.where(:id.ne => @current_region.try(:id)).map{|region| ["#{region.id.to_s}", 'name': region.name, 'prefix': region.abbreviation, 'abbreviation': region.abbreviation ]}.to_h
  end

  def create
    extra_info = {}
    if sequence_manager_params['facility_details'].present?
      extra_info['facility_details'] = sequence_manager_params['facility_details'].to_h
      sequence_manager_params.except(:facility_details)
    end
    if sequence_manager_params['region_details'].present?
      extra_info['region_details'] = sequence_manager_params['region_details'].to_h
      sequence_manager_params.except(:region_details)
    end
    if sequence_manager_params['entity_group_details'].present?
      extra_info['entity_group_details'] = sequence_manager_params['entity_group_details'].to_h
      sequence_manager_params.except(:entity_group_details)
    end
    if params[:sequence_manager][:department_id].present?
      params[:sequence_manager][:department_name], params[:sequence_manager][:department_abbreviation], params[:sequence_manager][:department_order] = department_details(sequence_manager_params[:department_id])
    end
    @sequence_manager = SequenceManager.new(sequence_manager_params)
    if @sequence_manager.save
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
      SequenceManagerJobs::ManageJob.perform_later(@sequence_manager.id.to_s, extra_info)
    else
      default_vals
      render 'new'
    end
  end

  def edit
    all_but_current_facilities = @current_organisation&.facilities.where(:id.ne => current_facility.id, is_active: true).pluck(:id)
    facility_sequences = SequenceManager.where(:facility_id.in => all_but_current_facilities, organisation_id: @current_organisation.id, counter_level: 'facility', module_name: @sequence_manager.module_name, is_deleted: false)
    if facility_sequences.count > 0
      @facility_details = facility_sequences.map{|facility| ["#{facility.facility_id.to_s}", 'name': facility.facility_name, 'prefix': facility.facility_abbreviation, 'abbreviation': facility.facility_abbreviation, 'original_counter': facility.original_counter, 'current_counter': facility.current_counter]}.to_h
    else
      @facility_details = @current_organisation&.facilities.where(:id.ne => current_facility.id, is_active: true).map{|facility| ["#{facility.id.to_s}", 'name': facility.try(:name), 'prefix': facility.try(:abbreviation), 'abbreviation': facility.try(:abbreviation)]}.to_h
    end
    # EOF facilities details

    # region details
    all_but_current_regions = @region_masters.where(:id.ne => @current_region.try(:id)).pluck(:id)
    region_sequences = SequenceManager.where(:region_id.in => all_but_current_regions, organisation_id: @current_organisation.id, counter_level: 'region', module_name: @sequence_manager.module_name, is_deleted: false)
    if region_sequences.count > 0
      @region_details = region_sequences.map{|region| ["#{region.region_id.to_s}", 'name': region.region_name, 'prefix': region.region_abbreviation, 'abbreviation': region.region_abbreviation, 'original_counter': region.original_counter, 'current_counter': region.current_counter]}.to_h
    else
      @region_details = @region_masters.where(:id.ne => @current_region.try(:id)).map{|region| ["#{region.id.to_s}", 'name': region.name, 'prefix': region.abbreviation, 'abbreviation': region.abbreviation ]}.to_h
    end
    # EOF region details
    # entity_group details
    all_but_current_entity_groups = @entity_groups.where(:id.ne => @current_entity_group.try(:id)).pluck(:id)
    entity_group_sequences = SequenceManager.where(:entity_group_id.in => all_but_current_entity_groups, organisation_id: @current_organisation.id, counter_level: 'entity_group', module_name: @sequence_manager.module_name, is_deleted: false)
    if entity_group_sequences.count > 0
      @entity_group_details = entity_group_sequences.map{|entity_group| ["#{entity_group.entity_group_id.to_s}", 'name': entity_group.entity_group_name, 'prefix': entity_group.entity_group_abbreviation, 'abbreviation': entity_group.entity_group_abbreviation, 'original_counter': entity_group.original_counter, 'current_counter': entity_group.current_counter]}.to_h
    else
      @entity_group_details = @entity_groups.where(:id.ne => @current_entity_group.try(:id)).map{|entity_group| ["#{entity_group.id.to_s}", 'name': entity_group.name, 'prefix': entity_group.abbreviation, 'abbreviation': entity_group.abbreviation ]}.to_h
    end
    # EOF entity_group details
  end

  def update
    extra_info = {}
    if sequence_manager_params['facility_details'].present?
      extra_info['facility_details'] = sequence_manager_params['facility_details'].to_h
      sequence_manager_params.except(:facility_details)
    end
    if sequence_manager_params['region_details'].present?
      extra_info['region_details'] = sequence_manager_params['region_details'].to_h
      sequence_manager_params.except(:region_details)
    end
    if sequence_manager_params['entity_group_details'].present?
      extra_info['entity_group_details'] = sequence_manager_params['entity_group_details'].to_h
      sequence_manager_params.except(:entity_group_details)
    end
    if params[:sequence_manager][:department_id].present?
      params[:sequence_manager][:department_name], params[:sequence_manager][:department_abbreviation], params[:sequence_manager][:department_order] = department_details(sequence_manager_params[:department_id])
    end
    extra_info['old_counter_level'] = @sequence_manager.counter_level
    if @sequence_manager.update(sequence_manager_params)
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
      SequenceManagerJobs::ManageJob.perform_later(@sequence_manager.id.to_s, extra_info)
    else
      default_vals
      render 'edit'
    end
  end

  def show; end

  def validate_sequence_manager
    sequence_manager_id = params['sequence_manager_id']
    organisation_id = params['organisation_id']
    department_id = (params['department_id'].present?) ? params['department_id'] : nil
    counter_level = params['counter_level']
    module_name = params['module_name']
    sequences = SequenceManager.where(organisation_id: organisation_id, department_id: department_id, counter_level: counter_level, module_name: module_name, is_deleted: false).pluck(:id).map(&:to_s)
    is_exist = (sequences.count > 0 && sequences.exclude?(sequence_manager_id)) || false
    respond_to do |format|
      format.json { render json: !is_exist.to_bool }
    end
  end
  # EOF validate_sequence_manager

  def generate_sequence
    params.permit(:ajax); ajax_params = params[:ajax]
    sequence_manager_id = ajax_params['sequence_manager_id']
    organisation_id = ajax_params['organisation_id']
    facility_id = ajax_params['facility_id']
    new_sequence = ajax_params['sequence_string']
    date_format = ajax_params['date_format']
    year_format = ajax_params['year_format']
    reset_month = ajax_params['reset_month']
    sequence_preview = SequenceManager::GenerateSequenceHelper.preview_sequence(sequence_manager_id, new_sequence, {organisation_id: organisation_id, facility_id: facility_id, date_format: date_format, year_format: year_format, reset_month: reset_month})
    respond_to do |format|
      format.json { render json: { sequence_preview: sequence_preview } }
    end
  end
  # EOF generate_sequence

  def disable_toggle
    @sequence_manager.update(is_active: params[:activate].to_bool)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end
  # EOF disable

  def toggle_primary
    sequence_manager_id = params['id']
    organisation_id = params['organisation_id']
    module_name = params['module_name']
    department_id = params['department_id']
    sequences = SequenceManager.where(organisation_id: organisation_id, module_name: module_name, department_id: department_id).update_all(is_primary: false)
    sequence = SequenceManager.find_by(id: sequence_manager_id)
    if sequence.counter_level.in?(['facility', 'region', 'entity_group'])
      other_sequences = SequenceManager.where(organisation_id: organisation_id, counter_level: sequence.counter_level, module_name: module_name, department_id: department_id).update_all(is_primary: true)
    else
      sequence.update(is_primary: true)
    end
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end
  # EOF toggle_primary

  private

  def default_vals
    @current_facility = current_facility
    @current_organisation = Organisation.find_by(id: current_organisation['_id'])
    @region_masters ||= RegionMaster.where(organisation_id: current_organisation['_id'])
    @entity_groups ||= EntityGroup.where(organisation_id: current_organisation['_id'], is_active: true)
    @separators = Global.sequence_manager.separators
    @separator = Global.sequence_manager.separator
    @module_name = (params[:action] == 'edit') ? @sequence_manager.try(:module_name) : params['module_name']
    @module_names = Global.sequence_manager.module_name
    @display_entities = Global.sequence_manager.display_entities
    @current_region = nil
    @module_has_entity = (@current_organisation.try(:enable_entity_group).present? && Global.sequence_manager.module_details[@module_name]['has_entity']) ? true : false
    if @module_has_entity && @current_organisation.enable_region.present?
      @counter_levels = Global.sequence_manager.counter_level_region_entity
      @current_region = RegionMaster.find_by(id: current_facility.region_master_id)
    elsif @module_has_entity && @current_organisation.enable_region == false
      @counter_levels = Global.sequence_manager.counter_level_entity
    elsif @current_organisation.enable_region.present?
      @counter_levels = Global.sequence_manager.counter_level_region
      @current_region = RegionMaster.find_by(id: current_facility.region_master_id)
    else
      @counter_levels = Global.sequence_manager.counter_level
    end
    @prefix_levels = Global.sequence_manager.prefix_level
    @current_entity_group = EntityGroup.find_by(organisation_id: current_organisation['_id'], country_id: current_facility.country_id, is_active:true)
    @date_formats = Global.sequence_manager.date_format
    @reset_months = Global.sequence_manager.reset_month
    @year_formats = Global.sequence_manager.year_format
    # only opd/ipd/pharmacy/optical depts
    department_ids = Global.sequence_manager.module_details[@module_name]['department_ids'] || ['485396012', '486546481', '50121007', '284748001']
    @departments = Department.where(:id.in => department_ids).order_by(order: :asc)
    @department_details = @departments.map{|department| ["#{department.id.to_s}", 'name': department.try(:name), 'prefix': department.try(:display_name), 'abbreviation': department.try(:display_name)]}.to_h
    @seqeunce_department_ids = nil
  end
  # EOF default_vals

  def sequence_manager_params
    params.require(:sequence_manager).permit(
      :id, :counter_level, :module_name, :original_counter, :current_counter,
      :counter_length, :display_name, :organisation_id, :organisation_abbreviation,
      :facility_id, :facility_name, :facility_abbreviation, :facility_counter, 
      :region_id, :region_name, :region_abbreviation, :region_counter,
      :has_entity, :entity_group_id, :entity_group_name, :entity_group_abbreviation, 
      :entity_group_counter,
      :department_id, :department_name, :department_abbreviation, :department_order, :store_id, 
      :other_settings, :prefix_level, :module_prefix,
      :display_format, :has_date, :date_format, :reset_on_newyear, :reset_month, 
      :year_format, :is_active, :facility_details => {}, :region_details => {},
      :entity_group_details => {}
    )
  end
  # EOF sequence_manager_params

  def sequence_manager
    @sequence_manager = SequenceManager.find_by(id: params[:id])
  end
  # EOF sequence_manager

  def update_default_vals
    @display_entities[-1][-1].replace("#{@sequence_manager.counter_level}_counter")
    if @sequence_manager.prefix_level == 'other'
      @display_entities[3][-1].replace('module_prefix')
    elsif @sequence_manager.prefix_level == 'entity_group'
      @display_entities[3][-1].replace('entity_group_abbreviation')
    end
  end
  # EOF update_default_vals

  def department_details(department_id)
    department = Department.find_by(id: department_id)
    department_name = department.try(:name)
    department_abbreviation = department.try(:display_name)
    department_order = department.try(:order)
    [department_name, department_abbreviation, department_order]
  end
end
