class SurgeryPackagesController < ApplicationController
  before_action :authorize
  before_action :set_surgery_package, only: [:destroy, :enable, :activate, :set_package_services]

  def index
    @specialties = Specialty.where(:id.in => current_organisation['specialty_ids']).to_a
    @selected_specialty = params[:specialty_id] || @specialties.first.id
    @sub_specialties = SubSpecialty.where(specialty_id: @selected_specialty).to_a

    @surgery_packages = SurgeryPackage.collection.aggregate(
      [
        { '$match': { organisation_id: current_user.organisation_id, specialty_id: @selected_specialty } },
        { '$group': { _id: { facility_id: '$facility_id', is_active: '$is_active' }, count: { '$sum': 1 } } },
        { '$group': { _id: '$_id.facility_id', facility_count: { '$sum': '$count' },
                      active_group: { '$push': { active: '$_id.is_active', count: '$count' } } } }
      ]
    ).to_a

    @facilities = Facility.where(:id.in => @surgery_packages.pluck(:_id).uniq)
                          .map { |facility| { id: facility.id, name: facility.name, country_id: facility.country_id } }
  end

  def package_list
    @specialties = Specialty.where(:id.in => current_organisation['specialty_ids']).to_a
    @selected_specialty = params[:specialty_id] || @specialties.first.id
    @sub_specialties = SubSpecialty.where(specialty_id: @selected_specialty).to_a

    @options = { facility_id: params[:facility_id], specialty_id: @selected_specialty }
    @options = @options.merge(is_active: params[:is_active]) if params[:is_active].present?

    @surgery_packages = SurgeryPackage.where(@options).order(created_at: :desc).group_by(&:package_group_id)
    @package_definitions = PackageDefinition.where(:package_group_id.in => @surgery_packages.keys).to_a
  end

  def new_multiple
    form_queries
  end

  def edit_multiple
    form_queries

    @package_definition = PackageDefinition.find_by(package_group_id: params[:package_group_id])
    @surgery_packages = SurgeryPackage.where(package_group_id: params[:package_group_id])

    @facility = @facilities.find { |facility| facility[:id].to_s == @package_definition.facility_id.to_s }

    @specialties = Specialty.where(:id.in => @facility.specialty_ids).to_a
    @specialty = @specialties.find { |specialty| specialty[:id].to_s == @package_definition.specialty_id }
    @sub_specialties = SubSpecialty.where(specialty_id: @package_definition.specialty_id).to_a
    @sub_specialty = @sub_specialties.find { |ss| ss[:id].to_s == @package_definition.sub_specialty_id }

    @items = SurgeryPackage::Item.where(facility_id: @package_definition.facility_id.to_s)
  end

  def create_multiple
    return unless params[:surgery_packages].present?
    if check_validation
      render 'errors.js.erb' 
    else
      params[:surgery_packages].each do |_k, package_fields|
        if package_fields[:id].present?
          surgery_package = SurgeryPackage.find_by(id: package_fields[:id])
          surgery_package.update_attributes!(surgery_package_params(package_fields))
        else
          surgery_package = SurgeryPackage.new(surgery_package_params(package_fields))
          surgery_package.save!
        end
      end

      PackageDefinitions::CreateUpdateService.call(params[:package_definition])
    end
  end

  def destroy
    @surgery_package&.set(is_active: false)
  end

  def enable
    @surgery_package&.set(is_active: true)
  end

  def activate
    @surgery_package&.set(activated: true)
  end

  def destroy_multiple
    @surgery_packages = SurgeryPackage.where(package_group_id: params[:package_group_id])
    @surgery_packages.update_all(is_active: false)
  end

  def enable_multiple
    @surgery_packages = SurgeryPackage.where(package_group_id: params[:package_group_id])
    @surgery_packages.update_all(is_active: true)
  end

  def set_specialties
    facility = Facility.find_by(id: params[:facility_id])
    @specialties = Specialty.where(:id.in => facility.specialty_ids).to_a

    render json: { specialties: @specialties.pluck(:name, :id) }
  end

  def set_package_services
    @payer_masters = PayerMaster.where(facility_id: current_facility.id.to_s)
    @payer_fields = @payer_masters.map { |c| { id: c.id.to_s, display_name: c.display_name } }
    @counter = params[:counter]
    @edit_bill_unit_price_enabled = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:edit_bill_unit_price_enabled)

    respond_to do |format|
      format.html { render 'set_package_services.html.erb', layout: false }
    end
  end

  def set_items
    @items = SurgeryPackage::Item.where(facility_id: params[:facility_id])

    render json: { items: @items.pluck(:name, :id, :type) }
  end

  def find_code_duplicacy
    duplicates = SurgeryPackage.where(:user_package_code.in => params['codes'], organisation_id: params['organisation_id'], facility_id: params['facility_id'])

    if duplicates.present? 
      render json: { message: "Code already taken", duplicate_codes: duplicates.pluck(:user_package_code) }, status: 200
    else
      render json: { message: "No code found" }, status: 200
    end
  end

  private

  def check_validation
    package_codes = []
    ids = []
    params['surgery_packages'].each do |package| 
      ids << package[1]['id']
      package_codes << package[1]['user_package_code']
    end
    duplicates = SurgeryPackage.where(:id.nin => ids, :user_package_code.in => package_codes, facility_id: params['package_definition']['facility_id'])
    @duplicate_codes = duplicates.pluck(:user_package_code) 
    duplicates.present? ? true : false
  end

  def surgery_package_params(surgery_package)
    surgery_package.permit(
      :id, :organisation_id, :facility_id, :specialty_id, :sub_specialty_id, :department_id, :user_id, :name,
      :display_name, :type, :service_group_id, :service_sub_group_id, :service_type, :service_type_code_name,
      :service_type_code, :room_type, :contact_group_id, :payer_master_id, :no_of_days, :amount, :valid_from,
      :valid_till, :package_group_id, :user_package_code, activity_log: { activated: [:user_id, :user_name, :event_time] },
      services_attributes: [:id, :item_name, :item_id, :item_type, :item_code, :unit, :unit_price, :total_price,
                            :is_active, activity_log: { activated: [:user_id, :user_name, :event_time] }]
    )
  end

  def set_surgery_package
    @surgery_package = SurgeryPackage.find_by(id: params[:id])
  end

  def form_queries
    organisation_id = current_user.organisation_id
    @facilities = Facility.where(organisation_id: organisation_id).to_a
    @service_groups = ServiceGroup.where(organisation_id: organisation_id).to_a
    @service_sub_groups = ServiceSubGroup.where(organisation_id: organisation_id).to_a
    @contact_groups = ContactGroup.where(organisation_id: organisation_id, :name.ne => "TPA+Insurance").to_a
    @room_types = Global.room_master.types
    group_id_condition = params[:action] == 'new_multiple' || params[:clone] == 'true'
    @package_group_id = group_id_condition ? BSON::ObjectId.new : params[:package_group_id]
  end
end
