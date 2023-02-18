class CustomCommonProceduresController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :set_init_params

  def index
    @disabled_procedures = CustomCommonProcedure.where(organisation_id: @current_user.organisation_id, is_deleted: true) + SynonymCommonProcedure.where(organisation_id: @current_user.organisation_id, is_deleted: true) + TranslatedCommonProcedure.where(organisation_id: current_user.organisation_id, is_deleted: true)
  end

  def new
    @custom_common_procedure = CustomCommonProcedure.new
    @org_id = @current_user.organisation_id
    @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @languages = Language.where(country_ids: current_facility.country_id).pluck(:name, :lcid_code)
    @languages.delete(["English", "en"])
  end

  def create
    if params[:custom_procedure_type] == 'create_new_procedure'
      @procedure = CustomProcedure::CreateService.call(params[:custom_common_procedure], @current_user)
    elsif params[:custom_procedure_type] == 'attach_procedure'
      params[:synonym_common_procedure][:specialty_id] = params[:custom_common_procedure][:speciality_id]
      @procedure = SynonymProcedure::CreateService.call(params[:synonym_common_procedure])
    elsif params[:custom_procedure_type] == 'translated_procedure'
      params[:translated_common_procedure][:speciality_id] = params[:custom_common_procedure][:speciality_id]
      @procedure = TranslatedProcedure::CreateService.call(params[:translated_common_procedure], @current_user)
    end
  end

  def edit
    @custom_common_procedure = CustomCommonProcedure.find_by(id: params[:id]) || SynonymCommonProcedure.find_by(id: params[:id]) || TranslatedCommonProcedure.find_by(id: params[:id])
    @org_id = @current_user.organisation_id
    lcid_code = @custom_common_procedure[:language]
    @language = Language.where(lcid_code: lcid_code).pluck(:name)
  end

  def update
    if params[:procedure_data_from] == 'custom_common_procedure'
      @procedure_name = params[:custom_common_procedure][:name]
      @custom_common_procedure = CustomCommonProcedure.find_by(id: params[:id])
    elsif params[:procedure_data_from] == 'synonym_common_procedure'
      @procedure_name = params[:synonym_common_procedure][:name]
      @custom_common_procedure = SynonymCommonProcedure.find_by(id: params[:id])
    elsif params[:procedure_data_from] == 'translated_common_procedure'
      @procedure_name = params[:translated_common_procedure][:name]
      @custom_common_procedure = TranslatedCommonProcedure.find_by(id: params[:id])
    end
    @custom_common_procedure.update_attributes(name: @procedure_name, display_name: @procedure_name)
  end

  def name_validation
    # validating 3 synonym fields ,if present
    procedure_from = params[:procedure_from]
    if procedure_from == 'synonym'
      procedure_name_entered = params[:synonym_common_procedure][:name]
      if procedure_name_entered['0'].present?
        procedure_name = procedure_name_entered['0']
      elsif procedure_name_entered['1'].present?
        procedure_name = procedure_name_entered['1']
      elsif procedure_name_entered['2'].present?
        procedure_name = procedure_name_entered['2']
      end
    elsif procedure_from == 'custom'
      procedure_name = params[:custom_common_procedure][:name]
    end

    synonym_procedure = SynonymCommonProcedure.find_by(name: procedure_name, organisation_id: @current_user.organisation_id, is_deleted: false)
    custom_procedure_found = CustomCommonProcedure.find_by(name: procedure_name, organisation_id: @current_user.organisation_id, is_deleted: false)

    respond_to do |format|
      format.json { render json: !custom_procedure_found.present? && !synonym_procedure.present? }
    end
  end

  def update_name_validation
    procedure_from = params[:procedure_from]
    procedure_name_saved = params[:saved_procedure_name]
    if procedure_from == 'synonym'
      procedure_field_name = params[:synonym_common_procedure][:name]
    elsif procedure_from == 'custom'
      procedure_field_name = params[:custom_common_procedure][:name]
    elsif procedure_from == 'translated'
      procedure_field_name = params[:translated_common_procedure][:name]
    end

    if procedure_name_saved != procedure_field_name
      synonym_procedure = SynonymCommonProcedure.find_by(name: procedure_field_name, organisation_id: @current_user.organisation_id, is_deleted: false)
      custom_procedure_found = CustomCommonProcedure.find_by(name: procedure_field_name, organisation_id: @current_user.organisation_id, is_deleted: false)
      translated_procedure_found = TranslatedCommonProcedure.find_by(name: procedure_field_name, organisation_id: @current_user.organisation_id, is_deleted: false)
    end

    respond_to do |format|
      format.json { render json: !synonym_procedure.present? && !custom_procedure_found.present? && !translated_procedure_found.present? }
    end
  end

  def data
    @custom_procedures_count = CustomCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false).count + SynonymCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false).count + TranslatedCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false).count
    @custom_common_procedure = CustomCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false)
                                                    .order('name ' + params[:sSortDir_0]) + SynonymCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false) + TranslatedCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false)
    start_point = params[:iDisplayStart].to_i
    end_point = (params[:iDisplayLength].to_i + params[:iDisplayStart].to_i - 1)
    @custom_common_procedure = @custom_common_procedure[start_point..end_point]
    @total_procedures_count = CustomCommonProcedure.where(organisation_id: @current_user.organisation_id, is_deleted: false).count + SynonymCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false).count + TranslatedCommonProcedure.where(name: /#{Regexp.escape(params[:sSearch])}/i, organisation_id: @current_user.organisation_id, is_deleted: false).count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def destroy
    @custom_common_procedure = CustomCommonProcedure.find(params[:id]) || SynonymCommonProcedure.find(params[:id]) || TranslatedCommonProcedure.find(params[:id])
    @custom_common_procedure.update_attributes(is_deleted: 'true')
  end

  def enable_procedure
    # @data_from = params[:data_from]
    @data_from = get_procedure_type(params[:data_from])
    @procedure = @data_from.constantize.find_by(id: params[:id])
    @procedure.update(is_deleted: false)
  end

  private

  def set_init_params
    @current_user = current_user
  end

  def get_procedure_type(procedure_type)
    ['CustomCommonProcedure', 'CommonProcedure', 'SynonymCommonProcedure', 'TranslatedCommonProcedure'].select{|procedure| procedure == procedure_type}.first
  end
  # EOF get_procedure_type
end
