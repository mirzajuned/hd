class CustomIcdDiagnosesController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :find_specialties, only: [:index, :new, :edit]
  before_action :custom_icd_diagnosis, only: [:edit, :destroy]

  def index
    @disabled_icds = CustomIcdDiagnosis.where(organisation_id: current_user.organisation_id,
                                              specialty_id: @selected_specialty, is_deleted: true, root: 0) +
                     SynonymIcdDiagnosis.where(organisation_id: current_user.organisation_id,
                                               specialty_id: @selected_specialty, is_deleted: true) +
                     TranslatedIcdDiagnosis.where(organisation_id: current_user.organisation_id,
                                                  specialty_id: @selected_specialty, is_deleted: true)
  end

  def new
    @custom_icd_diagnosis = CustomIcdDiagnosis.new
    @languages = Language.where(country_ids: current_facility.country_id).pluck(:name, :lcid_code)
    @languages.delete(['English', 'en'])
  end

  def create
    if params[:custom_icd_type] == 'create_new_icd'
      @icd_diagnosis = CustomDiagnosis::CreateService.call(params[:custom_icd_diagnosis], current_user)
    elsif params[:custom_icd_type] == 'attach_icd'
      params[:synonym_icd_diagnosis][:specialty_id] = params[:custom_icd_diagnosis][:specialty_id]
      @icd_diagnosis = SynonymDiagnosis::CreateService.call(params[:synonym_icd_diagnosis])
    elsif params[:custom_icd_type] == 'translated_icd'
      params[:translated_icd_diagnosis][:specialty_id] = params[:custom_icd_diagnosis][:specialty_id]
      @icd_diagnosis = TranslatedDiagnosis::CreateService.call(params[:translated_icd_diagnosis], current_user)
    end
  end

  def edit; end

  def update
    @icd_diagnosis = if params[:icd_data_from] == 'custom_icd_diagnosis'
                       CustomDiagnosis::UpdateService.call(params[:custom_icd_diagnosis], params[:id])
                     elsif params[:icd_data_from] == 'synonym_icd_diagnosis'
                       SynonymDiagnosis::UpdateService.call(params[:synonym_icd_diagnosis], params[:id])
                     else
                       TranslatedDiagnosis::UpdateService.call(params[:translated_icd_diagnosis], params[:id])
                     end
  end

  def destroy
    if @custom_icd_diagnosis.has_children == true
      values = []
      @custom_icd_diagnosis.childrencodename.each { |cnm| values << cnm[1] }
      values.each.with_index do |value, _i|
        @children_icd_diagnosis = if @custom_icd_diagnosis.icd_type == 'TranslatedIcdDiagnosis'
                                    TranslatedIcdDiagnosis.find_by(code: value)
                                  else
                                    CustomIcdDiagnosis.find_by(code: value)
                                  end
        @children_icd_diagnosis&.update_attributes(is_deleted: true)
      end
    end
    @custom_icd_diagnosis.update_attributes(is_deleted: true)
  end

  def name_validation
    # validating 3 synonym fields ,if present
    icd_from = params[:icd_from]
    if icd_from == 'synonym'
      icd_name_entered = params[:synonym_icd_diagnosis][:fullname]
      if icd_name_entered['0'].present?
        icd_name = icd_name_entered['0']
      elsif icd_name_entered['1'].present?
        icd_name = icd_name_entered['1']
      elsif icd_name_entered['2'].present?
        icd_name = icd_name_entered['2']
      end
    elsif icd_from == 'custom'
      icd_name = params[:custom_icd_diagnosis][:fullname]
    end

    synonym_found = SynonymIcdDiagnosis.find_by(fullname: icd_name, organisation_id: current_user.organisation_id,
                                                is_deleted: false)
    custom_icd_found = CustomIcdDiagnosis.find_by(fullname: icd_name, organisation_id: current_user.organisation_id,
                                                  is_deleted: false)

    respond_to do |format|
      format.json { render json: !custom_icd_found.present? && !synonym_found.present? }
    end
  end

  def update_name_validation
    icd_from = params[:icd_from]
    icd_name_saved = params[:saved_icd_name]
    if icd_from == 'synonym'
      icd_field_name = params[:synonym_icd_diagnosis][:fullname]
    elsif icd_from == 'custom'
      icd_field_name = params[:custom_icd_diagnosis][:originalname]
    end

    if icd_name_saved != icd_field_name
      synonym_found = SynonymIcdDiagnosis.find_by(fullname: icd_field_name,
                                                  organisation_id: current_user.organisation_id, is_deleted: false)
      custom_icd_found = CustomIcdDiagnosis.find_by(fullname: icd_field_name,
                                                    organisation_id: current_user.organisation_id, is_deleted: false)
    end

    respond_to do |format|
      format.json { render json: !custom_icd_found.present? && !synonym_found.present? }
    end
  end

  def data
    @custom_icd_diagnosis_count = CustomIcdDiagnosis.where(originalname: /#{Regexp.escape(params[:sSearch])}/i,
                                                           organisation_id: current_user.organisation_id, root: 0,
                                                           specialty_id: params[:specialty_id], is_deleted: false)
                                                    .count +
                                  SynonymIcdDiagnosis.where(fullname: /#{Regexp.escape(params[:sSearch])}/i,
                                                            organisation_id: current_user.organisation_id,
                                                            specialty_id: params[:specialty_id], is_deleted: false)
                                                     .count +
                                  TranslatedIcdDiagnosis.where(fullname: /#{Regexp.escape(params[:sSearch])}/i,
                                                               organisation_id: current_user.organisation_id,
                                                               specialty_id: params[:specialty_id], is_deleted: false)
                                                        .count
    @custom_icd_diagnosis = CustomIcdDiagnosis.where(originalname: /#{Regexp.escape(params[:sSearch])}/i,
                                                     organisation_id: current_user.organisation_id, is_deleted: false,
                                                     specialty_id: params[:specialty_id], root: 0)
                                              .order('name ' + params[:sSortDir_0]) +
                            SynonymIcdDiagnosis.where(fullname: /#{Regexp.escape(params[:sSearch])}/i,
                                                      organisation_id: current_user.organisation_id,
                                                      specialty_id: params[:specialty_id], is_deleted: false) +
                            TranslatedIcdDiagnosis.where(fullname: /#{Regexp.escape(params[:sSearch])}/i,
                                                         organisation_id: current_user.organisation_id,
                                                         specialty_id: params[:specialty_id], is_deleted: false)
    start_point = params[:iDisplayStart].to_i
    end_point = (params[:iDisplayLength].to_i + params[:iDisplayStart].to_i - 1)
    @custom_icd_diagnosis = @custom_icd_diagnosis[start_point..end_point]
    @total_icd_diagnosis_count = CustomIcdDiagnosis.where(organisation_id: current_user.organisation_id,
                                                          specialty_id: params[:specialty_id], is_deleted: false,
                                                          root: 0).count + SynonymIcdDiagnosis
                                 .where(organisation_id: current_user.organisation_id,
                                        specialty_id: params[:specialty_id], is_deleted: false)
                                 .count + TranslatedIcdDiagnosis
                                 .where(organisation_id: current_user.organisation_id,
                                        specialty_id: params[:specialty_id], is_deleted: false).count
    @s_echo = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def enable_diagnosis
    @data_from = params[:data_from]

    if @data_from == 'SynonymIcdDiagnosis'
      @icd_diagnosis = SynonymIcdDiagnosis.find_by(id: params[:id])
      @icd_diagnosis.update(is_deleted: false)
    elsif @data_from == 'TranslatedIcdDiagnosis'
      @icd_diagnosis = TranslatedIcdDiagnosis.find_by(id: params[:id])
      @icd_diagnosis.update!(is_deleted: false)
    else
      @icd_diagnosis = CustomIcdDiagnosis.find_by(id: params[:id])
      @icd_diagnosis.update(is_deleted: false)
      @has_children = @icd_diagnosis.has_children
      if @has_children
        values = ['1', '2', '3', '4']
        values.each.with_index do |value, _i|
          @children_code = @icd_diagnosis.code.to_s + value
          @children_icd_diagnosis = CustomIcdDiagnosis.find_by(code: @children_code)
          @children_icd_diagnosis.update_attributes(is_deleted: false)
        end
      end
    end
  end

  private

  def find_specialties
    @org_id = current_user.organisation_id
    @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @selected_specialty = params[:specialty_id] || @available_specialties.first.id
  end

  def custom_icd_diagnosis
    @custom_icd_diagnosis = CustomIcdDiagnosis.find_by(id: params[:id]) ||
                            SynonymIcdDiagnosis.find_by(id: params[:id]) ||
                            TranslatedIcdDiagnosis.find_by(id: params[:id])
  end
end
