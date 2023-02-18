class CustomConsentsController < ApplicationController
  before_action :authorize
  before_action :find_specialties, only: [:new, :edit, :index]
  before_action :set_custom_consent, only: [:edit, :update, :destroy]
  before_action :set_languages, only: [:new, :edit]
  before_action :print_settings, only: [:ipd_preview]

  def new
    @custom_consent = CustomConsent.new
    @level = params[:level]
  end

  def create
    @custom_consent = CustomConsent.new(custom_params)
    @level = params[:custom_consent][:level]

    @custom_consent.save
  end

  def edit
    @level = params[:level]
  end

  def update
    @level = params[:custom_consent][:level]
    @custom_consent.update!(custom_params)
  end

  def destroy
    @custom_consent.update_attributes(is_deleted: true)
  end

  def index
    @level = 'organisation'
    find_specialties
    organisation_id = current_user.organisation_id
    @custom_consent_count = CustomConsent.where(organisation_id: organisation_id, level: @level, is_deleted: false)
                                         .count
    @specialty_name = Specialty.where(id: params[:specialty_id]).name
    @custom_consent = CustomConsent.where(organisation_id: organisation_id, level: @level, is_deleted: false)
                                  .limit(params[:iDisplayLength])
                                  .offset(params[:iDisplayStart])
    @total_custom_concent_count = CustomConsent.where(organisation_id: organisation_id, level: @level,
                                                      is_deleted: false)
                                              .count
  end

  def data
    # organisation level
    @level = params[:level]
    organisation_level_data
    @s_echo = params[:sEcho]
  end

  def ipd_preview_custom_consent
    if params[:specialty_id].present?
      custom_consents = CustomConsent.where(organisation_id: current_user.organisation_id, is_deleted: false, specialty_id: params[:specialty_id])
    else
      custom_consents = CustomConsent.where(organisation_id: current_user.organisation_id, is_deleted: false)
    end
  end

  def ipd_preview
    @admission = Admission.find_by(id: params[:admission_id])
    @available_specialties = Specialty.where(:id.in => current_facility['specialty_ids'])
    @selected_specialty = params[:specialty_id]
    custom_consents = CustomConsent.where(organisation_id: current_user.organisation_id, is_deleted: false, specialty_id: params[:specialty_id])
    @custom_consents = custom_consents.map do |cc|
      { id: cc.id.to_s, name: cc.name, languages: cc.language_consent_subsets.pluck(:language) }
    end
  end

  def ipd_preview_content
    @available_specialties = Specialty.where(:id.in => current_facility['specialty_ids'])
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @custom_consent = CustomConsent.find_by(id: params[:custom_consent_id])
    @language_consent = @custom_consent.language_consent_subsets.find_by(language: params[:language])
    @selected_specialty = params[:specialty_id]
  end

  def print_ipd_consent
    @available_specialties = Specialty.where(:id.in => current_facility['specialty_ids'])
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    if params[:custom_consent_id].present?
      @custom_consent = CustomConsent.find_by(id: params[:custom_consent_id])
      @language_consent = @custom_consent.language_consent_subsets.find_by(language: params[:language])
    end
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      print_attributes(format, 'custom_consents/print_ipd_consent', '', @print_setting)
    end
  end

  private

  def find_specialties
    # organisation level
    @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @level_name = current_organisation['name']
    @selected_specialty = params[:specialty_id]
  end

  def custom_params
    params.require(:custom_consent).permit(
      :user_id, :facility_id, :organisation_id, :level, :name, :specialty_id,
      language_consent_subsets_attributes: [:id, :_destroy, :language, :content]
    )
  end

  def set_custom_consent
    @custom_consent = CustomConsent.find_by(id: params[:id])
  end

  def set_languages
    @languages = Language.where(country_ids: current_facility.country_id)
  end

  def organisation_level_data
    organisation_id = current_user.organisation_id
    if params[:specialty_id].present?
      @custom_consent_count = CustomConsent.where(organisation_id: organisation_id, level: @level, is_deleted: false,
                                                  specialty_id: params[:specialty_id])
                                          .count
      @specialty_name = Specialty.where(id: params[:specialty_id]).name
      @custom_consent = CustomConsent.where(organisation_id: organisation_id, specialty_id: params[:specialty_id], level: @level, is_deleted: false,
                                            name: /#{Regexp.escape(params[:sSearch])}/i)
                                    .limit(params[:iDisplayLength])
                                    .offset(params[:iDisplayStart])
                                    .order("name #{params[:sSortDir_0]}")
      @total_custom_concent_count = CustomConsent.where(organisation_id: organisation_id, level: @level,
                                                        is_deleted: false, specialty_id: params[:specialty_id])
                                                .count
    else
      @custom_consent_count = CustomConsent.where(organisation_id: organisation_id, level: @level, is_deleted: false,
                                                name: /#{Regexp.escape(params[:sSearch])}/i)
                                         .count
      @specialty_name = Specialty.where(id: params[:specialty_id]).name
      @custom_consent = CustomConsent.where(organisation_id: organisation_id, level: @level, is_deleted: false,
                                            name: /#{Regexp.escape(params[:sSearch])}/i)
                                    .limit(params[:iDisplayLength])
                                    .offset(params[:iDisplayStart])
                                    .order("name #{params[:sSortDir_0]}")
      @total_custom_concent_count = CustomConsent.where(organisation_id: organisation_id, level: @level,
                                                        is_deleted: false)
                                                .count
    end
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end
end
