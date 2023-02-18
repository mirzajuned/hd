class Investigation::RecordsController < ApplicationController
  layout "loggedin"
  before_action :authorize
  before_action :set_investigation_record, only: [:show, :edit, :update, :destroy]
  before_action :print_settings, only: [:show, :create, :update, :update_all_reports]

  # GET /investigation_records
  # GET /investigation_records.json
  def index
    @type = investigation_type
    @investigation_records = investigation_type.all
    # @lab_records = Investigation::Record.all
  end

  # GET /investigation_records/1
  # GET /investigation_records/1.json
  def show
    @type = @investigation_record._type
    @patient = Patient.find(@investigation_record.patient_id)
    @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
    @investigation_detail = Investigation::InvestigationDetail.find_by(investigation_record_id: @investigation_record.id)
    respond_to do |format|
      format.js {}
    end
  end

  # GET /investigation_records/new
  def new
    # params[:test]
    # params[:investigation_id] = '591bfbfd43fe4711142731f8'
    @action = 'create'
    @type = Investigation::InvestigationDetails::DocumentType.new(params[:investigation_id].to_s).get
    @investigation_advised = Investigation::InvestigationDetail.find(params[:investigation_id])
    @patient = Patient.find_by(id: @investigation_advised.patient_id)
    if @type.to_s == "LabRecord"
      @investigation_test = LaboratoryInvestigationData.find_by(:loinc_code => @investigation_advised.loinc_code, facility_id: current_facility.id)
      @investigation_record = @type.to_s.constantize.new

      @panel_ids = @investigation_test.panel_ids
      @panel_investigations = []
      if @panel_ids.present?
        @panel_ids.each do |panel_loinc_code|
          @panel_inv = LaboratoryInvestigationData.find_by(loinc_code: panel_loinc_code, facility_id: current_facility.id)
          @panel_investigations << @panel_inv
        end
        @panel_investigations.size.times { @investigation_record.panel_records.build }
      end

      1.times { @investigation_record.record_histories.build }
      @previous_values = Investigation::Record.where(patient_id: @investigation_advised.patient_id.to_s, loinc_code: @investigation_advised.loinc_code)
    else
      @previous_values = Investigation::Record.where(patient_id: @investigation_advised.patient_id.to_s, investigation_full_code: @investigation_advised.investigation_full_code)
      @investigation_record = @type.to_s.constantize.new
    end

    @form = "form"

    respond_to do |format|
      format.js {}
    end
  end

  def edit
    @form = "edit_form"
    @action = 'update'
    @investigation_advised = Investigation::InvestigationDetail.includes(:patient).find_by(id: @investigation_record.investigation_advised_id)
    @patient = Patient.find_by(id: @investigation_advised.patient_id)
    1.times { @investigation_record.record_histories.build }
    @type = @investigation_record._type
    if @type == 'LabRecord'
      @previous_values = Investigation::Record.where(patient_id: @investigation_record.patient_id.to_s, loinc_code: @investigation_record.loinc_code)
    else
      @previous_values = Investigation::Record.where(patient_id: @investigation_record.patient_id.to_s, investigation_full_code: @investigation_advised.investigation_full_code)
    end
    respond_to do |format|
      format.js {}
    end
  end

  # POST /investigation_records
  # POST /investigation_records.json
  def create
    @investigation_record = Investigation::Record.new(investigation_record_params)
    @investigation_record.performed_at = DateTime.parse(params[:investigation_record][:performed_at])
    @investigation_record.advised_at = DateTime.parse(params[:investigation_record][:advised_at])
    respond_to do |format|
      if @investigation_record.save
        @type = @investigation_record._type
        @patient = Patient.find(@investigation_record.patient_id)
        @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
        @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
        # update investigation workflow
        update_investigation_workflow
        investigation = Investigation::InvestigationDetail.find_by(investigation_record_id: @investigation_record.try(:id))
        @lab_record = LabRecord.find_by(id: investigation.try(:investigation_record_id))
        if @lab_record.present?
          @lab_record.update( template_created_by: investigation.try(:template_created_by), state: "nil")
        end
        @ehr_investigation_detail = EhrInvestigation::LaboratoryRecord.find_by(id: investigation.try(:ehr_investigation_record_id))
        if @ehr_investigation_detail.present?
          @ehr_investigation_detail.update(template_created_by: investigation.try(:template_created_by), state: "nil")
        end
        update_patient_opd_investigation
        format.js {}
        format.json { render :show, status: :created, location: @investigation_record }
      else
        format.html { render :new }
        format.json { render json: @investigation_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /investigation_records/1
  # PATCH/PUT /investigation_records/1.json
  def update
    respond_to do |format|
      if @investigation_record.update(update_investigation_record_params)
        @type = @investigation_record._type
        @patient = Patient.find(@investigation_record.patient_id)
        @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
        @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
        @investigation_detail = Investigation::InvestigationDetail.find_by(investigation_record_id: @investigation_record.id)
        @ehr_investigation_detail = EhrInvestigation::LaboratoryRecord.find_by(investigation_record_id: @investigation_record.id)
        @ehr_investigation_detail.update(doctors_remark: @investigation_record.doctors_remark) if @ehr_investigation_detail.present?
        # format.html { redirect_to @investigation_record, notice: 'investigation record was successfully updated.' }
        update_patient_opd_investigation
        format.js {}
        format.json { render :show, status: :ok, location: @investigation_record }

        @appointment = Appointment.find_by(id: @investigation_detail.appointment_id)
        CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation_detail, current_facility.id, current_user.id)
      else
        format.html { render :edit }
        format.json { render json: @investigation_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /investigation_records/1
  # DELETE /investigation_records/1.json
  def destroy
    @investigation_record.destroy
    respond_to do |format|
      format.html { redirect_to investigation_records_url, notice: 'investigation record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def print
    @investigation_record = Investigation::Record.find(params[:record_id])
    @patient = Patient.find(@investigation_record.patient_id)
    filename = "#{@investigation_record.name}_#{Date.current.strftime('%d_%m_%y')}"
    if @investigation_record._type == "LabRecord"
      @type = 'laboratory'
    elsif @investigation_record._type == "RadiologyRecord"
      @type = 'radiology'
    elsif @investigation_record._type == "OphthalmologyRecord"
      @type = 'ophthalmology'
    end
    @investigation_detail = Investigation::InvestigationDetail.find_by(investigation_record_id: @investigation_record.id)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, @type)
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render :template => "investigation/records/print", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, :top => @print_setting.try(:header_height).to_f * 10, :bottom =>  @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  def print_all
    @approved_flag = params[:approved_flag]
    @record_ids = params[:record_ids].split(',')

    options = {:id.in => @record_ids}
    if params[:approved_flag] == 'true'
      options[:state] = 'reviewed'
      @state = 'reviewed'
    else
      options[:state.ne] = 'reviewed'
      @state = ''
      #template_created_by, created_at
    end
    @investigation_records = Investigation::Record.where(options).order('performed_at DESC')
    @org_setting = current_user.organisation.organisations_setting
    @record = @investigation_records&.first
    if @record.present? && @org_setting.print_only_todays_peformed_investigations
      @investigation_records = @investigation_records.where(performed_at: { :$gte => @record.performed_at&.to_date || Date.today }) 
    end
    @type = @record._type[0..2].downcase if @record.present?
    @investigation_records = GroupBy::advised_and_performed(@investigation_records)

    @patient = Patient.find(params[:patient_id])
    @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
    @view = params[:view]
    filename = "Inv_#{Date.current.strftime('%d_%m_%y')}"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, @view)
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render :template => "investigation/records/print_all", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, :top => @print_setting.try(:header_height).to_f * 10, :bottom => @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  def upload_details
    investigation_id = params[:investigation_id]
    upload_id = params[:clicked_image_id]
    @investigation_detail = Investigation::InvestigationDetail.find_by(id: investigation_id)
    @investigation_record = Investigation::Record.find_by(investigation_advised_id: investigation_id)
    @current_image = PatientSummaryAssetUpload.find_by(id: upload_id)
    if @current_image.present?
      @tags = PatientAssetUploadTag.where(patient_summary_asset_upload_id: @current_image.id)
      @all_comments = @current_image.comments.where(is_deleted: false)
    else
      @tags = []
      @all_comments = []
    end
    if investigation_id.present?
      @all_current_investigation_uploads = PatientSummaryAssetUpload.where(investigation_detail_id: investigation_id,
                                                                           :id.nin => [@current_image&.id, nil],
                                                                           asset_type: 'image', is_deleted: false)
    else
      @all_current_investigation_uploads = []
    end
    # @comment = @current_image.comments.new
  end

  def pdf_upload_details
    investigation_id = params[:investigation_id]
    upload_id = params[:clicked_image_id]
    @investigation_detail = Investigation::InvestigationDetail.find_by(id: investigation_id)
    @investigation_record = Investigation::Record.find_by(investigation_advised_id: investigation_id)
    @current_pdf = PatientSummaryAssetUpload.find_by(id: upload_id)
    if @current_pdf.present?
      @tags = PatientAssetUploadTag.where(patient_summary_asset_upload_id: @current_pdf.id)
    else
      @tags = []
    end
    @all_current_investigation_uploads = PatientSummaryAssetUpload.find_by(id: @current_pdf, content_type: 'application/pdf')
    @pdf_path = @all_current_investigation_uploads.asset_path_url if @all_current_investigation_uploads.present?
  end

  def fetch_photo_details
    @current_image = PatientSummaryAssetUpload.find_by(id: params[:current_image_id])
    if params[:current_image_id].present? && @current_image.present?
      @tags = PatientAssetUploadTag.where(patient_summary_asset_upload_id: @current_image.id)
      @all_comments = @current_image.comments.where(is_deleted: false)
    else
      head :ok
    end
  end

  def add_investigation_fields
    @investigation_record = Investigation::Record.find_by(id: params[:investigation_id])
    1.times { @investigation_record.panel_records.build }
    @type = @investigation_record._type
  end

  def all_reports_new
    @current_facility = current_facility
    @investigation_ids = params[:investigation_ids]
    if @investigation_ids.nil?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'No performed Investigations', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      @patient = Patient.find_by(id: params[:patient_id])
      @patient_investigation = Investigation::InvestigationDetail.where(:id.in => @investigation_ids).order('created_at DESC')
      @investigation_record = Investigation::Record.new
      @investigation_tests = LaboratoryInvestigationData.where(:loinc_code.in => @patient_investigation.pluck(:loinc_code), facility_id: @current_facility.id)
      @panel_investigation = LaboratoryInvestigationData.where(:loinc_code.in => @investigation_tests.pluck(:panel_ids).flatten, facility_id: @current_facility.id)
    end
  end

  def create_all_reports
    params[:investigation_record].values.each_with_index do |investigation_record, i|
      params[:record] = investigation_record
      @investigation_record = Investigation::Record.create(all_investigation_params)
      update_investigation_workflow
    end
  end

  def edit_all_reports
    @record_ids_string = params[:record_ids]
    if !@record_ids_string.nil?
      @record_ids = @record_ids_string.split(',')
      @patient = Patient.find_by(id: params[:patient_id])
      @investigation_records = Investigation::Record.find(@record_ids)
    end
  end

  def update_all_reports
    @current_user = current_user
    @template_ids = []
    params[:investigation_record].values.each_with_index do |investigation_record, i|
      params[:record] = investigation_record
      investigation_record['id']
      @template_ids << investigation_record['id']
      @investigation_record = Investigation::Record.find_by(id: investigation_record['id'])
      @investigation_record.update(all_investigation_update_params)

      @investigation_advised = Investigation::InvestigationDetail.find_by(id: @investigation_record.investigation_advised_id)
      @appointment = Appointment.find_by(id: @investigation_advised.appointment_id)
      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation_advised, current_facility.id, current_user.id)
    end

    @patient = Patient.find(params[:investigation_record]['0'][:patient_id])

    @investigation_records = Investigation::Record.where(:id.in => @template_ids).order('advised_at DESC')
    @record = @investigation_records&.first
    @type = @record._type[0..2].downcase if @record.present?
    @lab_records = @investigation_records.where(_type: 'LabRecord')
    @radio_records = @investigation_records.where(_type: 'RadiologyRecord')
    @ophthal_records = @investigation_records.where(_type: 'OphthalmologyRecord')
    @lab_record_ids = @lab_records.pluck(:id).map(&:to_s)
    @radio_record_ids = @radio_records.pluck(:id).map(&:to_s)
    @ophthal_record_ids = @ophthal_records.pluck(:id).map(&:to_s)
    @lab_records = GroupBy::advised_and_performed(@lab_records)
    @radio_records = GroupBy::advised_and_performed(@radio_records)
    @ophthal_records = GroupBy::advised_and_performed(@ophthal_records) 
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def investigation_types
    ['LabRecord', 'RadiologyRecord', 'OphthalmologyRecord']
  end

  def investigation_type
    # params[:type].constantize if params[:type].in? investigation_types
    investigation_types.select{|type| type == params[:type]}.first&.constantize
  end

  def set_investigation_record
    @investigation_record = Investigation::Record.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def investigation_record_params
    params.require(:investigation_record).permit(:investigation_name, :specimen_type, :_type, :investigation_val, :normal_range, :appointment_id, :patient_id, :requested_by, :advised_by, :performed_by, :performed_at, :opd_record, :loinc_class, :loinc_code, :facility_id, :investigation, :name, :organisation_id, :investigation_advised_id, :test_category, :investigation_comment, :doctors_remark, :specimen_date, :opd_record_id, :investigation_full_code, panel_records_attributes: [:investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def update_investigation_record_params
    params.require(:investigation_record).permit(:investigation_name, :specimen_type, :investigation_val, :normal_range, :test_category, :investigation_comment, :doctors_remark, :specimen_date, panel_records_attributes: [:id, :investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def update_investigation_workflow
    @investigation_detail = Investigation::InvestigationDetail.find_by(id: @investigation_record.investigation_advised_id)
    @investigation_detail.update(investigation_record_id: @investigation_record.id, template_created_by: current_user.id, template_created_by_username: current_user.fullname, template_created_at_facility_id: current_facility.id, template_created_at_facility_name: current_facility.name, template_created_at: Time.current)
    @investigation_detail.template_created
    @investigation_queue = Investigation::Queue.find_by(patient_id: @investigation_detail.patient_id)
    @investigation_queue.update(status: "review")

    @appointment = Appointment.find_by(id: @investigation_detail.appointment_id)
    CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation_detail, current_facility.id, current_user.id)
  end

  def all_investigation_params
    params.require(:record).permit(:investigation_name, :specimen_type, :_type, :investigation_val, :normal_range, :appointment_id, :patient_id, :requested_by, :advised_by, :advised_at, :performed_by, :performed_at, :opd_record, :loinc_class, :loinc_code, :template_created_by, :facility_id, :investigation, :name, :organisation_id, :investigation_advised_id, :test_category, :investigation_comment, :specimen_date, :opd_record_id, :investigation_full_code, panel_records_attributes: [:investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def all_investigation_update_params
    params.require(:record).permit(:id, :patient_id, :investigation_name, :specimen_type, :investigation_val, :normal_range, :investigation_comment, :specimen_date, panel_records_attributes: [:_id, :investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def update_patient_opd_investigation
    @patient_opd = ::PatientOpd.find_by(id: @patient.id)

    if @patient_opd
      if @patient_opd.records.count > 0

        if @investigation_record.present?
          if @investigation_detail._type == "Investigation::Ophthal"
            update_investigation("ophthal_investigations_list")

          elsif @investigation_detail._type == "Investigation::Radiology"
            update_investigation("radiology_investigations_list")

          elsif @investigation_detail._type == "Investigation::Laboratory"

            if @investigation_detail.opd_record_id.present?
              patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.opd_record_id)

              if patient_opd_record.present?
                lab_investigations = patient_opd_record.laboratory_investigations_list.where(investigation_id: @investigation_detail.investigation_id.to_s, created_from_template: true)

                lab_investigations.try(:each) do |record|
                  if @investigation_record.panel_records.count > 0
                    record.laboratory_panel_records.destroy
                    @investigation_record.panel_records.each do |panel_record|
                      record.laboratory_panel_records.create(panel_record.attributes)
                    end
                  end
                end

                lab_investigations.update_all(investigation_comment: @investigation_record.investigation_comment, doctors_remark: @investigation_record.doctors_remark, investigation_val: @investigation_record.investigation_val, normal_range: @investigation_record.normal_range, specimen_type: @investigation_record.specimen_type)
              end
            else
              patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.investigation_patient_opd_record_id)
              if patient_opd_record
                saved_investigation = patient_opd_record.laboratory_investigations_list.find_by(investigation_detail_id: BSON::ObjectId.from_string(@investigation_record.investigation_advised_id))

                if saved_investigation
                  saved_investigation.update(investigation_comment: @investigation_record.investigation_comment, doctors_remark: @investigation_record.doctors_remark, investigation_val: @investigation_record.investigation_val, normal_range: @investigation_record.normal_range, specimen_type: @investigation_record.specimen_type)

                  if @investigation_record.panel_records.count > 0
                    saved_investigation.laboratory_panel_records.destroy

                    @investigation_record.panel_records.each do |panel_record|
                      saved_investigation.laboratory_panel_records.create(panel_record.attributes)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  # updates only radiology and ophthal investigations
  def update_investigation(investigation_type)
    if @investigation_detail.opd_record_id.present?
      patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.opd_record_id)

      if patient_opd_record.present?
        ophthal_investigations = patient_opd_record.instance_eval(investigation_type).where(investigation_id: @investigation_detail.investigation_id.to_s, created_from_template: true)
        ophthal_investigations.update_all(investigationname: @investigation_record.investigation_name, investigation_comment: @investigation_record.investigation_comment, doctors_remark: @investigation_record.doctors_remark, investigation_val: @investigation_record.investigation_val)
      end
    else
      patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.investigation_patient_opd_record_id)
      if patient_opd_record
        saved_investigation = patient_opd_record.instance_eval(investigation_type).find_by(investigation_detail_id: BSON::ObjectId.from_string(@investigation_record.investigation_advised_id))
        if saved_investigation
          saved_investigation.update(investigationname: @investigation_record.investigation_name, investigation_comment: @investigation_record.investigation_comment, doctors_remark: @investigation_record.doctors_remark, investigation_val: @investigation_record.investigation_val)
        end
      end
    end
  end

  def print_settings
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ["309935007", "261904005", "309964003"])
  end
end
