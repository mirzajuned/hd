class MailRecordTrackersController < ApplicationController
  before_action :authorize
  before_action :set_initial_params


  def new
    @mode = params[:mode] || params[:viewmode]
    @record_mail_sets = RecordMailerSet.where(user_id: current_user.id)

    if ['OpdRecord', 'Invoice::Opd', 'Invoice::Ipd', 'RefundPayment', 'PatientOpticalPrescription', 'PatientPrescription', 'AdvancePayment', 'Invoice::InventoryInvoice', 'Invoice::InventoryOrder'].include?(params[:record_model])
      @patient = Patient.find_by(id: params[:patient_id])
      @appointment_id = params[:appointment_id]
      @admission_id = params[:admission_id]

    elsif params[:record_model] == 'Inpatient::IpdRecord'
      @ipd_record = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
      unless @ipd_record.present?
        admission = Admission.find_by(id: params[:admission_id])
        @patient = admission.patient
      else
        @patient = @ipd_record.try(:patient)
      end
      @admission_id = params[:admission_id]
    end
    content_type
    @email_tracker = MailRecordTracker.new
  end

  def create
    @params = params[:mail_record_tracker]
    first_email = @params[:email].split(',')[0] rescue ''
    @language_flag = @params[:language_flag]
    @advice_language = @params[:advice_language]
    @patient = Patient.find_by(id: @params[:patient_id])
    params[:mail_record_tracker][:selectedtagnames] = @params[:selectedtagnames].split(',').uniq.join(',')
    record_details = { record_name: @params[:record_name], record_id: @params[:record_id].to_s, record_model: @params[:record_model] }
    sender_details = { sender_name: @current_user.fullname, sender_id: @current_user.id.to_s, sender_role: @current_user.primary_role }
    receiver_details = { 
      patient_email: @params[:email],
      patient_name: @patient.fullname,
      patient_id: @patient.id.to_s,
      appointment_id: @params[:appointment_id].to_s,
      admission_id: @params[:admission_id].to_s,
      cc_email: @params[:selectedtagnames].to_s
    }
    facility_details = { facility_name: @current_facility.name, facility_id: @current_facility.id.to_s, speciality: @params[:speciality], speciality_id: @params[:speciality_id] }

    params[:mail_record_tracker][:record_details] = record_details
    params[:mail_record_tracker][:sender_details] = sender_details
    params[:mail_record_tracker][:receiver_details] = receiver_details
    params[:mail_record_tracker][:facility_details] = facility_details

    params[:mail_record_tracker][:record_details][:filename] = content_type_for_filename(record_details)
    
    @patient.update(email: first_email) if first_email.present?
    set_mail_message
    @email_tracker = MailRecordTracker.new(mail_record_params)
    @email_tracker.save!
  end

  def edit
    @email_tracker = MailRecordTracker.find_by(id: params[:id])
    @tag_names = @email_tracker.selectedtagnames.split(',')
    @tag_fields = @tag_names.map { |tag| Array[tag, tag] }
    @patient = Patient.find_by(id: params[:patient_id])
    @record_mail_sets = RecordMailerSet.where(user_id: current_user.id)
  end

  def update
    @email_tracker =  MailRecordTracker.find_by(id: params[:id])
    @patient = Patient.find_by(id: @email_tracker[:receiver_details][:patient_id])
    tag_names = params[:mail_record_tracker][:selectedtagnames]
    params[:mail_record_tracker][:selectedtagnames] = tag_names.split(',').uniq.join(',')
    params[:mail_record_tracker][:receiver_details] = {}
    params[:mail_record_tracker][:receiver_details] = {
        patient_email: params[:mail_record_tracker][:email],
        patient_name: @patient.fullname,
        patient_id: @patient.id.to_s,
        appointment_id: @email_tracker.receiver_details['appointment_id'],
        admission_id: @email_tracker.receiver_details['admission_id'],
        cc_email: params[:mail_record_tracker][:selectedtagnames].to_s
      }

    set_mail_message
    @email_tracker.update(mail_record_update_params)
    email_param = params[:mail_record_tracker][:email]
    first_email = email_param.split(',')[0] rescue ''
    # @patient.update(email: params[:mail_record_tracker][:email])
    @patient.update(email: first_email) if first_email.present?
  end

  def new_mail_set_popup
    respond_to do |format|
      format.html { render 'new_mail_set_popup', layout: false }
    end
  end

  def save_mail_set
    RecordMailerSet.create!(user_id: @current_user.id, facility_id: @current_facility.id, organisation_id: @current_organisation.id, name: params[:name], content: params[:content])
    @mail_sets = RecordMailerSet.where(user_id: @current_user.id)
  end

  def send_mail
    begin
      params['translated_language'] = @translated_language
      params[:facility_id] = current_facility.id
      RecordsMailer.send_mail(params).deliver_now
    rescue ArgumentError
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'We can't deliver your mail due to some problem', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    end

    respond_to do |format|
      format.js {}
    end
  end

  private

  def mail_record_params
    params.require(:mail_record_tracker).permit(:subject, :cc_mail, :cc_mail_selected_tag_ids, :selectedtagnames, :mail_text, :disclaimer, :organisation_id, record_details: [:record_name, :record_id, :record_model, :filename], sender_details: [:sender_id, :sender_name, :sender_role], receiver_details: [:patient_id, :patient_name, :appointment_id, :patient_email, :admission_id, :cc_email], facility_details: [:facility_id, :facility_name, :speciality, :speciality_id])
  end

  def mail_record_update_params
    params.require(:mail_record_tracker).permit(:mail_text, :subject, :disclaimer, :selectedtagnames, receiver_details: [:patient_id, :patient_name, :appointment_id, :patient_email, :admission_id, :cc_email])
  end

  def set_mail_message
    map = { '%pat_name%' => @patient.try(:fullname).try(:capitalize), '%fac_no%' => @current_facility.try(:telephone), '%fac_name%' => @current_facility.try(:name), '%org_name%' => @current_organisation.try(:name).try(:capitalize) }
    re = Regexp.union(map.keys)
    params[:mail_record_tracker][:mail_text] = params[:mail_record_tracker][:mail_text].gsub(re, map)
  end

  def set_initial_params
    @current_user = current_user
    @current_facility = current_facility
    @current_organisation = @current_user.organisation
  end

  def content_type
    @content_type = if params[:templatetype].present?
                      record = params[:record_model].split /(?=[A-Z])/
                      "Your #{(record[0] == 'Ipd' || record[0] == 'Opd') ? record[0].upcase : record[0] } Health #{record[1]}"
                    else
                      if params[:record_model] == 'Invoice::InventoryOrder'
                        "Your #{get_name_for_inventory_order(params[:record_id], params[:record_name])} "
                      elsif params[:record_name] == 'Inventory Invoice'
                        "Your #{inventory_bill_name(params[:record_id])}"       
                      elsif params[:record_model] == 'AdvancePayment'
                        type = AdvancePayment.find_by(id: params[:record_id]).type
                        "Your #{type} Advance Receipt"
                      elsif params[:record_model] == 'RefundPayment'
                        type = RefundPayment.find_by(id: params[:record_id]).type
                        "Your #{type} Refund Receipt"
                      elsif params[:record_model] == 'Invoice::Ipd' || params[:record_model] == 'Invoice::Opd'
                        "Your " + name_for_ipd_opd_invoices(params[:record_name], params[:record_id])
                      elsif params[:record_name] == 'Medication Prescription' && params[:record_model] == 'Inpatient::IpdRecord'
                        'Post OP Medication'
                      elsif params['record_name'].present?
                        # "Your #{params['record_name'].slice(0..(params['record_name'].index('-')))}"
                        "Your #{record_name_alias(params['record_name'])}"
                      else
                        ""
                      end
                    end
              
  end

  def content_type_for_filename(record_details) 
    if record_details[:record_model].include?('Invoice::InventoryOrder')
      get_name_for_inventory_order(record_details[:record_id], record_details[:record_name])
    elsif record_details[:record_name] == 'Inventory Invoice'
      inventory_bill_name(record_details[:record_id])       
    elsif record_details[:record_model] == 'AdvancePayment'
      type = AdvancePayment.find_by(id: record_details[:record_id]).type
      "#{type} Advance Receipt"
    elsif record_details[:record_model] == 'RefundPayment'
      type = RefundPayment.find_by(id: record_details[:record_id]).type
      "#{type} Refund Receipt"
    elsif record_details[:record_model] == 'Invoice::Ipd' || record_details[:record_model] == 'Invoice::Opd'
      name_for_ipd_opd_invoices(record_details[:record_name], record_details[:record_id])
    elsif record_details[:record_name].include?('Medication')
      if record_details[:record_model].include?('Inpatient::IpdRecord')
        return 'Post OP Medication'
      end
      "Medication Prescription"
    elsif record_details[:record_model] == 'OpdRecord'
      if record_details[:record_name] == "Intermediate Glass Prescription" 
        return "Intermediate Glass Prescription"  
      elsif record_details[:record_name].include?('Squint') 
        return 'Squint Examination'
      elsif record_details[:record_name].include?('Glass')
        return "Glass Prescription"
      end
      "#{record_details[:record_model][0..2].upcase} Health Record"
    elsif record_details[:record_name].present?
      " #{record_name_alias(record_details[:record_name])}"
    else
      ""
    end
  end

  def inventory_bill_name(record_id)
    inventory_data_item = Invoice::InventoryInvoice.find_by(id: record_id)
    if inventory_data_item.invoice_type == 'cash'
      inventory_data_item.department_name == 'Optical' ? "#{inventory_data_item.department_name.capitalize} Invoice" : "#{inventory_data_item.department_name} Cash Bill Invoice"
    else
      "#{inventory_data_item.department_name.capitalize} #{inventory_data_item.invoice_type.capitalize} Bill Invoice"
    end
  end

  def get_name_for_inventory_order(record_id,record_name)
    invoice = Invoice::InventoryOrder.find_by(id: record_id)
    "#{invoice.department_name.capitalize} Order"
  end 

  def record_name_alias(record_name)
    if record_name == 'careplan'
      'Nursing Care Plan Documentation'
    elsif record_name == 'Pre Anaesthesia'
      'Pre Anaesthesia Summary'
    elsif record_name == 'Ot Checklist'
      'OT Checklist'
    elsif record_name == 'Discharge Note'
      'IPD Discharge Note'
    elsif record_name == 'pain'
      'Pain Assessment'
    elsif record_name == 'aldrete'
      'Modified Aldrete Score For Discharge'
    elsif record_name == 'sedation'
      'Sedation / Analgesia Monitoring Chart'
    else
      record_name.titleize
    end
  end
  # EOF record_name_alias

  def name_for_ipd_opd_invoices(record_name, inv_id)
    invoice = Invoice.find_by(id: inv_id)
    if invoice.invoice_type == 'cash' 
      "#{record_name.split(" ")[0].upcase} Cash Bill"
    elsif invoice.invoice_type == 'credit'
      invoice.is_draft ? "#{record_name.split(" ")[0].upcase} Draft Bill" : "#{record_name.split(" ")[0].upcase} Credit Bill"
    else
      # should not execute, but wrote just to be safe in case someone adds new invoice type 
      "#{record_name.upcase}"
    end
  end


end
