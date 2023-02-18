class Api::V1::DocumentsController < ApiApplicationController
  respond_to :pdf
  before_action :doorkeeper_authorize!

  def download
    raise Errors::NoParams, 'Params Missing' if params[:record_id].nil? || params[:record_name].nil?

    get_record(params[:record_name], params[:record_id])

    discharge_note if params[:record_name] == 'DischargeNote'

    respond_to do |format|
      format.pdf do
        render template: @template, locals: @locals, pdf: params[:record_name], layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', margin: { top: 30, bottom: 20 }
      end
    end
  rescue StandardError => e
    message = e.try(:message) || 'Invalid Request'

    @data_hash = { status_code: 400, message: message }

    render json: @data_hash
  end

  private

  def get_record(record_name, record_id)
    if record_name == 'DischargeNote'
      @ipd_record = ::Inpatient::IpdRecord.find_by(id: record_id)
      @record = @ipd_record&.discharge_note
    else
      @record = record_name.constantize.find_by(id: record_id)
    end
    raise Errors::FindByNil.new('Record', 'Record Id') if @record.nil?
  end

  def discharge_note
    @admission = Admission.find_by(id: @ipd_record.admission_id)

    @facility = Facility.find_by(id: @admission.facility_id)
    @organisation = Organisation.find_by(id: @facility.organisation_id)
    @patient = Patient.find_by(id: @record.patient_id)

    @current_user = User.find_by(id: @admission.user_id)
    @tpa = Inpatient::Insurance::Tpa.find_by(admission_id: @admission.id)
    specialty_path = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)

    @locals = { speciality: specialty_path, patient: @patient, case_sheet: @admission.case_sheet, tpa: @tpa,
                ipd_record: @ipd_record, current_facility: @facility, current_user: @current_user, view: 'Note',
                advice_language: '', language_flag: '', translated_language: '' }
    @template = 'inpatient/ipd_record/discharge_note/mail_record'
  end
end
