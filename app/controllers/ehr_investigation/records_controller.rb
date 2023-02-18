class EhrInvestigation::RecordsController < ApplicationController
  layout "loggedin"
  before_action :authorize
  before_action :set_ehr_investigation_record, only: [:show, :edit, :update, :destroy]
  before_action :print_settings, only: [:show, :create, :update, :update_all_reports, :show_all_reports]

  # GET /ehr_investigation_records
  # GET /ehr_investigation_records.json
  def index
    @type = investigation_type
    @ehr_investigation_records = investigation_type.all
    # @lab_records = Investigation::Record.all
  end

  # GET /ehr_investigation_records/1
  # GET /ehr_investigation_records/1.json
  def show
    @type = @ehr_investigation_record._type
    @patient = Patient.find(@ehr_investigation_record.patient_id)
    @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
    @investigation_detail = Investigation::InvestigationDetail.find_by(ehr_investigation_record_id: @ehr_investigation_record.id)
    respond_to do |format|
      format.js {}
    end
  end

  def new
    @action = 'create'
    @type = Investigation::InvestigationDetails::DocumentType.new(params[:investigation_id].to_s).get_ehr_investigation_type
    @investigation_advised = Investigation::InvestigationDetail.find_by(id: params[:investigation_id])
    @patient = Patient.find_by(id: @investigation_advised.patient_id)
    @calculate_age = @patient.calculate_age
    if @type.to_s == "EhrInvestigation::LaboratoryRecord"
      @ehr_investigation_record = @type.to_s.constantize.new
      @investigation_test = LaboratoryInvestigationData.find_by(:loinc_code => @investigation_advised.loinc_code, facility_id: current_facility.id)

      @panel_ids = @investigation_test.panel_ids
      @panel_investigations = []
      if @panel_ids.present?
        @panel_ids.each do |panel_loinc_code|
          @panel_inv = LaboratoryInvestigationData.find_by(loinc_code: panel_loinc_code, facility_id: current_facility.id)
          @panel_investigations << @panel_inv
        end
        @panel_investigations.size.times { @ehr_investigation_record.panel_records.build }
      end

      1.times { @ehr_investigation_record.record_histories.build }

      @previous_values = EhrInvestigation::Record.where(patient_id: @investigation_advised.patient_id.to_s, loinc_code: @investigation_advised.loinc_code)

    else
      @ehr_investigation_record = @type.to_s.constantize.new
      1.times { @ehr_investigation_record.record_histories.build }
      @previous_values = EhrInvestigation::Record.where(patient_id: @investigation_advised.patient_id.to_s, investigation_full_code: @investigation_advised.investigation_full_code)
    end

    @form = "form"

    respond_to do |format|
      format.js {}
    end
  end

  # GET /ehr_investigation_records/1/edit
  def edit
    @form = "edit_form"
    @action = 'update'
    @investigation_advised = Investigation::InvestigationDetail.includes(:patient).find_by(id: @ehr_investigation_record.investigation_advised_id)
    @patient = Patient.find_by(id: @investigation_advised.patient_id)
    1.times { @ehr_investigation_record.record_histories.build }
    @type = @ehr_investigation_record._type
    if @type == 'EhrInvestigation::LaboratoryRecord'
      @previous_values = EhrInvestigation::Record.where(patient_id: @ehr_investigation_record.patient_id.to_s, loinc_code: @ehr_investigation_record.loinc_code).to_a
    else
      @previous_values = EhrInvestigation::Record.where(patient_id: @investigation_advised.patient_id.to_s, investigation_full_code: @investigation_advised.investigation_full_code).to_a
    end
    respond_to do |format|
      format.js {}
    end
  end

  # POST /ehr_investigation_records
  # POST /ehr_investigation_records.json
  def create
    @ehr_investigation_record = EhrInvestigation::Record.new(ehr_investigation_record_params)
    @ehr_investigation_record.performed_at = DateTime.parse params[:ehr_investigation_record][:performed_at]
    @ehr_investigation_record.advised_at = DateTime.parse(params[:ehr_investigation_record][:advised_at])
    respond_to do |format|
      if @ehr_investigation_record.save
        @type = @ehr_investigation_record._type
        @patient = Patient.find_by(id: @ehr_investigation_record.patient_id)
        @calculate_age = @patient.calculate_age
        @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
        @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
        # update investigation workflow
        update_investigation_workflow
        @investigation_detail = Investigation::InvestigationDetail.find_by(ehr_investigation_record_id: @ehr_investigation_record.id)
        update_patient_opd_investigation
        format.js {}
        format.json { render :show, status: :created, location: @ehr_investigation_record }
      else
        format.html { render :new }
        format.json { render json: @ehr_investigation_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ehr_investigation_records/1
  # PATCH/PUT /ehr_investigation_records/1.json
  def update
    respond_to do |format|
      if @ehr_investigation_record.update(update_ehr_investigation_record_params)
        @type = @ehr_investigation_record._type
        @patient = Patient.find_by(id: @ehr_investigation_record.patient_id)
        @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
        @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
        # format.html { redirect_to @ehr_investigation_record, notice: 'investigation record was successfully updated.' }
        @investigation_detail = Investigation::InvestigationDetail.find_by(ehr_investigation_record_id: @ehr_investigation_record.id)
        update_patient_opd_investigation
        format.js {}
        format.json { render :show, status: :ok, location: @ehr_investigation_record }

        @appointment = Appointment.find_by(id: @investigation_detail.appointment_id)
        CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation_detail, current_facility.id, current_user.id)
      else
        format.html { render :edit }
        format.json { render json: @ehr_investigation_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ehr_investigation_records/1
  # DELETE /ehr_investigation_records/1.json
  def destroy
    @ehr_investigation_record.destroy
    respond_to do |format|
      format.html { redirect_to ehr_investigation_records_url, notice: 'investigation record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def print
    @ehr_investigation_record = EhrInvestigation::Record.find_by(id: params[:record_id])
    @patient = Patient.find_by(id: @ehr_investigation_record.patient_id)
    @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
    filename = "#{@ehr_investigation_record.name}_#{Date.current.strftime('%d_%m_%y')}"
    if @ehr_investigation_record._type == "EhrInvestigation::LaboratoryRecord"
      @type = 'laboratory'
    elsif @ehr_investigation_record._type == "EhrInvestigation::RadiologyRecord"
      @type = 'radiology'
    elsif @ehr_investigation_record._type == "EhrInvestigation::OphthalmologyRecord"
      @type = 'ophthalmology'
    end
    @investigation_detail = Investigation::InvestigationDetail.find_by(ehr_investigation_record_id: @ehr_investigation_record.id)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, @type)
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render :template => "ehr_investigation/records/print", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, :top => @print_setting.try(:header_height).to_f * 10, :bottom =>  @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  def print_all
    @approved_flag = params[:approved_flag]
    @record_ids = params[:record_ids].split(',')
    @ehr_investigation_records = EhrInvestigation::Record.find(@record_ids)
    @patient = Patient.find_by(id: params[:patient_id])
    @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
    @view = params[:view]

    options = {:id.in => @record_ids}
    if params[:approved_flag] == 'true'
      options[:state] = 'reviewed'
      @state = 'reviewed'
    else
      options[:state.ne] = 'reviewed'
      @state = ''
    end
    @investigation_records = EhrInvestigation::Record.where(options).order('performed_at DESC')
    @org_setting = current_user.organisation.organisations_setting
    @record = @investigation_records&.first
    if @record.present? && @org_setting.print_only_todays_peformed_investigations
      @investigation_records = @investigation_records.where(performed_at: { :$gte => @record.performed_at&.to_date || Date.today }) 
    end
    @type = @record._type[18..20].downcase if @record.present?
    @state = @record.try(:state)
    @investigation_records = GroupBy::advised_and_performed(@investigation_records)

    filename = "Inv_#{Date.current.strftime('%d_%m_%y')}"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, @view)
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      format.pdf { render :template => "ehr_investigation/records/print_all", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, :top => @print_setting.try(:header_height).to_f * 10, :bottom => @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  def add_investigation_fields
    @ehr_investigation_record = EhrInvestigation::Record.find_by(id: params[:investigation_id])
    1.times { @ehr_investigation_record.panel_records.build }
    @type = @ehr_investigation_record._type
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
      @calculate_age = @patient.calculate_age
      @patient_investigation = Investigation::InvestigationDetail.where(:id.in => @investigation_ids).order('created_at DESC')
      @ehr_investigation_record = EhrInvestigation::Record.new
      @investigation_tests = LaboratoryInvestigationData.where(:loinc_code.in => @patient_investigation.pluck(:loinc_code), facility_id: @current_facility.id)
      @panel_investigation = LaboratoryInvestigationData.where(:loinc_code.in => @investigation_tests.pluck(:panel_ids).flatten, facility_id: @current_facility.id)
    end
  end

  def create_all_reports
    params[:ehr_investigation_record].values.each_with_index do |ehr_investigation_record, i|
      params[:record] = ehr_investigation_record
      @ehr_investigation_record = EhrInvestigation::Record.create(all_investigation_params)
      @patient = Patient.find_by(id: @ehr_investigation_record.patient_id)
      @investigation_detail = Investigation::InvestigationDetail.find_by(id: @ehr_investigation_record.investigation_advised_id.to_s)
      update_investigation_workflow
      update_patient_opd_investigation
    end
  end

  def edit_all_reports
    @record_ids_string = params[:record_ids]
    if !@record_ids_string.nil?
      @record_ids = @record_ids_string.split(',')
      @patient = Patient.find_by(id: params[:patient_id])
      @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
      @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
      @ehr_investigation_records = EhrInvestigation::Record.find(@record_ids)
    end
  end

  def update_all_reports
    @template_ids = []
    params[:ehr_investigation_record].values.each_with_index do |ehr_investigation_record, i|
      params[:record] = ehr_investigation_record
      ehr_investigation_record['id']
      @template_ids << ehr_investigation_record['id']
      @ehr_investigation_record = EhrInvestigation::Record.find_by(id: ehr_investigation_record['id'])
      @ehr_investigation_record.update(all_investigation_update_params)

      @investigation_advised = Investigation::InvestigationDetail.find_by(id: @ehr_investigation_record.investigation_advised_id)
      @appointment = Appointment.find_by(id: @investigation_advised.appointment_id)
      CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation_advised, current_facility.id, current_user.id)
    end
    @patient = Patient.find(params[:ehr_investigation_record]['0'][:patient_id])
    @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
    # @lab_records = EhrInvestigation::LaboratoryRecord.where(:id.in => @template_ids)
    # @radio_records = EhrInvestigation::RadiologyRecord.where(:id.in => @template_ids)
    # @ophthal_records = EhrInvestigation::OphthalmologyRecord.where(:id.in => @template_ids)
    @investigation_records = EhrInvestigation::Record.where(:id.in => @template_ids).order('advised_at DESC')

    @lab_records = @investigation_records.where(_type: 'EhrInvestigation::LaboratoryRecord')
    @radio_records = @investigation_records.where(_type: 'EhrInvestigation::RadiologyRecord')
    @ophthal_records = @investigation_records.where(_type: 'EhrInvestigation::OphthalmologyRecord')

    @lab_record_ids = @lab_records.pluck(:id).map(&:to_s)
    @radio_record_ids = @radio_records.pluck(:id).map(&:to_s)
    @ophtal_record_ids = @ophthal_records.pluck(:id).map(&:to_s)

    @record = @investigation_records&.first
    @type = @record._type[18..20].downcase
    @state = @record.try(:state)

    @lab_records = GroupBy::advised_and_performed(@lab_records)
    @radio_records = GroupBy::advised_and_performed(@radio_records)
    @ophthal_records = GroupBy::advised_and_performed(@ophthal_records) 
