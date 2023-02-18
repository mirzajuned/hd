class OrganisationSettingsController < ApplicationController
  before_action :authorize
  before_action :set_organisation_setting
  before_action :opd_templates, only: [:edit, :update, :show]

  def validate_patient; end

  def update_validate_patient
    @organisation_setting.update_attributes(validate_patient: params[:validate_patient])

    head :no_content
  end

  def edit; end

  def update
    if @organisation_setting.update(organisation_setting_params)
      flash[:error] = nil
      render :show
    else
      flash[:error] = @organisation_setting.errors.full_messages.to_sentence
      render :edit
    end
  end

  def show; end

  def auto_requisition; end

  def save_auto_requisition
    type = params[:organisations_setting][:auto_requisition_type]
    value = params[:organisations_setting][:auto_requisition_value]
    @organisation_setting.update!(auto_requisition_type: type, auto_requisition_value: value,
                                  auto_requisition_enabled: true)
  end

  private

  def set_organisation_setting
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end

  def organisation_setting_params
    params.require(:organisations_setting).permit(
      :disable_clone_old_template, :print_only_todays_peformed_investigations, 
      :organisation_notification_enabled,
      :disable_opd_templates, :disable_opd_templates_duration, :time_slots_enabled,
      :organisation_whatsapp_enabled, :communication_number_id, :disable_visit_fields,
      :organisation_account_sid, allowed_opd_templates: {}
    )
  end

  def specialties
    Specialty.where(:id.in => current_organisation['specialty_ids'])
  end

  def opd_templates
    @opd_templates = {}
    specialties.each do |specialty|
      specialty_name = specialty.name.downcase
      blank_form = if specialty_name == 'ophthalmology'
                     [{ 'displayname' => 'Blank Form', 'templatename' => 'blank_form' }]
                   else
                     []
                   end

      @opd_templates[specialty_name] = Global.send(specialty.underscored_name).send('opdtemplates') + blank_form
    end
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
  end
end
