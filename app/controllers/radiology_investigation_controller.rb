require 'date'
require 'time'
class RadiologyInvestigationController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def all_radiology_investigations
    facility_id = current_facility.id
    @patient_radio_investigations = PatientRadiologyAssessment.not_in(status: "Complete").where(facility_id: facility_id).order('created_at DESC')
    # @patient_radio_investigations.each do |p|
    #   PatientOphthalAssessment.where(record_id: p.record_id).each {|r| r.update_attributes(payment: p.payment, status: p.status)}
    # end
  end

  def all_radiology_reports
    facility_id = current_facility.id
    @patient_radio_reports = PatientRadioAssessmentReport.where(facility_id: facility_id).order('created_at DESC')
  end

  # def radio_invoice
  #   facility_id = current_facility.id
  #   @invoice = Invoice::Opd::Radiology.where(facility_id: current_facility.id.to_s).order('created_at DESC')
  # end

  def patient_tests
    all_test = []
    if params[:record_id].present?
      record_id = BSON::ObjectId(params[:record_id])
      @assessment = PatientRadiologyAssessment.where(patient_id: params[:patient_id], record_id: record_id).order('created_at DESC')

    else
      @assessment = PatientRadiologyAssessment.where(patient_id: params[:patient_id]).order('created_at DESC')
    end
    @assessment.each do |assessment|
      assessment.radiology_investigations.each do |investigation|
        all_test.push(investigation)
      end
    end
    render json: all_test.as_json
  end

  def upload_investigation_file
    report_id_array = []
    @assessment = PatientRadiologyAssessment.find_by(:id => params[:assessmentid])
    all_report = PatientRadioAssessmentReport.where(assessment_id: params[:assessmentid]).pluck('id')
    @report_link = PatientSummaryAssetUpload.create(name: params[:investigationName], asset_path: params[:files], facility_id: params[:facilityId], patient_id: params[:patientId], user_id: params[:userId], parent_folder_id: '560cc6f72b2e26135d000001', is_folder: 'N', opdrecord_id: @assessment.record_id)
    @report = PatientRadioAssessmentReport.create(asset_path: params[:files], investigation_name: params[:investigationName], investigation_id: params[:investigationId], patient_id: params[:patientId], investigation_side: params[:investigationSide], assessment_id: params[:assessmentid], facility_id: params[:facilityId], record_id: @assessment.record_id, upload_id: @report_link.id)

    @assessment.update_attributes(report_id: all_report)
  end

  def radio_invoice_list
    @payment = params[:payment]
    @patient_investigation_id = params[:id]
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @patient_investigations = PatientRadiologyAssessment.find_by(:id => params[:id])
    @services = Service.where(:service_type_id => 9999999999)
    @radio_investigation_invoice = Invoice::Opd::Radiology.find_by(:opdrecord_id => params[:opdrecordid])
    @flag = false
    respond_to do |format|
      format.js { render "radio_investigation_list", layout: false }
    end
  end

  def save_radio_investigation
    # fail
    existing_invoice = Invoice::Opd::Radiology.where(opdrecord_id: params[:patient_investigation][:opdrecord_id])[0]
    @invoice_params = params[:patient_investigation]
    @patient_investigation_id = params[:patient_investigation_id]
    @patient_investigation = PatientRadiologyAssessment.find_by(id: @patient_investigation_id)
    unless existing_invoice
      @params_investigation = params.require(:patient_investigation).permit!

      @patient_investigation.update_attributes(payment: 'Paid')
      # @patient_investigation.payment = params[:patient_opthal_assessment][:payment]
      # @patient_investigation.upsert
      @invest = Array.new
      params[:patient_investigation][:services_attributes].each do |index, service|
        @patient_investigation.radiology_investigations.each_with_index do |investigation, index|
          if investigation[:investigationname].to_s == service[:label].to_s
            @invest[index] = Hash.new()
            @invest[index] = investigation
            @invest[index][:payment] = service[:payment]
          end
        end
        @service = Service.find_by(:organisation_id => current_user.organisation.id, :service_type_id => 9999999999, :name => service[:label])
        if @service == nil
          Service.create(:name => service[:label], :organisation_id => current_user.organisation.id, :service_type_id => "9999999999", :service_type => "Assessment", :default_units => "1", :unit_cost => service[:unit_price])
        end
      end

      @invoice_params[:patient_id] = @patient_investigation.patient_id
      @invoice_params[:appointment_id] = @patient_investigation.appointment_id
      @invoice_params[:facility_id] = current_facility.id
      @invoice_params[:user_id] = current_user.id
      @invoice_params[:bill_number] = CommonHelper::gen_investigation_identifier(current_user)
      @invoice_params[:services_attributes].each do |index, params_i|
        if params_i[:payment].to_s == "Outhouse"
          @invoice_params[:services_attributes].delete(index.to_sym)
        end
      end
      @invoice = Invoice::Opd::Radiology.create(@invoice_params)
      @patient_investigation.update_attributes(:invoice_id => @invoice.id, :ophthal_investigations => @invest)
      @patient_radio_investigations = @patient_investigation

    else
      @patient_radio_investigations = @patient_investigation
      existing_invoice.update(invoice_update_params)
      existing_invoice.save(:validate => false)
      @invoice = existing_invoice
      # respond_to do |format|
      # format.js { render :partial => "investigation_state_change" }
      # end
    end
    @appointment_id = @patient_investigation.appointment_id
    respond_to do |format|
      format.js {}
    end
  end

  def unavailable_investigation
    @assessment = PatientRadiologyAssessment.find(params[:assessment_id])
    unavailable_test_id = []
    if @assessment.try(:unavailable_test_id)
      unavailable_test_id = @assessment.unavailable_test_id
    end
    unavailable_test_id.push(params[:investigation_id])
    @assessment.update_attributes(unavailable_test_id: unavailable_test_id.uniq)
    render json: nil, status: :ok
  end

  # def radiology_invoice

  # end

  def delete_report
    if params[:report_id]
      @patientfiles = PatientRadioAssessmentReport.find(params[:report_id])
      @patientuploads = PatientSummaryAssetUpload.find(params[:upload_id])
    elsif params[:id]
      @patientfiles = PatientRadioAssessmentReport.find_by(upload_id: params[:id])
      @patientuploads = PatientSummaryAssetUpload.find_by(asset_path: params[:asset_path].split('/')[-1])
    end

    @patientuploads.try(:delete)
    @patientfiles.try(:delete)
    head :no_content
  end

  def investigation_invoice # technician side
    # fail
    @invoice = Invoice::Opd::Radiology.new(total: params[:total], tax: params[:tax], advance_payment: params[:advance_amount], patient_id: params[:patient_id])
    @organisation = current_user.organisation
    @patient_details = Patient.find_by(id: params[:patient_id])
    @patient_radio_investigation = PatientRadiologyAssessment.find(params[:assessment_id])

    params[:services].each do |a, v|
      # @patient_ophthal_investigation.save()
      service_item = @invoice.services.new(label: v[:name], unit_price: v[:cost])
      service_item.save(validate: false)
    end
    @invoice.opdrecord_id = @patient_radio_investigation.record_id
    @invoice.facility_id = current_facility.id
    @invoice.bill_number = CommonHelper::gen_investigation_identifier(current_user)
    @invoice.user_id = current_user.id
    @invoice.appointment_id = @patient_radio_investigation.appointment_id
    @invoice.save(validate: false)
    inv_workflow = InvestigationWorkflow.find_by(appointment_id: @patient_radio_investigation.appointment_id)
    inv_workflow.advised_to_payment
    inv_workflow.payment_done_to_technician

    @patient_radio_investigation.update_attributes(payment: "Paid to Technician")
    # @opthal_assessment = @patient_ophthal_investigation.ophthal_investigations
    # @assessment = @patient_ophthal_investigation

    # @investigations = @assessment.ophthal_investigations
    # arr = []
    # params[:services].each do |a,v|
    #   @investigations.each do |investigation|
    #     if v['name'] == investigation['investigationname']
    #       temp = Hash.new
    #       temp = investigation
    #       temp.merge!(:payment => "Inhouse", :cost => v['cost'])
    #       investigation = temp
    #       arr.push(investigation)
    #     end
    #   end

    # end
    # @assessment.update_attributes(:ophthal_investigations => arr )

    if params[:pagesize] == "A4"
      respond_to do |format|
        format.json { render :json => {} }
        format.pdf { render :template => "patient_investigations/printinvoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @organisation.letter_head_customisations[:left_margin].to_i * 10, right: @organisation.letter_head_customisations[:right_margin].to_i * 10, :top => @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom =>  @organisation.letter_head_customisations[:footer_height].to_i * 10 } }
      end
    elsif params[:pagesize] == "A5"
      format.json { render :json => {} }
      respond_to do |format|
        format.pdf { render :template => "patient_investigations/printinvoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A5", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @organisation.letter_head_customisations[:left_margin].to_i * 10, right: @organisation.letter_head_customisations[:right_margin].to_i * 10, :top => @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom =>  @organisation.letter_head_customisations[:footer_height].to_i * 10 } }
      end
    end
  end

  def print
    if params[:log_id]
      opdrecord_id = Invoice::Opd::Radiology.find(params[:log_id]).opdrecord_id.to_s
      @patient_radio_investigation = PatientRadiologyAssessment.find_by(:record_id => BSON::ObjectId(opdrecord_id))
    else
      @patient_radio_investigation = PatientRadiologyAssessment.find_by(:id => params[:investigation_id])
    end
    @invoice = Invoice.find_by(:opdrecord_id => @patient_radio_investigation.record_id.to_s)
    if @invoice.mode_of_payment == "cash,card"
      @mop = "Cash & Card"
    elsif @invoice.mode_of_payment == nil
      @mop = 'Cash'
    else
      @mop = @invoice.mode_of_payment.capitalize
    end
    @organisation = current_user.organisation

    @patient_details = Patient.find(@patient_radio_investigation.patient_id)
    if params[:pagesize] == "A4"
      respond_to do |format|
        format.pdf { render :template => "radiology_investigation/printinvoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @organisation.letter_head_customisations[:left_margin].to_i * 10, right: @organisation.letter_head_customisations[:right_margin].to_i * 10, :top => @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom => @organisation.letter_head_customisations[:footer_height].to_i * 10 } }
      end
    elsif params[:pagesize] == "A5"
      respond_to do |format|
        format.pdf { render :template => "radiology_investigation/printinvoice_a5.pdf.erb", :pdf => "xyz", :layout => 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', :page_size => "A5", :orientation => "Landscape", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :footer => { :right => '[page] of [topage]' } }
      end
    end
  end

  def complete_investigation
    @patient = PatientRadiologyAssessment.find(params[:radio_inv_id])
    @patient.update_attributes(status: 'Complete')

    inv_workflow = InvestigationWorkflow.find_by(appointment_id: @patient.appointment_id)
    inv_workflow.upload_complete
    head :no_content
  end

  def radio_investigation_summary
    @image = PatientSummaryAssetUpload.where(opdrecord_id: params[:opdrecordid], parent_folder_id: '560cc6f72b2e26135d000001', is_deleted: false).group_by { |x| x.name }
    @advised = PatientRadiologyAssessment.find_by(record_id: BSON::ObjectId(params[:opdrecordid].to_s))
    respond_to do |format|
      format.js { render "radio_investigation_summary", layout: false }
    end
  end

  private

  def invoice_update_params
    params.require(:patient_investigation).permit(:total, :tax, :discount, :mode_of_payment, :cash, :card)
  end
end
