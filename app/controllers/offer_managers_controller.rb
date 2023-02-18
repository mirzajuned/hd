class OfferManagersController < ApplicationController
  before_action :authorize
  before_action :set_offer_manager, only: [:edit, :update, :destroy, :activate, :show, :offer_details]
  before_action :set_facilities, only: [:index, :new, :edit, :facility_dropdown]
  before_action :set_departments, only: [:new, :edit]

  def index
    @ongoing_offer_managers = OfferManager.where(facility_id: current_facility.id, :start_datetime.lte => Time.current, :end_datetime.gte => Time.current, is_active: true).type_asc
    @upcoming_offer_managers = OfferManager.where(facility_id: current_facility.id, :start_datetime.gte => Time.current, is_active: true).type_asc
    @inactive_offer_managers = OfferManager.where(facility_id: current_facility.id, :end_datetime.gte => Time.current, is_active: false).type_asc
    @expired_offer_managers = OfferManager.where(facility_id: current_facility.id, :end_datetime.lte => Time.current).type_asc
  end

  def facility_dropdown
    @active_tab = params[:active_tab]
    facility_dropdown_id = params[:facility_dropdown_id]
    @facility_filter = OfferManager.where(facility_id: facility_dropdown_id, is_active: true)
    @ongoing_offer_managers = OfferManager.where(facility_id: facility_dropdown_id, :start_datetime.lte => Time.current, :end_datetime.gte => Time.current, is_active: true).type_asc
    @upcoming_offer_managers = OfferManager.where(facility_id: facility_dropdown_id, :start_datetime.gte => Time.current, is_active: true).type_asc
    @inactive_offer_managers = OfferManager.where(facility_id: facility_dropdown_id, :end_datetime.gte => Time.current, is_active: false).type_asc
    @expired_offer_managers = OfferManager.where(facility_id: facility_dropdown_id, :end_datetime.lte => Time.current).type_asc
  end

  def new
    @current_facility = params[:facility_id].present? ? Facility.find_by(id: params[:facility_id]) : @current_facility
    @data_tab = params[:data_tab]
    @offer_manager = OfferManager.new(facility_id: params[:facility_id], offer_type: params[:offer_type])
  end

  def create
    store_ids = service_ids = []
    department_ids = params[:offer_manager]['department_ids'].split(',')
    params[:offer_manager]['department_ids'] = department_ids
    service_id = params[:offer_manager]['service_id'] if params[:offer_manager]['service_id'].present?
    department_ids.each do |department_id|
      department_stores = params["#{department_id}_stores"]
      department = Department.find_by(id: department_id)
      params[:offer_manager]['department_id'] = department_id
      params[:offer_manager]['department_name'] = department.try(:name)
      params[:offer_manager]['department_display_name'] = department.try(:display_name)
      if department_stores.present?
        params[:offer_manager]['store_ids'] = department_stores
        department_stores.each do |store_id|
          store = Inventory::Store.find_by(id: store_id)
          params[:offer_manager]['store_id'] = store_id
          params[:offer_manager]['store_name'] = store.try(:name)
          offer_manager = OfferManager.new(offer_manager_params)
          offer_manager.save!
        end
      else
        if service_id.present?
          service = PricingMaster.find_by(id: service_id)
          params[:offer_manager]['service_id'] = service_id
          params[:offer_manager]['service_name'] = service.try(:service_name)
        end
        offer_manager = OfferManager.new(offer_manager_params)
        offer_manager.save!
      end
    end
    @facility_id = params[:offer_manager]['facility_id']
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def edit
    @data_tab = params[:data_tab]
    if @offer_manager.code_type == 'standard'
      @other_offers = OfferManager.where(organisation_id: @offer_manager.organisation_id, department_ids: @offer_manager.department_ids, offer_type: @offer_manager.offer_type, code_type: @offer_manager.code_type, standard_code: @offer_manager.standard_code, :id.ne => @offer_manager.id, is_active: true)
    else
      @other_offers = OfferManager.where(organisation_id: @offer_manager.organisation_id, department_ids: @offer_manager.department_ids, offer_type: @offer_manager.offer_type, code_type: @offer_manager.code_type, :id.ne => @offer_manager.id, is_active: true)
    end
    if @offer_manager.offer_type == 'bill'
      @inventory_stores = Inventory::Store.where(
        :id.nin => @other_offers.pluck(:store_id).uniq,
        facility_id: @offer_manager.facility_id,
        department_id: @offer_manager.department_id,
        is_active: true, is_disable: false
      ).order_by(name: :asc)
    else
      facility = Facility.find_by(id: @offer_manager.facility_id)
      @services = PricingMaster.includes(
        :service_master, :service_group, :service_sub_group
      ).where(facility_id: facility.id.to_s,
              :specialty_id.in => facility.specialty_ids,
              department_id: @offer_manager.department_id)#.group_by(&:service_group_id)
      # , contact_group_id: nil
    end
  end

  def update
    service_id = params[:offer_manager]['service_id'] if params[:offer_manager]['service_id'].present?
    if service_id.present?
      service = PricingMaster.find_by(id: service_id)
      params[:offer_manager]['service_id'] = service_id
      params[:offer_manager]['service_name'] = service.try(:service_name)
    end
    @offer_manager.update(offer_manager_params)
    @data_tab = params[:data_tab]
    @facility_id = @offer_manager.facility_id
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def show; end

  def destroy
    @data_tab = params[:data_tab]
    @offer_manager.update_attributes(is_active: false)
    @facility_id = @offer_manager.facility_id.to_s
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def validate_offer
    offer_manager = params[:offer_manager]
    offer_present = false
    return unless offer_manager.present?
    department_ids = if params[:department_id].present?
                      params[:department_id].split(',')
                    else
                      ''
                    end
    organisation_id = params[:organisation_id]
    facility_id = params[:facility_id]
    if department_ids != '' && offer_manager[:name].present? && params[:existing_name] != offer_manager[:name]
      offer_present = check_offer_exist(
                        organisation_id, facility_id, department_ids,
                        'name', offer_manager[:name]
                      )
    elsif department_ids != '' && offer_manager[:standard_code].present? && params[:existing_standard_code] != offer_manager[:standard_code]
      offer_present = check_offer_exist(
                        organisation_id, facility_id, department_ids,
                        'standard_code', offer_manager[:standard_code]
                      )
    end
    render json: (!offer_present).to_json
  end

  def load_stores
    @inventory_stores = Inventory::Store.where(
      facility_id: params['facility_id'],
      department_id: params['department_id'],
      is_active: true, is_disable: false
    ).order_by(name: :asc)
    render json: @inventory_stores.to_json
  end

  def load_services
    facility = Facility.find_by(id: params['facility_id'])
    @services = PricingMaster.includes(
      :service_master, :service_group, :service_sub_group
    ).where(facility_id: facility.id.to_s,
            :specialty_id.in => facility.specialty_ids,
            department_id: params['department_id']).group_by(&:service_group_id)
    render json: @services.to_json
  end

  def activate
    @data_tab = params[:data_tab]
    @offer_manager.update_attributes(is_active: true)
    @facility_id = @offer_manager.facility_id.to_s
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def offer_details
    render json: @offer_manager.attributes.merge(
      :offer_code => @offer_manager.offer_code
    ).to_json if @offer_manager.present?
  end

  private

  def offer_manager_params
    params.require(:offer_manager)
          .permit(:organisation_id, :facility_id, :department_id, :department_name, :department_display_name,
                  :offer_type, :service_id, :service_name, :name, :code_type, :standard_code,
                  :store_id, :store_name, :dynamic_code_count, :start_date, :start_datetime, 
                  :end_date, :end_datetime, :offer_duration, :discount, :max_amount, 
                  :has_redeem_limit, :redeem_limit, :allow_with_other_offers,
                  :department_ids => [], :store_ids => [], :service_ids => [])
  end

  def set_offer_manager
    @offer_manager = OfferManager.find_by(id: params[:id])
    @current_facility = Facility.find_by(id: @offer_manager.try(:facility_id)) || current_facility
  end

  def set_facilities
    @current_user = current_user
    @current_facility = current_facility
    @current_organisation = current_organisation
    @facilities = @current_user.facilities.pluck(:name, :id)
  end

  def set_departments
    @bill_departments = Department.where(
      :id.in => ['485396012', '486546481', '284748001', '50121007']
    ).order(order: :asc).map { |d| [d.display_name, d.id.to_s] }
    # , '284748001', '50121007'
    @service_departments = Department.where(
      :id.in => ['485396012', '486546481']
    ).order(order: :asc).map { |d| [d.display_name, d.id.to_s] }
  end

  def check_offer_exist(organisation_id, facility_id, department_ids, field_name, field_val)
    OfferManager.find_by(
      organisation_id: organisation_id,
      facility_id: facility_id,
      :department_ids.in => department_ids,
      field_name.to_sym => field_val,
      is_active: true).present?
  end
end