end

  def show_all_reports
    @current_user = current_user
    @template_ids = params[:template_ids]
    if @template_ids.nil?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'No Records Found', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      @patient = Patient.find_by(id: params[:patient_id])
      @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
      @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
      # @lab_records = EhrInvestigation::LaboratoryRecord.where(:id.in => @template_ids).order('advised_at DESC')
      # @lab_record_ids = @lab_records.pluck(:id).map(&:to_s)
      # @lab_records = @lab_records.group_by { |lab| 
      #     [lab.advised_at.strftime('%d/%m/%Y'), lab.advised_by, lab.performed_at.strftime('%d/%m/%Y'), lab.performed_by]
      #   }
      # @radio_records = EhrInvestigation::RadiologyRecord.where(:id.in => @template_ids)
      # @ophthal_records = EhrInvestigation::OphthalmologyRecord.where(:id.in => @template_ids)

      @investigation_records = EhrInvestigation::Record.where(:id.in => @template_ids).order('advised_at DESC')

      @lab_records = @investigation_records.where(_type: 'EhrInvestigation::LaboratoryRecord')
      @radio_records = @investigation_records.where(_type: 'EhrInvestigation::RadiologyRecord')
      @ophthal_records = @investigation_records.where(_type: 'EhrInvestigation::OphthalmologyRecord')

      @lab_record_ids = @lab_records.pluck(:id).map(&:to_s)
      @radio_record_ids = @radio_records.pluck(:id).map(&:to_s)
      @ophtal_record_ids = @ophthal_records.pluck(:id).map(&:to_s)

      @record = @investigation_records&.first
      @type = @record._type[18..20].downcase
      @state = @record.try(:state)

      @lab_records = GroupBy::advised_and_performed(@lab_records)
      @radio_records = GroupBy::advised_and_performed(@radio_records)
      @ophthal_records = GroupBy::advised_and_performed(@ophthal_records)      
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def investigation_types
    ['EhrInvestigation::LaboratoryRecord', 'EhrInvestigation::RadiologyRecord', 'EhrInvestigation::OphthalmologyRecord']
  end

  def investigation_type
    # params[:type].constantize if params[:type].in? investigation_types
    investigation_types.select{|type| type == params[:type]}.first&.constantize
  end

  def set_ehr_investigation_record
    @ehr_investigation_record = EhrInvestigation::Record.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def ehr_investigation_record_params
    params.require(:ehr_investigation_record).permit(:doctors_remark, :specimen_type, :investigation_name, :_type, :investigation_val, :normal_range, :appointment_id, :patient_id, :requested_by, :advised_by, :performed_by, :performed_at, :opd_record, :loinc_class, :loinc_code, :facility_id, :investigation, :name, :organisation_id, :investigation_advised_id, :test_category, :investigation_comment, :specimen_date, :opd_record_id, :investigation_full_code, panel_records_attributes: [:investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def update_ehr_investigation_record_params
    params.require(:ehr_investigation_record).permit(:doctors_remark, :specimen_type, :investigation_name, :investigation_val, :normal_range, :test_category, :investigation_comment, :specimen_date, panel_records_attributes: [:id, :investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def update_investigation_workflow
    @current_facility = current_facility
    @current_user = current_user
    @investigation_advised = Investigation::InvestigationDetail.find_by(id: @ehr_investigation_record.investigation_advised_id)
    @investigation_advised.update(ehr_investigation_record_id: @ehr_investigation_record.id, template_created_by: @current_user.id, template_created_by_username: @current_user.fullname, template_created_at_facility_id: @current_facility.id, template_created_at_facility_name: @current_facility.name, template_created_at: Time.current)
    @investigation_advised.template_created

    @appointment = Appointment.find_by(id: @investigation_advised.appointment_id)
    CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation_advised, current_facility.id, current_user.id)
  end

  def all_investigation_params
    params.require(:record).permit(:doctors_remark, :specimen_type, :investigation_name, :_type, :investigation_val, :normal_range, :appointment_id, :template_created_by, :patient_id, :requested_by, :advised_by, :advised_at, :performed_by, :performed_at, :opd_record, :loinc_class, :loinc_code, :facility_id, :investigation, :name, :organisation_id, :investigation_advised_id, :test_category, :investigation_comment, :specimen_date, :opd_record_id, :investigation_full_code, panel_records_attributes: [:investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def all_investigation_update_params
    params.require(:record).permit(:id, :doctors_remark, :specimen_type, :investigation_name, :investigation_val, :normal_range, :investigation_comment, :specimen_date, panel_records_attributes: [:_id, :investigation_name, :investigation_val, :normal_range], record_histories_attributes: [:user_id, :template_type, :actiontime, :action])
  end

  def update_patient_opd_investigation
    @patient_opd = PatientOpd.find_by(id: @patient.id)

    if @patient_opd
      if @patient_opd.records.count > 0
        if @ehr_investigation_record.present?
          if @ehr_investigation_record._type == "EhrInvestigation::OphthalmologyRecord"
            update_investigation("ophthal_investigations_list")

          elsif @ehr_investigation_record._type == "EhrInvestigation::RadiologyRecord"
            update_investigation("radiology_investigations_list")

          elsif @ehr_investigation_record._type == "EhrInvestigation::LaboratoryRecord"

            if @investigation_detail.opd_record_id.present?
              patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.opd_record_id)

              if patient_opd_record.present?
                lab_investigations = patient_opd_record.laboratory_investigations_list.where(investigation_id: @investigation_detail.investigation_id.to_s, created_from_template: true)

                lab_investigations.try(:each) do |record|
                  if @ehr_investigation_record.panel_records.count > 0
                    record.laboratory_panel_records.destroy
                    @ehr_investigation_record.panel_records.each do |panel_record|
                      record.laboratory_panel_records.create(panel_record.attributes)
                    end
                  end
                end

                lab_investigations.update_all(investigationname: @ehr_investigation_record.investigation_name, investigation_comment: @ehr_investigation_record.investigation_comment, doctors_remark: @ehr_investigation_record.doctors_remark, investigation_val: @ehr_investigation_record.investigation_val, normal_range: @ehr_investigation_record.normal_range, specimen_type: @ehr_investigation_record.specimen_type)
              end
            else
              patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.investigation_patient_opd_record_id)
              if patient_opd_record
                saved_investigation = patient_opd_record.laboratory_investigations_list.find_by(investigation_detail_id: BSON::ObjectId.from_string(@ehr_investigation_record.investigation_advised_id))

                if saved_investigation
                  if @ehr_investigation_record.panel_records.count > 0
                    saved_investigation.laboratory_panel_records.destroy

                    @ehr_investigation_record.panel_records.each do |panel_record|
                      saved_investigation.laboratory_panel_records.create(panel_record.attributes)
                    end
                  end
                  saved_investigation.update(investigationname: @ehr_investigation_record.investigation_name, investigation_comment: @ehr_investigation_record.investigation_comment, doctors_remark: @ehr_investigation_record.doctors_remark, investigation_val: @ehr_investigation_record.investigation_val, normal_range: @ehr_investigation_record.normal_range, specimen_type: @ehr_investigation_record.specimen_type)
                end
              end
            end
          end
        end
      end
    end
  end

  def update_investigation(investigation_type)
    if @investigation_detail.opd_record_id.present?
      patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.opd_record_id)

      if patient_opd_record.present?
        ophthal_investigations = patient_opd_record.instance_eval(investigation_type).where(investigation_id: @investigation_detail.investigation_id.to_s, created_from_template: true)
        ophthal_investigations.update_all(investigationname: @ehr_investigation_record.investigation_name, investigation_comment: @ehr_investigation_record.investigation_comment, doctors_remark: @ehr_investigation_record.doctors_remark, investigation_val: @ehr_investigation_record.investigation_val)
      end
    else
      patient_opd_record = @patient_opd.records.find_by(id: @investigation_detail.investigation_patient_opd_record_id)
      if patient_opd_record
        saved_investigation = patient_opd_record.instance_eval(investigation_type).find_by(investigation_detail_id: BSON::ObjectId.from_string(@ehr_investigation_record.investigation_advised_id))
        if saved_investigation
          saved_investigation.update(investigationname: @ehr_investigation_record.investigation_name, investigation_comment: @ehr_investigation_record.investigation_comment, doctors_remark: @ehr_investigation_record.doctors_remark, investigation_val: @ehr_investigation_record.investigation_val)
        end
      end
    end
  end

  def print_settings
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ["309935007", "261904005", "309964003"])
  end
end
