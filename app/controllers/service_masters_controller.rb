class ServiceMastersController < ApplicationController
  before_action :authorize
  before_action :set_service_groups, only: [:new, :edit, :edit_multiple]
  before_action :set_service_sub_groups, only: [:new, :edit, :edit_multiple]
  before_action :set_service_master, only: [:edit, :update, :destroy, :enable]
  before_action :set_specialties, only: [:new, :edit, :edit_multiple]

  def index
    @service_masters = ServiceMaster.includes(:service_group, :service_sub_group)
                                    .where(organisation_id: current_user.organisation_id).order(created_at: :desc)
  end

  def new
    @service_master = ServiceMaster.new
  end

  def create
    params[:service_master][:service_code] = CommonHelper.get_service_master_code(current_user)
    params[:service_master][:department_ids] = params[:service_master][:department_ids].split(',')
    params[:service_master][:activity_log] = {}
    params[:service_master][:activity_log]['activated'] = { user_name: current_user.fullname, event_time: Time.current }

    @service_master = ServiceMaster.new(service_master_params)

    if @service_master.save
      set_specialty
      CreatePricingMasterJob.perform_later(@service_master.id.to_s)
    else
      set_service_groups
      set_service_sub_groups

      render 'new'
    end
  end

  def edit
    @no_subspeciality = true if @service_master.sub_specialty_id.blank?
  end

  def update
    params[:service_master][:department_ids] = params[:service_master][:department_ids].split(',')
    if @service_master.update_attributes(service_master_params)
      set_specialty
      CreatePricingMasterJob.perform_later(@service_master.id.to_s, params[:update_amount].present?)
    else
      set_service_groups
      set_service_sub_groups

      render 'edit'
    end
  end

  def destroy
    if @service_master.present?
      @service_master.is_active = false
      @service_master.activity_log['deactivated'] = { user_name: current_user.fullname, event_time: Time.current }

      @service_master.save!

      @pricing_masters = PricingMaster.where(service_master_id: @service_master.id.to_s).update_all(is_active: false)
    end
  end

  def enable
    if @service_master.present?
      @service_master.is_active = true
      @service_master.activity_log['activated'] = { user_name: current_user.fullname, event_time: Time.current }

      @service_master.save!

      @pricing_masters = PricingMaster.where(service_master_id: @service_master.id.to_s).update_all(is_active: true)
    end
  end

  def search
    @search = params[:search]
    options = { organisation_id: current_user.organisation_id }
    options = options.merge(service_name: /#{Regexp.escape(@search)}/i) if @search.present? && @search.length > 2

    @service_masters = ServiceMaster.includes(:service_group, :service_sub_group).where(options)
  end

  def edit_multiple
    @selected_sub_specialty = params[:sub_specialty_id]
    @current_user = current_user
    if params[:flag] == 'Procedure'
      @common_procedures = CommonProcedure.where(speciality_id: @selected_specialty)
      proc_options = { speciality_id: @selected_specialty, organisation_id: @current_user.organisation_id.to_s,
                       is_deleted: false }
      @custom_common_procedures = CustomCommonProcedure.where(proc_options)
      @translated_common_procedures = TranslatedCommonProcedure.where(proc_options)
    elsif params[:flag] == 'Ophthal Investigation'
      @ophthalmology_investigations = OphthalmologyInvestigationData.where(speciality_id: @selected_specialty)
      inv_options = { facility_id: current_facility.id.to_s, is_deleted: false }
      @custom_ophthal_investigations = CustomOphthalInvestigation.where(inv_options)
    elsif params[:flag] == 'Laboratory Investigation'
      @laboratory_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id.to_s, is_deleted: false)
    elsif params[:flag] == 'Radiology Investigation'
      @radiology_investigations = RadiologyInvestigationData.where(specialty_id: @selected_specialty.to_i)
      inv_options = { specialty_id: @selected_specialty, facility_id: current_facility.id.to_s, is_deleted: false }
      @custom_radiology_investigations = CustomRadiologyInvestigation.where(inv_options)
    end

    @service_masters = ServiceMaster.where(organisation_id: @current_user.organisation_id, service_type: params[:flag],
                                           specialty_id: @selected_specialty, sub_specialty_id: @selected_sub_specialty)
    @service_masters_attributes = @service_masters.map(&:attributes)
    params[:specialty_id] = @selected_specialty if @available_specialties.count == 1 && params[:specialty_id].blank?
  end

  def update_multiple
    specialty_id = params[:specialty_id]
    sub_specialty_id = params[:sub_specialty_id]
    user_id = current_user.id.to_s
    service_master = params[:service_master].to_unsafe_h

    CreateMultipleServiceMasterJob.perform_later(service_master, user_id, specialty_id, sub_specialty_id)
  end

  def set_service_types
    specialty_id = get_speacialty_id(params[:specialty_id].to_s)
    if specialty_id.present?
      service_types = Global.service_types.send(specialty_id)['type']
      render json: service_types.to_json
    end
  end

  private

  def service_master_params
    params.require(:service_master).permit(
      :service_type, :service_type_code, :service_type_code_name, :service_type_code_type, :service_group_id,
      :service_sub_group_id, :service_name, :service_code, :service_amount, :organisation_service_code,
      :activity_log, :organisation_id, :user_id, :specialty_id, :sub_specialty_id, department_ids: []
    )
  end

  def set_service_master
    @service_master = ServiceMaster.find_by(id: params[:id])
  end

  def set_specialties
    @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids']).pluck(:name, :id)
    @selected_specialty = @service_master&.specialty_id || params[:specialty_id] || @available_specialties[0][1]

    @sub_specialties = SubSpecialty.where(specialty_id: @selected_specialty).pluck(:name, :id)
  end

  def set_specialty
    @specialty = Specialty.find_by(id: @service_master.specialty_id)
    @sub_specialty = SubSpecialty.find_by(id: @service_master.sub_specialty_id)
  end

  def set_service_groups
    @service_groups = ServiceGroup.where(organisation_id: current_user.organisation_id, :name.ne => 'Legacy')
    @service_groups_attributes = @service_groups.map { |sg| { id: sg.id.to_s, name: sg.name } }
  end

  def set_service_sub_groups
    @service_sub_groups = ServiceSubGroup.where(organisation_id: current_user.organisation_id)
    @service_sub_groups_attributes = @service_sub_groups.map { |ssg| { id: ssg.id.to_s, name: ssg.name } }
  end

  def get_speacialty_id(specialty_id)
    if Global.send('service_types').key?(specialty_id)
      specialty_id
    else
      nil
    end
  end
  # EOF get_speacialty_id
end
