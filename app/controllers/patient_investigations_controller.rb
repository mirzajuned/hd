require 'date'
require 'time'
class PatientInvestigationsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def index
    respond_to do |format|
      format.html { render "index", layout: 'backbone_investigation' }
    end
  end

  def patient_tests
    all_test = []
    if params[:record_id].present?
      record_id = BSON::ObjectId(params[:record_id])
      @assessment = PatientOphthalAssessment.where(patient_id: params[:patient_id], record_id: record_id).order('created_at DESC')

    else
      @assessment = PatientOphthalAssessment.where(patient_id: params[:patient_id]).order('created_at DESC')
    end
    @assessment.each do |assessment|
      assessment.ophthal_investigations.each do |investigation|
        all_test.push(investigation)
      end
    end
    render json: all_test.as_json
  end

  def all_investigation_list
    facility_id = current_facility.id
    @patient_ophthal_investigations = PatientOphthalAssessment.not_in(status: "Complete").where(facility_id: facility_id).order('created_at DESC')
    # @patient_ophthal_investigations.each do |p|
    #   PatientRadiologyAssessment.where(record_id: p.record_id).each {|r| r.update_attributes(payment: p.payment, status: p.status)}
    # end
    # respond_to do |format|
    #   format.json { render json: @patient_ophthal_investigations}
    # end
  end

  def all_completed_reports
    facility_id = current_facility.id

    @patient_ophthal_investigations = PatientOphthalAssessment.where(status: "Complete", facility_id: facility_id).order('created_at DESC')

    # respond_to do |format|
    #   format.json { render json: @patient_ophthal_investigations}
    # end
  end

  def all_investigation_report
    facility_id = current_facility.id
    @patient_ophthal_reports = PatientOphthalAssessmentReport.where(facility_id: facility_id).order('created_at DESC')
  end

  def opthal_invoice
    facility_id = current_facility.id
    @invoice = Invoice::Opd::Opthal.where(facility_id: current_facility.id.to_s).order('created_at DESC')
    # respond_to do |format|
    #   format.json { render json: @invoice}
    # end
  end

  def upload_investigation_file
    report_id_array = []
    @assessment = PatientOphthalAssessment.find_by(:id => params[:assessmentid])
    all_report = PatientOphthalAssessmentReport.where(assessment_id: params[:assessmentid]).pluck('id')
    @report_link = PatientSummaryAssetUpload.create(name: params[:investigationName], asset_path: params[:files], facility_id: params[:facilityId], patient_id: params[:patientId], user_id: params[:userId], parent_folder_id: '560cc6f72b2e26135d000008', is_folder: 'N', opdrecord_id: @assessment.record_id)
    @report = PatientOphthalAssessmentReport.create(asset_path: params[:files], investigation_name: params[:investigationName], investigation_id: params[:investigationId], patient_id: params[:patientId], investigation_side: params[:investigationSide], assessment_id: params[:assessmentid], facility_id: params[:facilityId], record_id: @assessment.record_id, upload_id: @report_link.id)

    @assessment.update_attributes(report_id: all_report)
    # @investigations = @assessment.ophthal_investigations

    # @investigations.each do |investigation|
    #   if investigation[:investigationname].to_s == params[:investigationName].to_s
    #     if !investigation[:report_id].present?
    #       @assessment.report_id.each do |report|
    #         @report_id.push(report)
    #       end
    #     end
    #     @report_id.push(@report_link.id.to_s)
    #     investigation[:report_id] = @report_id
    #     investigation[:asset_path] = @report_link.asset_path.url
    #     end
    #   end
    #     @assessment.update_attributes(:ophthal_investigations => @investigations)
    #     @test_name = params[:investigationName]
    #     @klass_name = params[:investigationId]

    # respond_to do |format|
    #   # format.js
    #   format.json {
    #       render :json => { :files => [@picture.to_jq_upload] }
    #     }
    # end
  end

  def unavailable_investigation
    @assessment = PatientOphthalAssessment.find(params[:assessment_id])
    unavailable_test_id = []
    if @assessment.try(:unavailable_test_id)
      unavailable_test_id = @assessment.unavailable_test_id
    end
    unavailable_test_id.push(params[:investigation_id])
    @assessment.update_attributes(unavailable_test_id: unavailable_test_id.uniq)
    render json: nil, status: :ok
    # respond_to do |format|
    #   format.js { render js: {} }
    # end
  end

  def investigation_invoice # technician side
    # fail
    @invoice = Invoice::Opd::Opthal.new(total: params[:total], tax: params[:tax], advance_payment: params[:advance_amount], patient_id: params[:patient_id])
    @organisation = current_user.organisation
    @patient_details = Patient.find_by(id: params[:patient_id])
    @patient_ophthal_investigation = PatientOphthalAssessment.find(params[:assessment_id])

    params[:services].each do |a, v|
      # @patient_ophthal_investigation.save()
      service_item = @invoice.services.new(label: v[:name], unit_price: v[:cost])
      service_item.save(validate: false)
    end
    @invoice.opdrecord_id = @patient_ophthal_investigation.record_id
    @invoice.facility_id = current_facility.id
    @invoice.bill_number = CommonHelper::gen_investigation_identifier(current_user)
    @invoice.user_id = current_user.id
    @invoice.appointment_id = @patient_ophthal_investigation.appointment_id
    @invoice.save(validate: false)
    inv_workflow = InvestigationWorkflow.find_by(appointment_id: @patient_ophthal_investigation.appointment_id)
    inv_workflow.advised_to_payment
    inv_workflow.payment_done_to_technician
    @patient_ophthal_investigation.update_attributes(payment: "Paid to Technician")
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

  def delete_report
    if params[:report_id]
      @patientfiles = PatientOphthalAssessmentReport.find(params[:report_id])
      @patientuploads = PatientSummaryAssetUpload.find(params[:upload_id])
    elsif params[:id]
      @patientfiles = PatientOphthalAssessmentReport.find_by(upload_id: params[:id])
      @patientuploads = PatientSummaryAssetUpload.find_by(asset_path: params[:asset_path].split('/')[-1])
    end

    @patientuploads.try(:delete)
    @patientfiles.try(:delete)
    head :no_content
  end

  def complete_investigation
    @patient = PatientOphthalAssessment.find(params[:ophthal_inv_id])
    @patient_radio = PatientRadiologyAssessment.find_by(record_id: @patient.record_id)

    @patient.update_attributes(status: 'Complete')

    inv_workflow = InvestigationWorkflow.find_by(appointment_id: @patient.appointment_id)
    inv_workflow.upload_complete

    head :no_content
  end

  def ophthal_investigation_list
    @payment = params[:payment]
    @patient_investigation_id = params[:id]
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @patient_investigations = PatientOphthalAssessment.find_by(:id => params[:id])
    @services = Service.where(:service_type_id => 9999999999)
    @ophthal_investigation_invoice = Invoice::Opd::Opthal.find_by(:opdrecord_id => params[:opdrecordid])
    @flag = false

    respond_to do |format|
      format.js { render "ophthal_investigation_list", layout: false }
    end
  end

  def ophthal_investigation_summary
    @image = PatientSummaryAssetUpload.where(parent_folder_id: '560cc6f72b2e26135d000008', opdrecord_id: params[:opdrecordid], is_deleted: false).group_by { |x| x.name }
    @advised = PatientOphthalAssessment.find_by(record_id: BSON::ObjectId(params[:opdrecordid].to_s))
    respond_to do |format|
      format.js { render "ophthal_investigation_summary", layout: false }
    end
  end

  def save_ophthal_investigation
    # fail
    existing_invoice = Invoice::Opd::Opthal.where(opdrecord_id: params[:patient_investigation][:opdrecord_id])[0]
    @invoice_params = params[:patient_investigation]
    @patient_investigation_id = params[:patient_investigation_id]
    @patient_investigation = PatientOphthalAssessment.find_by(id: @patient_investigation_id)
    unless existing_invoice
      @params_investigation = params.require(:patient_investigation).permit!

      @patient_investigation.update_attributes(payment: 'Paid')
      # @patient_investigation.payment = params[:patient_opthal_assessment][:payment]
      # @patient_investigation.upsert
      @invest = Array.new
      params[:patient_investigation][:services_attributes].each do |index, service|
        @patient_investigation.ophthal_investigations.each_with_index do |investigation, index|
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
      @invoice = Invoice::Opd::Opthal.create(@invoice_params)
      @patient_investigation.update_attributes(:invoice_id => @invoice.id, :ophthal_investigations => @invest)
      @patient_ophthal_investigations = @patient_investigation

    else
      @patient_ophthal_investigations = @patient_investigation
      existing_invoice.update(invoice_update_params)
      existing_invoice.save(:validate => false)
      # params[:services_attributes].each do |index, service|
      #   existing_invoice.all[index]
      # end
      @invoice = existing_invoice
      # respond_to do |format|
      # format.js { render :partial => "investigation_state_change" }
      # end
    end
    @appointment_id = @patient_investigation.appointment_id
    respond_to do |format|
      format.js { render 'investigation_modal_preivew', :layout => false }
    end
  end

  def print
    if params[:log_id]
      opdrecord_id = Invoice::Opd::Opthal.find(params[:log_id]).opdrecord_id.to_s
      @patient_ophthal_investigation = PatientOphthalAssessment.find_by(:record_id => BSON::ObjectId(opdrecord_id))
    else
      @patient_ophthal_investigation = PatientOphthalAssessment.find_by(:id => params[:investigation_id])
    end
    @invoice = Invoice.find_by(:opdrecord_id => @patient_ophthal_investigation.record_id.to_s)
    if @invoice.mode_of_payment == "cash,card"
      @mop = "Cash & Card"
    elsif @invoice.mode_of_payment == nil
      @mop = 'Cash'
    else
      @mop = @invoice.mode_of_payment.capitalize
    end
    @organisation = current_user.organisation

    @patient_details = Patient.find(@patient_ophthal_investigation.patient_id)
    if params[:pagesize] == "A4"
      respond_to do |format|
        format.pdf { render :template => "patient_investigations/printinvoice.pdf.erb", :pdf => "xyz", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @organisation.letter_head_customisations[:left_margin].to_i * 10, right: @organisation.letter_head_customisations[:right_margin].to_i * 10, :top => @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom => @organisation.letter_head_customisations[:footer_height].to_i * 10 } }
      end
    elsif params[:pagesize] == "A5"
      respond_to do |format|
        format.pdf { render :template => "patient_investigations/printinvoice_a5.pdf.erb", :pdf => "xyz", :layout => 'pdfgen_invoice.html.erb', viewport_size: '1280x1024', :page_size => "A5", :orientation => "Landscape", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :footer => { :right => '[page] of [topage]' } }
      end
    end
  end

  def ophthal_investigation_preview
    @patient_ophthal_investigations = PatientOphthalAssessment.find_by(:id => params[:investigation_id].to_s)
    @invoice = Invoice::Opd::Opthal.find_by(:id => @patient_ophthal_investigations.invoice_id)
    respond_to do |format|
      format.js { render 'investigation_modal_preivew', :layout => false }
    end
  end

  def report_from_lab
    @patient_investigation = PatientOphthalAssessment.find_by(:id => params[:id])
    respond_to do |format|
      format.js { render 'report_from_lab', :layout => false }
    end
  end

  def save_ophthal_investigation_image
    @save_ophthal_investigation_image = PatientInvestigationAsset.new(:investigation_image_path => params[:investigation_image_path],
                                                                      :investigation_id => params[:investigation_id],
                                                                      :patient_investigation_id => params[:patient_investigation_id],
                                                                      :eye_side => params[:eye_side],
                                                                      :investigationside => params[:investigationside],
                                                                      :investigation_type => params[:investigation_type])

    @save_ophthal_investigation_image.save!

    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def radio_investigation_list
    @patient_investigation_id = params[:id]
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @patient_investigations = PatientInvestigation.find_by(:id => params[:id])
    respond_to do |format|
      format.js { render "radio_investigation_list", layout: false }
    end
  end

  def save_radio_investigation
    @patient_investigation_id = params[:patient_investigation_id]
    @patient_investigation = PatientInvestigation.find_by(id: @patient_investigation_id)
    @data_entry = params[:radiology_investigations]
    @radio_patient_investigation = @patient_investigation.radiology_investigations
    @radio_patient_investigation.each_with_index do |opi, i|
      opi[:findings] = @data_entry[i.to_s]
    end
    @patient_investigation.upsert
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def lab_investigation_list
    @patient_investigation_id = params[:id]
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @patient_investigations = PatientInvestigation.find_by(:id => params[:id])
    respond_to do |format|
      format.js { render "lab_investigation_list", layout: false }
    end
  end

  def lab_investigation_view
    @patient_investigation_id = params[:id]
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @patient_investigations = PatientInvestigation.find_by(:id => @patient_investigation_id)
    respond_to do |format|
      format.js { render "lab_investigation_view", layout: false }
    end
  end

  def save_lab_investigation
    @patient_investigation_id = params[:patient_investigation_id]
    @patient_investigation = PatientInvestigation.find_by(id: @patient_investigation_id)
    @data_entry = params[:laboratory_investigations]
    @lab_patient_investigation = @patient_investigation.laboratory_investigations
    @lab_patient_investigation.each_with_index do |opi, i|
      opi[:findings] = @data_entry[i.to_s]
    end
    @patient_investigation.upsert
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  private

  def invoice_update_params
    params.require(:patient_investigation).permit(:total, :tax, :discount, :mode_of_payment, :cash, :card)
  end
end
