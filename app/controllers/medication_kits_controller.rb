class MedicationKitsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout 'loggedin'

  before_action :set_init_params

  def index
    @medication_kits = MedicationKit.where(user_id: @current_user.id, level: 'user').order_by('created_at DESC')
    @medication_lists = MyPracticeMedicationList.where(user_id: @current_user.id, is_deleted: false)
    @userlaboratorylists = UsersLaboratoryList.where(user_id: @current_user.id)
    @level = 'user'

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    @templatetype = params[:templatetype]
    @level        = params[:level].present? ? params[:level] : 'user'
    @medication_kit = MedicationKit.new
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    find_user_specialties

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def edit
    @medication_kit = MedicationKit.find_by(id: params[:id])
    @level = @medication_kit.level
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    if @medication_kit[:data] == 'null'
      @medication_details = []
    else
      @medication_details = @medication_kit[:data]
      @medication_details = JSON.parse(@medication_details)
    end
    find_user_specialties

    respond_to do |format|
      format.js {}
    end
  end

  def update
    params[:opdrecord] = { treatmentmedication_attributes: {} } if params[:opdrecord].nil?
    params[:medication_kit][:data] = params[:opdrecord][:treatmentmedication_attributes].to_json
    @medication_kit = MedicationKit.find_by(id: params[:medication_kit][:id])
    @medication_kit.update(medication_kit_update_params)
    level = params[:medication_kit][:level]
    @medication_kits = medication_kit_data(level)

    respond_to do |format|
      format.js {}
    end
  end

  def destroy
    @medication_kit = MedicationKit.find_by(id: params[:id])
    level = params[:level]
    @medication_kits = medication_kit_data(level)
    @medication_kit.destroy if @medication_kit.present?
    respond_to do |format|
      format.js {}
    end
  end

  def medication_kit_specialty
    @specialty_id = params[:specialty_id]
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    if @specialty_id == '309988001'
      respond_to do |format|
        format.html { render 'medication_kits/medication_kit_ophthal', layout: false }
      end
    else
      respond_to do |format|
        format.html { render 'medication_kits/medication_kit_other_spes', layout: false }
      end
    end
  end

  def edit_medication_kit_specialty
    @specialty_id = params[:specialty_id]
    @medication_kit = MedicationKit.find_by(id: params[:medication_kit_id])
    @level = @medication_kit.level
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    if @medication_kit[:data] == 'null'
      @medication_details = []
    else
      @medication_details = @medication_kit[:data]
      @medication_details = JSON.parse(@medication_details)
    end
    if @specialty_id == '309988001'
      respond_to do |format|
        format.html { render 'medication_kits/edit_medication_kit_ophthal', layout: false }
      end
    else
      respond_to do |format|
        format.html { render 'medication_kits/edit_medication_kit_other_spes', layout: false }
      end
    end
  end

  def user_med_list
    @level = params[:level]
    @medication_lists = medication_lists_data(@level)
    respond_to do |format|
      format.js {}
    end
  end

  def laboratorysets
    @medication_kits = MedicationKit.where(user_id: @current_user.id)
    @medication_lists = MyPracticeMedicationList.where(user_id: @current_user.id, is_deleted: false)
    @userlaboratorylists = UsersLaboratoryList.where(user_id: @current_user.id, is_deleted: false)
    @set_type = 'user'
    respond_to do |format|
      format.js {}
    end
  end

  def facilitylaboratorysets
    @medication_kits = MedicationKit.where(user_id: @current_user.id)
    @medication_lists = MyPracticeMedicationList.where(user_id: @current_user.id, is_deleted: false)
    @facilitylaboratorylists = FacilityLaboratoryList.where(facility_id: @current_facility.id, is_deleted: false)
    @set_type = 'facility'
    respond_to do |format|
      format.js {}
    end
  end

  def otsets
    @ot_kits = OtKit.where(user_id: @current_user.id).order_by('created_at DESC')
    respond_to do |format|
      # format.html {}
      format.js {}
    end
  end

  def new_ot_set
    @templatetype = params[:templatetype]
    @ot_kit = OtKit.new
    @userid = @current_user.id
    @department_id = '' # @current_user.department_id
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def create_ot_set
    params[:ot_kit][:organisation_id] = @current_user.organisation_id.to_s
    params[:ot_kit][:data] = params[:opdrecord][:ot_kit_attributes].to_json
    @ot_kit = OtKit.new(ot_kit_params)
    @ot_kits = OtKit.where(user_id: @current_user.id).order_by('created_at DESC')
    @ot_kit.save
    respond_to do |format|
      format.js {}
    end
  end

  def edit_ot_set
    @ot_kit = OtKit.find_by(id: params[:id])
    @ot_details = @ot_kit[:data]
    @ot_details = JSON.parse(@ot_details)
    @department_id = '' # @current_user.department_id
    @userid = @current_user.id
    respond_to do |format|
      format.js {}
    end
  end

  def update_ot_set
    puts params[:ot_kit][:data] = params[:opdrecord][:ot_kit_attributes].to_json
    @ot_kit = OtKit.find_by(id: params[:ot_kit][:id])
    @ot_kit.update(ot_kit_update_params)
    @ot_kits = OtKit.where(user_id: @current_user.id).order_by('created_at DESC')
    respond_to do |format|
      format.js {}
    end
  end

  def create_medication_set
    params[:opdrecord] = { treatmentmedication_attributes: {} } if params[:opdrecord].nil?
    params[:medication_kit][:organisation_id] = @current_user.organisation_id.to_s
    params[:medication_kit][:data] = params[:opdrecord][:treatmentmedication_attributes].to_json
    @medication_kit = MedicationKit.new(medication_kit_params)
    level = params[:medication_kit][:level]
    @medication_kits = medication_kit_data(level)
    @medication_kit.save
    respond_to do |format|
      format.js {}
    end
  end

  def destroy_ot_set
    @ot_kit = OtKit.find_by(id: params[:id])
    @ot_kits = OtKit.where(user_id: @current_user.id).order_by('created_at DESC')
    respond_to do |format|
      format.js {} if @ot_kit.destroy
    end
  end

  def new_medication_kits_popup
    @specialty_id = params[:specialty_id]
    respond_to do |format|
      format.html { render 'medication_kits/new_medication_kits_popup', layout: false }
    end
  end

  def save_medication_kit
    medication_kit_data = params[:medication_kit].to_json
    if medication_kit_data != 'null'
      @medication_kit = MedicationKit.new.tap do |med_kit|
        med_kit.data = medication_kit_data
        med_kit.organisation_id = @current_user.organisation_id.to_s
        med_kit.specialty_id = params[:specialty_id]
        med_kit.user_id = @current_user.id
        med_kit.doctor = @current_user.id
        med_kit.set_type = params[:set_type]
        med_kit.level = 'user'
        med_kit.name = params[:medication_kits_name]
        med_kit.save!
      end
    else
      @medication_kit = MedicationKit.new
      @msg = 'Please fill atleast one medication'
    end

    respond_to do |format|
      format.js {}
    end
  end

  def organisation_medication_kit
    @medication_kits = MedicationKit.where(organisation_id: @current_user.organisation.id, level: 'organisation').order_by('created_at DESC')
    @level           = 'organisation'
  end

  def facility_medication_kit
    @medication_kits = MedicationKit.where(facility_id: @current_facility.id, level: 'facility').order_by('created_at DESC')
    @level           = 'facility'
  end

  def show_medication_sets
    level = params[:level]
    # set_type = eval(params[:set_type])
    set_type = JSON.parse(params[:set_type])
    if level == 'organisation'
      medication_kit = MedicationKit.where(organisation_id: @current_user.organisation_id, specialty_id: params[:specialty_id].to_i, level: 'organisation', :set_type.in => set_type).sort_by{|med_kit| med_kit.name.downcase}.pluck(:id, :name)
    elsif level == 'facility'
      medication_kit = MedicationKit.where(facility_id: @current_facility.id, specialty_id: params[:specialty_id].to_i, level: 'facility', :set_type.in => set_type).sort_by{|med_kit| med_kit.name.downcase}.pluck(:id, :name)
    elsif level == 'all'
      medication_kit = MedicationKit.where(organisation_id: @current_user.organisation_id, specialty_id: params[:specialty_id].to_i, :set_type.in => set_type, '$or' => [
                                             { level: 'organisation' },
                                             { facility_id: @current_facility.id, level: 'facility' },
                                             { user_id: @current_user.id, level: 'user' }
                                           ]).sort_by{|med_kit| med_kit.name.downcase}.pluck(:id, :name)
    else
      medication_kit = MedicationKit.where(user_id: @current_user.id, level: 'user', :set_type.in => set_type, specialty_id: params[:specialty_id].to_i).sort_by{|med_kit| med_kit.name.downcase}.pluck(:id, :name)
    end

    render json: { medication_kit: medication_kit }
  end

  def get_organisation_medication_list
    @level = 'organisation'
    @medication_lists = MyPracticeMedicationList.where(organisation_id: @current_user.organisation_id, level: @level, is_deleted: false)

    respond_to do |format|
      format.js {}
    end
  end

  def get_facility_medication_list
    @level = 'facility'
    @medication_lists = MyPracticeMedicationList.where(facility_id: @current_facility.id, level: @level, is_deleted: false)
  end

  private

  def set_init_params
    @current_user = current_user
    @current_facility = current_facility
  end

  def find_user_specialties
    # if !@current_user.role_ids.include?(158965000) && @current_user.role_ids.any? { |ele| [6868009, 160943002].include?(ele) }                              # only admin and owner
    if @level == 'user'
      @level_name = @current_user.fullname
      @user_specialties = Specialty.where(:id.in => @current_user.specialty_ids).pluck(:name, :id) # doctor

    elsif @level == 'organisation'
      @level_name = current_organisation['name']
      @user_specialties = Specialty.where(:id.in => current_organisation['specialty_ids']).pluck(:name, :id)

    elsif @level == 'facility'
      @level_name = @current_facility.name
      @user_specialties = Specialty.where(:id.in => @current_facility.specialty_ids).pluck(:name, :id)
    end
  end

  def medication_kit_params
    params.require(:medication_kit).permit(:user_id, :organisation_id, :doctor, :name, :set_type, :data,
                                           :specialty_id, :facility_id, :level, :pharmacy_item_id,
                                           :generic_display_name, :generic_display_ids, :medicine_from)
  end

  def medication_kit_update_params
    params.require(:medication_kit).permit(:id, :user_id, :organisation_id, :doctor, :name, :set_type, :data,
                                           :specialty_id, :pharmacy_item_id, :generic_display_name,
                                           :generic_display_ids, :medicine_from)
  end

  def ot_kit_params
    params.require(:ot_kit).permit(:user_id, :organisation_id, :doctor, :name, :set_type, :data, :department,
                                   :pharmacy_item_id, :generic_display_name, :generic_display_ids, :medicine_from)
  end

  def ot_kit_update_params
    params.require(:ot_kit).permit(:id, :user_id, :organisation_id, :doctor, :name, :set_type, :data,
                                   :pharmacy_item_id, :generic_display_name, :generic_display_ids, :medicine_from)
  end

  def medication_lists_data(level)
    if level == 'user'
      MyPracticeMedicationList.where(user_id: @current_user.id, level: 'user', is_deleted: false)
    elsif level == 'organisation'
      MyPracticeMedicationList.where(organisation_id: @current_user.organisation_id, level: 'organisation', is_deleted: false)
    elsif level == 'facility'
      MyPracticeMedicationList.where(facility_id: @current_facility.id, level: 'facility', is_deleted: false)
    end
  end

  def medication_kit_data(level)
    if level == 'user'
      MedicationKit.where(user_id: @current_user.id, level: 'user')
    elsif level == 'organisation'
      MedicationKit.where(organisation_id: @current_user.organisation.id, level: 'organisation')
    elsif level == 'facility'
      MedicationKit.where(facility_id: @current_facility.id, level: 'facility')
    end
  end
end
