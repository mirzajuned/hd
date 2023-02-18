class ConsolidateReportsController < ApplicationController
  before_action :authorize
  before_action :find_patient_appointment, :set_speciality_folder_name, only: [:index, :template_filter]

  def index
    @consolidate_report = 'true'
    current_organisations_setting
    find_patient_template_summary_timeline
    @date_filter = [{ 'displayname' => 'DATE', 'templatename' => 'date' }]
    @opd_templates = Global.send(@speciality_folder_name).send('opdtemplates')
    @ipd_templates = [{ 'displayname' => 'Clinical Note', 'templatename' => 'Clinical Note' },
                      { 'displayname' => 'Operative Note', 'templatename' => 'Operative Note' },
                      { 'displayname' => 'Discharge Note', 'templatename' => 'Discharge Note' }]
    @drop_down_filter = @date_filter.concat(@opd_templates).concat(@ipd_templates)
    @patient_legacy_appointment = LegacyAppointment.where(new_patient_id: params[:patient_id],
                                                          organisation_id: current_user.organisation_id.to_s)
    @patient_legacy = LegacyPatient.find_by(new_patient_id: params[:patient_id],
                                            organisation_id: current_user.organisation_id.to_s)
    @camp_patient_data = CampPatient.find_by(patient_id: params[:patient_id])
    advice_set_languages
    print_settings
  end

  def template_filter
    @templatetype = get_template_types(params[:template_type])
    @consolidate_report = 'true'
    current_organisations_setting
    if ['Clinical Note', 'Operative Note', 'Discharge Note'].include?(@templatetype)
      @ipd_record = Inpatient::IpdRecord.where(patient_id: @patient.id)
    elsif @templatetype == 'date'
      find_patient_template_summary_timeline
    else
      @opd_record = OpdRecord.where(patientid: @patient.id.to_s, templatetype: @templatetype)
    end
    advice_set_languages
    print_settings
  end

  private

  def find_patient_template_summary_timeline
    @patient_report = PatientSummaryTimeline.where(patient_id: @patient.id,
                                                   :primary_model.in => ['OpdRecord', 'Inpatient::IpdRecord'],
                                                   specialty_id: params[:specialty_id],
                                                   is_active: true)
                                            .order(encounter_date: :desc)
    @patient_timeline_dates = @patient_report.group_by(&:encounter_date)
  end

  def find_patient_appointment
    @patient = Patient.find(params[:patient_id])
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
  end

  def set_speciality_folder_name
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:specialty_id])
  end

  def advice_set_languages
    @advice_set_language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'],
                            ['Tamil', 'ta'], ['Telugu', 'te'], ['Gujarati', 'gu']]
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['485396012', '486546481'])
  end

  def current_organisations_setting
    @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
  end

  def get_template_types(template_type)
    ['Clinical Note', 'Operative Note', 'Discharge Note', 'date', 'eye', 'lens', 'pmt', 'quickeye', 'trauma', 'freeform', 'optometrist', 'postop', 'paediatrics', 'orthoptics', 'express', 'elbow', 'vision'].select{|t_type| t_type == template_type}.first
  end
  # EOF get_template_types
end
