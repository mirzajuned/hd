class PricingMastersController < ApplicationController
  before_action :authorize, :sessions_params
  before_action :set_service_master, only: [:edit_multiple, :set_pricing_masters]
  before_action :set_payer_masters, only: [:pricing_list, :edit_multiple, :set_pricing_masters, :edit_payer_pricing]
  before_action :set_specialties, only: [:index, :pricing_list, :set_pricing_masters, :edit_payer_pricing]
  before_action :set_service_groups, only: [:edit_payer_pricing]
  before_action :set_service_sub_groups, only: [:edit_payer_pricing]
  def index
    @selected_specialty = params[:specialty_id] || @specialties.first.id

    @pricing_masters = PricingMaster.collection.aggregate(
      [
        { '$match': { organisation_id: current_user.organisation_id, specialty_id: @selected_specialty } },
        { '$group': { _id: { facility_id: '$facility_id', is_active: '$is_active' }, count: { '$sum': 1 } } },
        { '$group': {
          _id: '$_id.facility_id', facility_count: { '$sum': '$count' },
          active_group: { '$push': { active: '$_id.is_active', count: '$count' } }
        } }
      ]
    ).to_a

    @facilities = Facility.where(:id.in => @pricing_masters.pluck(:_id).uniq)
                          .map { |facility| { id: facility.id, name: facility.name, country_id: facility.country_id } }
  end

  def pricing_list
    @selected_specialty = params[:specialty_id] || @specialties.first.id

    @options = { facility_id: params[:facility_id], specialty_id: @selected_specialty }
    @options = @options.merge(is_active: params[:is_active]) if params[:is_active].present?
    @pricing_masters = PricingMaster.includes(:service_master, :service_group, :service_sub_group).where(@options)
                                    .order(created_at: :desc)
                                    .group_by { |pm| [pm.service_master_id, pm.department_id] }
  end


  def edit_multiple
    @specialty = Specialty.find_by(id: @service_master.specialty_id)
    @sub_specialty = SubSpecialty.find_by(id: @service_master.sub_specialty_id)
    @pricing_masters = PricingMaster.includes(:service_master, :payer_master)
                                    .where(facility_id: params[:facility_id],
                                           service_master_id: params[:service_master_id],
                                           department_id: params[:department_id])
    @standard_pricing_master = @pricing_masters.find_by(payer_master_id: 'general')

    if  @contact_group_id.present?
      @pricing_masters = @pricing_masters.where(contact_group_id: @contact_group_id)
    end

    @room_types = Global.room_master.types
    @users = User.where(role_ids: 158965000, facility_ids: @standard_pricing_master.facility_id.to_s).to_a
  end

  def update_multiple
    save_pricing_master(params)
  end

  def set_pricing_masters
    @service_type = params[:service_type].to_s

    department_filter = params[:department_filter].to_s
    service_type_filter = params[:service_type_filter].to_s
    group_filter = params[:group_filter].to_s
    sub_group_filter = params[:sub_group_filter].to_s

    if @service_type == 'General Consultation'
      @consultant_user = User.find_by(id: params[:consultant_id])
      @standard_pricing_masters = PricingMaster.includes(:service_master).where(
          facility_id: params[:facility_id], :payer_master_id.in => ['general'], service_type: 'General Consultation'
      ).to_a
      @payer_pricing_masters = PricingMaster.includes(:service_master).where(
          facility_id: params[:facility_id], :consultant_user_id => params[:consultant_id]
      ).to_a
    else

      filter_option = {facility_id: params[:facility_id], :payer_master_id.in => ['general', BSON::ObjectId(params[:payer_master_id])]}
      filter_option = filter_option.merge(department_id: department_filter) if department_filter.present?
      filter_option = filter_option.merge(service_type: service_type_filter) if service_type_filter.present?
      filter_option = filter_option.merge(service_group_id: group_filter) if group_filter.present?
      filter_option = filter_option.merge(service_sub_group_id: sub_group_filter) if sub_group_filter.present?

      @payer_master = PayerMaster.find_by(id: params[:payer_master_id])
      @pricing_masters = PricingMaster.includes(:service_master).where(filter_option).to_a
      pricing_master_fields = @pricing_masters.map { |pm| pm }
      @standard_pricing_masters = pricing_master_fields.map { |pmf| pmf if pmf.payer_master_id == 'general' }.reject(&:nil?)
      @payer_pricing_masters = pricing_master_fields.map { |pmf| pmf if pmf.payer_master_id.to_s == params[:payer_master_id] }
                                   .reject(&:nil?)
    end
  end

  def edit_payer_pricing
    @selected_specialty = params[:specialty_id] || @specialties.first.id
  end

  def update_payer_pricing
    save_pricing_master(params)
  end

  def set_surgery_pricing_masters
    pricing_masters = PricingMaster.where(facility_id: params[:facility_id], payer_master_id: params[:payer_master_id],
                                          specialty_id: params[:specialty_id], department_id: params[:department_id])

    render json: { "pricing_masters": pricing_masters }
  end

  private

  def sessions_params
    @current_user = current_user
    @current_facility = current_facility
  end

  def set_service_master
    service_master = ServiceMaster.includes(:service_group, :service_sub_group)
    if params[:service_master_id].present?
      @service_master = service_master.find_by(id: params[:service_master_id])
    else
      @service_masters = service_master.where(organisation_id: @current_user.organisation_id, is_active: true)
    end
  end

  def set_payer_masters
    @service_type = params[:service_type].to_s
    @contact_group_id = params[:contact_group_id].to_s
    @facility_id = params[:facility_id].to_s
    @facility = Facility.find_by(id: @facility_id)
    if @service_type == "General Consultation"
      @consultant_users = User.where(role_ids: 158965000, facility_ids: params[:facility_id].to_s, is_active: true).to_a
      @consultant_user_fields = @consultant_users.map { |cu| { id: cu.id.to_s, fullname: cu.fullname } }
    else
      payer_master_options = { facility_id: params[:facility_id], is_active: true }
      contact_group_options = { organisation_id: @current_user.organisation_id , :name.ne => "TPA+Insurance"}

      if  @contact_group_id.present?
        payer_master_options = payer_master_options.merge({contact_group_id: @contact_group_id})
        # contact_group_options = contact_group_options.merge({id: @contact_group_id})
      end

      @contact_groups = ContactGroup.where(contact_group_options).to_a
      @contact_group_fields = @contact_groups.map { |cg| { id: cg.id.to_s, name: cg.name } }

      @payer_masters = PayerMaster.where(payer_master_options).to_a
      @payer_fields = @payer_masters.map do |c|
        { id: c.id.to_s, display_name: c.display_name, contact_group_id: c.contact_group_id.to_s }
      end
    end
  end

  def set_specialties
    @specialties = Specialty.where(:id.in => current_organisation['specialty_ids']).to_a
  end

  def set_service_groups
    @service_groups = ServiceGroup.where(organisation_id: current_user.organisation_id, :name.ne => 'Legacy')
    @service_groups_attributes = @service_groups.map { |sg| { id: sg.id.to_s, name: sg.name } }
  end

  def set_service_sub_groups
    @service_sub_groups = ServiceSubGroup.where(organisation_id: current_user.organisation_id)
    @service_sub_groups_attributes = @service_sub_groups.map { |ssg| { id: ssg.id.to_s, name: ssg.name } }
  end

  def save_pricing_master(params)
    return unless params[:pricing_master].present?

    params[:pricing_master].each do |_k, pricing_master|
      @pricing_master = if pricing_master[:id].present?
                          PricingMaster.find_by(id: pricing_master[:id].to_s)
                        else
                          PricingMaster.new
                        end
      next unless @pricing_master.present?

      @pricing_master[:organisation_id] = pricing_master[:organisation_id]
      @pricing_master[:facility_id] = pricing_master[:facility_id]
      @pricing_master[:user_id] = pricing_master[:user_id]
      @pricing_master[:specialty_id] = pricing_master[:specialty_id]
      @pricing_master[:department_id] = pricing_master[:department_id]
      @pricing_master[:department_name] = pricing_master[:department_name]

      @pricing_master[:service_master_id] = pricing_master[:service_master_id]
      @pricing_master[:service_group_id] = pricing_master[:service_group_id]
      @pricing_master[:service_sub_group_id] = pricing_master[:service_sub_group_id]
      @pricing_master[:service_type] = pricing_master[:service_type]
      @pricing_master[:consultant_user_id] = pricing_master[:consultant_user_id]
      @pricing_master[:service_type_code] = pricing_master[:service_type_code]
      @pricing_master[:service_type_code_name] = pricing_master[:service_type_code_name]
      @pricing_master[:service_name] = pricing_master[:service_name]
      @pricing_master[:payer_master_id] = pricing_master[:payer_master_id]
      @pricing_master[:contact_group_id] = pricing_master[:contact_group_id]
      @pricing_master[:amount] = pricing_master[:amount].to_i
      @pricing_master[:service_code] = pricing_master[:service_code]
      @pricing_master[:internal_comment] = pricing_master[:internal_comment]
      @pricing_master[:external_comment] = pricing_master[:external_comment]
      if @pricing_master.facility_service_code.nil?
        facility = Facility.find_by(id: @pricing_master.facility_id)
        @pricing_master[:facility_service_code] = CommonHelper.get_pricing_master_code(facility)
      end
      @pricing_master[:is_active] = pricing_master[:is_active].present? ? pricing_master[:is_active] : true
      @pricing_master[:activity_log] = @pricing_master.activity_log
      if @pricing_master.is_active_changed?
        log = ('activated' if @pricing_master.is_active) || 'deactivated'
        @pricing_master[:activity_log][log] = { user_name: @current_user.fullname, event_time: Time.current }
      end

      @pricing_master[:has_exceptions] = pricing_master[:has_exceptions]

      pricing_exceptions = @pricing_master.pricing_exceptions

      if pricing_master[:exceptions].present?
        pricing_master[:exceptions].each do |_key, exceptions|
          exception_ids = {}
          seq_array = []
          exception = pricing_exceptions.find_by(id: exceptions[:_id])
          exceptions[:sub_exception].each do |_kkey, sub_exceptions|
            if sub_exceptions[:type] == 'room'
              exception_ids[:room_exception_id] = sub_exceptions[:exception_id]
              exception_ids[:room_exception_name] = sub_exceptions[:exception_name]
            elsif sub_exceptions[:type] == 'user'
              exception_ids[:user_exception_id] = sub_exceptions[:exception_id]
              exception_ids[:user_exception_name] = sub_exceptions[:exception_name]
            end
            seq_array << sub_exceptions[:type]
          end
          options = { room_exception_id: exception_ids[:room_exception_id],
                      room_exception_name: exception_ids[:room_exception_name],
                      user_exception_id: exception_ids[:user_exception_id],
                      user_exception_name: exception_ids[:user_exception_name],
                      amount: exceptions[:amount], sequence: seq_array }
          if exception.present?
            exception.update(options.merge(is_active: exceptions[:is_active]))
          else
            pricing_exceptions.new(options).save!
          end
        end
      end

      @pricing_master.save!
    end
  end
end
