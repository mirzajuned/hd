# 5   Metrics/MethodLength
# 3   Metrics/AbcSize
# 1   Metrics/ClassLength
# 1   Metrics/CyclomaticComplexity
# 1   Metrics/PerceivedComplexity
# --
# 11  Total
class EmailJobs::GenerateReportPdf < ActiveJob::Base
  queue_as :urgent

  def perform(params)
    @report = MailRecordTracker.find_by(id: params[:id])
    @patient = Patient.find_by(id: @report.receiver_details['patient_id'])
    @appointment = Appointment.find_by(id: @report.receiver_details['appointment_id'])
    @current_user = User.find_by(id: @report.sender_details['sender_id'])
    @current_facility = Facility.find_by(id: params[:facility_id] ||  @report.facility_details['facility_id'])
    @facility_setting = FacilitySetting.find_by(facility_id: @current_facility.id)

    @translated_language = params['translated_language']

    if @report.record_details['record_model'] == 'OpdRecord'
      opd_record_params(params)

    elsif @report.record_details['record_model'] == 'PatientOpticalPrescription'
      patient_optical_prescription_params(params)

    elsif @report.record_details['record_model'] == 'PatientPrescription'
      patient_pharmacy_prescription_params(params)

    elsif @report.record_details['record_model'] == 'Inpatient::IpdRecord'
      ipd_record_params(params)

    elsif ['Invoice::Opd', 'Invoice::Ipd'].include? @report.record_details['record_model']
      opd_ipd_invoices_params(params)

    elsif @report.record_details['record_model'] == 'Invoice::InventoryInvoice'
      inventory_invoices_params(params)

    elsif @report.record_details['record_model'] == 'Invoice::InventoryOrder'
      inventory_orders_params(params)

    elsif @report.record_details['record_name'] == 'AdvancePayment'
      advance_payment_params(params)

    elsif @report.record_details['record_name'] == 'RefundPayment'
      refund_payment_params(params)

    elsif @report.record_details['record_name'] == 'PurchaseOrder'
      purchase_order_params(params)

    end

    wicked = WickedPdf.new

    # Make a PDF in memory
    pdf_file = wicked.pdf_from_string(
      ApplicationController.new.render_to_string(
        template: @template,
        layout: 'pdfgen.html.erb',
        locals: @locals
      ), viewport_size: '1280x1024', page_size: 'A4', margin: { top: 30, bottom: 20 }
    )

    # creating directory if doesnt exits
    Dir.mkdir('public/mail_pdfs/') unless File.exist?('public/mail_pdfs/')

    # Write it to disk
    save_path = Rails.root.join('public/mail_pdfs/', "patient_record_#{@report.id}.pdf")

    File.open(save_path, 'wb') do |file|
      file << pdf_file
    end
  end

  private

  def opd_record_params(params)
    @opd_record = OpdRecord.find_by(id: @report.record_details['record_id'])
    @case_sheet = CaseSheet.find_by(id: @opd_record.case_sheet_id)
    speciality_path = @report.facility_details['speciality']
    has_intermediate = @report.record_details['record_name'].include?('Intermediate')
    optical_file_name = ''
    advice_language = params[:advice_language]
    language_flag = params[:language_flag]
    # performed investigations
    performed_case_opd(@opd_record, @case_sheet)
    # EOF get opd performed investigations which are not yet stored in case-sheet

    if @report.record_details['record_name'] == 'Medication Prescription'
      @template = "opd_records/#{speciality_path}_notes/download/medication_opd_summary_mail"

    elsif @report.record_details['record_name'].include?('Glass Prescription')
      optical_file_name = has_intermediate ? 'glasses_intermediate_prescriptions' : 'glassesprescriptions'
      @template = "opd_records/#{speciality_path}_notes/download/glasses_opd_summary_mail"

    elsif @report.record_details['record_name'] == 'Squint Examination'
      @template = "opd_records/#{speciality_path}_notes/download/squint_opd_summary_mail"
    else
      @template = "opd_records/#{speciality_path}_notes/download/mail_opd_summary_download"
    end

    if @opd_record.treatmentmedication.present?
      @medication = 'true'
      @medication_groups = @opd_record.treatmentmedication.group_by(&:status)
    end

    @locals = { specalityfoldername: speciality_path, current_user: @current_user, current_facility: @current_facility,
                opdrecord: @opd_record, case_sheet: @case_sheet, patient: @patient, appointment: @appointment,
                templatetype: @opd_record.templatetype, optical_file_name: optical_file_name,
                advice_language: advice_language, language_flag: language_flag, medication_groups: @medication_groups,
                translated_language: @translated_language, performed_opd_ophthal: @performed_opd_ophthal,
                performed_opd_laboratory: @performed_opd_laboratory, performed_opd_radiology: @performed_opd_radiology }
  end

  def performed_case_opd(opd_record, _opd_case_sheet)
    # opthal investigations
    # @performed_ophthal = opd_case_sheet.ophthal_investigations.where(is_performed: true, record_id: opd_record.id.to_s)
    @performed_opd_ophthal = opd_record.ophthalinvestigationlist.where(is_performed: true)
    # EOF opthal investigations

    # laboratory investigations
    # @performed_laboratory = opd_case_sheet.laboratory_investigations.where(is_performed: true, record_id: opd_record.id.to_s)
    @performed_opd_laboratory = opd_record.addedlaboratoryinvestigationlist.where(is_performed: true)
    # EOF laboratory investigations

    # radiology investigations
    # @performed_radiology = opd_case_sheet.radiology_investigations.where(is_performed: true, record_id: opd_record.id.to_s)
    @performed_opd_radiology = opd_record.investigationlist.where(is_performed: true)
    # EOF radiology investigations
  end

  def patient_optical_prescription_params(_params)
    optical_prescription = PatientOpticalPrescription.find_by(id: @report.record_details['record_id'])
    opd_record = OpdRecord.find_by(id: optical_prescription.record_id)
    speciality_path = @report.facility_details['speciality']
    has_intermediate = @report.record_details['record_name'].include?('Intermediate')
    optical_file_name = has_intermediate ? 'glasses_intermediate_prescriptions' : 'glassesprescriptions'

    if opd_record.treatmentmedication.present?
      @medication = 'true'
      @medication_groups = opd_record.treatmentmedication.group_by(&:status)
    end

    @template = "opd_records/#{speciality_path}_notes/download/glasses_opd_summary_mail"
    @locals = { specalityfoldername: speciality_path, current_user: @current_user,
                current_facility: @current_facility, opdrecord: opd_record, patient: @patient,
                appointment: @appointment, optical_file_name: optical_file_name, medication_groups: @medication_groups, translated_language: @translated_language }
  end

  def patient_pharmacy_prescription_params(params)
    prescription = PatientPrescription.find_by(id: @report.record_details['record_id'])
    specialty_path = @report.facility_details['speciality']
    if @report.facility_details['speciality_id'].present? && !specialty_path.present?
      specialty_path = TemplatesHelper.get_speciality_folder_name(@report.facility_details['speciality_id'])
    end
    advice_language = params[:advice_language]
    language_flag = params[:language_flag]

    if prescription.encountertype == 'OPD'
      opd_record = OpdRecord.find_by(id: prescription.record_id)
      @template = "opd_records/#{specialty_path}_notes/download/medication_opd_summary_mail"

      if opd_record.treatmentmedication.present?
        @medication = 'true'
        @medication_groups = opd_record.treatmentmedication.group_by(&:status)
      end

      @locals = { specalityfoldername: specialty_path, current_user: @current_user, current_facility: @current_facility,
                  opdrecord: opd_record, patient: @patient, appointment: @appointment,
                  advice_language: advice_language, language_flag: language_flag, medication_groups: @medication_groups, translated_language: @translated_language }
    else
      ipd_record = Inpatient::IpdRecord.find_by(admission_id: @report.receiver_details['admission_id'])
      admission = ipd_record.try(:admission)
      case_sheet = CaseSheet.find_by(id: ipd_record.case_sheet_id)
      @template = 'inpatient/ipd_record/discharge_note/mail_record'

      @locals = { speciality: specialty_path, current_user: @current_user, patient: @patient, admission: admission,
                  ipd_record: ipd_record, tpa: admission, current_facility: @current_facility,
                  view: 'Medication', case_sheet: case_sheet, advice_language: advice_language,
                  language_flag: language_flag, translated_language: @translated_language }
    end
  end

  def ipd_record_params(params)
    @ipd_record = Inpatient::IpdRecord.find_by(admission_id: @report.receiver_details['admission_id'])
    @tpa = Inpatient::Insurance::Tpa.find_by(admission_id: @report.receiver_details['admission_id'])
    case_sheet = CaseSheet.find_by(id: @ipd_record.try(:case_sheet_id))
    specialty_path = TemplatesHelper.get_speciality_folder_name(@report.facility_details['speciality_id'])
    advice_language = params[:advice_language]
    language_flag = params[:language_flag]

    if @report.record_details['record_name'] == 'Medication Prescription'
      @template = 'inpatient/ipd_record/discharge_note/mail_record'
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), ipd_record: @ipd_record, tpa: @tpa,
                  current_facility: @current_facility, view: 'Medication', advice_language: advice_language,
                  language_flag: language_flag, translated_language: @translated_language }

    elsif @report.record_details['record_name']  == 'Clinical Note'
      @template = 'inpatient/ipd_record/clinical_note/mail_record'
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), ipd_record: @ipd_record, tpa: @tpa,
                  current_facility: @current_facility, translated_language: @translated_language }

    elsif @report.record_details['record_name']  == 'Operative Note'
      @template = 'inpatient/ipd_record/operative_note/mail_record'
      operative_note = (@ipd_record.try(:operative_notes).present?) ? @ipd_record.operative_notes.find_by(id: @report.record_details['record_id']) : nil
      @locals = { speciality: specialty_path, operative_note: operative_note, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), ipd_record: @ipd_record, tpa: @tpa,
                  current_facility: @current_facility, current_user: @current_user, advice_language: advice_language,
                  language_flag: language_flag, translated_language: @translated_language }

    elsif @report.record_details['record_name']  == 'Discharge Note'
      @template = 'inpatient/ipd_record/discharge_note/mail_record'
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet, ipd_record: @ipd_record,
                  tpa: @tpa, current_facility: @current_facility, current_user: @current_user, view: 'Note',
                  advice_language: advice_language, language_flag: language_flag, translated_language: @translated_language }

    elsif @report.record_details['record_name']  == 'Ot Checklist'
      @template = 'inpatients/ot_checklists/mail_record'
      @ot_checklist = OtChecklist.find_by(admission_id: @ipd_record.try(:admission).try(:id).to_s)
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), ot_checklist: @ot_checklist, ipd_record: @ipd_record, tpa: @tpa,
                  current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'Ward Checklist'
      @template = 'inpatient/ward_checklists/mail_record'
      @ward_checklist = Inpatient::WardChecklist.find_by(admission_id: @ipd_record.try(:admission).try(:id).to_s)
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), ward_checklist: @ward_checklist, ipd_record: @ipd_record, tpa: @tpa,
                  current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'Assessment'
      @template = 'inpatients/patient_assessments/mail_record'
      @assessment = PatientAssessment.find_by(admission_id: @ipd_record.try(:admission).try(:id).to_s)
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), assessment: @assessment, ipd_record: @ipd_record, tpa: @tpa,
                  current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'careplan'
      @template = 'inpatients/nursing_records/mail_record'
      @assessment = NursingRecord.find_by(id: @report.record_details['record_id'])
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), assessment: @assessment, templatetype: "careplan", ipd_record: @ipd_record, tpa: @tpa, view: 'Medication', current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'sedation'
      @template = 'inpatients/nursing_records/mail_record'
      @assessment = NursingRecord.find_by(id: @report.record_details['record_id'])
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), assessment: @assessment, templatetype: "sedation", ipd_record: @ipd_record, tpa: @tpa, current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'aldrete'
      @template = 'inpatients/nursing_records/mail_record'
      @assessment = NursingRecord.find_by(id: @report.record_details['record_id'])
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), assessment: @assessment, templatetype: "aldrete", ipd_record: @ipd_record, tpa: @tpa, current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'pain'
      @template = 'inpatients/nursing_records/mail_record'
      @assessment = NursingRecord.find_by(id: @report.record_details['record_id'])
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), assessment: @assessment, templatetype: "pain", ipd_record: @ipd_record, tpa: @tpa, current_facility: @current_facility, translated_language: @translated_language }
    elsif @report.record_details['record_name']  == 'Pre Anaesthesia'
      @template = 'inpatient/pre_anaesthesia_notes/mail_record'
      @pre_anaesthesia_note = Inpatient::PreAnaesthesiaNote.find_by(admission_id: @ipd_record.try(:admission).try(:id).to_s)
      @locals = { speciality: specialty_path, patient: @patient, case_sheet: case_sheet,
                  admission: @ipd_record.try(:admission), pre_anaesthesia_note: @pre_anaesthesia_note, ipd_record: @ipd_record, tpa: @tpa, current_facility: @current_facility, translated_language: @translated_language }
    end
  end

  def opd_ipd_invoices_params(params)
    @invoice = Invoice.find_by(id: @report.record_details['record_id'])

    if @report.record_details['record_name'] == 'Opd Invoice'
      @department = 'Opd'
      @model = 'Invoice::Opd'
      @appointment = Appointment.find_by(id: @report.receiver_details['appointment_id'])
      fetch_opd_assessment_data
    else
      @department = 'Ipd'
      @model = 'Invoice::Ipd'
      @admission = Admission.find_by(id: @report.receiver_details['admission_id'])
      fetch_ipd_assessment_data
    end

    @refund_payments = RefundPayment.where(invoice_id: @invoice.id)
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: @invoice.facility_id, is_active: true)
    @payer_fields = @payer_masters.map { |c| { id: c.id.to_s, display_name: c.display_name } }
    @invoice_setting = InvoiceSetting.find_by(organisation_id: @current_user.organisation_id)
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: @current_user.organisation_id)
    currency_symbol = (@invoice.currency_symbol || @current_facility.currency_symbol)
    @locals = { patient: @patient, appointment: @appointment, admission: @admission, invoice: @invoice,
                invoice_setting: @invoice_setting, organisation_settings: @organisation_settings,
                refund_payments: @refund_payments, action: params[:action], facility_setting: @facility_setting,
                current_user: @current_user, translated_language: @translated_language, payer_fields: @payer_fields,
                currency_symbol: currency_symbol, visit_diagnoses: @visit_diagnoses, visit_ophthal_investigations: @visit_ophthal_investigations, visit_laboratory_investigations: @visit_laboratory_investigations, visit_radiology_investigations: @visit_radiology_investigations, visit_procedures: @visit_procedures }

    @template = if @invoice.tax_enabled && @invoice_setting.show_tax_in_print
                  "invoice/#{@department.downcase}/print_full_invoice_tax_enabled"
                else
                  "invoice/#{@department.downcase}/print_full_invoice_tax_disabled"
                end
  end

  def fetch_opd_assessment_data
    case_sheet = CaseSheet.where(patient_id: @patient.id,:appointment_ids.in=> [@invoice.appointment_id.to_s])[0]

    if case_sheet.present?
      @visit_diagnoses = case_sheet.diagnoses.where(appointment_id: @invoice.appointment_id.to_s)
      @visit_ophthal_investigations = case_sheet.ophthal_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
      @visit_laboratory_investigations = case_sheet.laboratory_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
      @visit_radiology_investigations = case_sheet.radiology_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
    else
      @visit_diagnoses = nil
      @visit_ophthal_investigations = nil
      @visit_laboratory_investigations = nil
      @visit_radiology_investigations = nil
    end
  end

  def fetch_ipd_assessment_data
    @ipd_record = Inpatient::IpdRecord.where(admission_id: @invoice.admission_id.to_s)[0]

    @visit_diagnoses = @ipd_record.try(:diagnosislist)

    @visit_procedures = @ipd_record.procedure.where(is_performed: true)

    # @visit_ophthal_investigations = @ipd_record.ophthal_investigations_list.where(is_disabled: false)
    # @visit_laboratory_investigations = @ipd_record.laboratory_investigations_list.where(is_disabled: false)
    # @visit_radiology_investigations = @ipd_record.radiology_investigations_list.where(is_disabled: false)
    @visit_ophthal_investigations = nil
    @visit_laboratory_investigations = nil
    @visit_radiology_investigations = nil
  end

  def inventory_invoices_params(_params)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @report.record_details['record_id'])
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: @current_user.organisation_id)
    @locals = { invoice_setting: @invoice_setting, current_user: @current_user, current_facility: @current_facility,
                patient: @patient, inventory_store: @inventory_store, inventory_invoice: @inventory_invoice, mail_job: true, translated_language: @translated_language }

    @template = 'invoice/inventory_invoices/print'
  end

  def inventory_orders_params(_params)
    @inventory_order = Invoice::InventoryOrder.find_by(id: @report.record_details['record_id'])
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: @current_user.organisation_id)
    @locals = { invoice_setting: @invoice_setting, current_user: @current_user, current_facility: @current_facility,
                patient: @patient, inventory_store: @inventory_store, inventory_order: @inventory_order, mail_job: true, translated_language: @translated_language }

    @template = 'invoice/inventory_orders/print'
  end

  def advance_payment_params(_params)
    @advance_payment = AdvancePayment.find_by(id: @report.record_details['record_id'])
    @user = User.find_by(id: @advance_payment.user_id)

    @locals = { mail_job: true, patient: @patient, advance_payment: @advance_payment, user: @user, translated_language: @translated_language }
    @template = 'invoice/advance_payments/print'
  end

  def refund_payment_params(_params)
    @refund_payment = RefundPayment.find_by(id: @report.record_details['record_id'])
    @user = User.find_by(id: @refund_payment.user_id)
    @invoice_id = @refund_payment.try(:invoice_id)
    @invoice = Invoice.find_by(id: @invoice_id) if @invoice_id.present?
    @locals = { mail_job: true, patient: @patient, refund_payment: @refund_payment, invoice: @invoice, user: @user, translated_language: @translated_language }
    @template = 'invoice/refund_payments/print'
  end

  def purchase_order_params(_params)
    @purchase_order = Inventory::Order::Purchase.find_by(id: @report.record_details['record_id'])
    @user = User.find_by(id: @purchase_order.user_id)
    @inventory_store = Inventory::Store.find_by(id: @purchase_order.store_id)
    @entity_name = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s).try(:name)
    @vendor = Inventory::Vendor.find_by(id: @purchase_order.vendor_id)
    @indent = Inventory::Order::Indent.find_by(id: @purchase_order.indent_id)
    @bill_to_store = Inventory::Store.find_by(id: @purchase_order.bill_to_store)
    @ship_to_store = Inventory::Store.find_by(id: @purchase_order.ship_to_store)
    @requisition = Inventory::Order::Requisition.find_by(id: @purchase_order.requisition_order_id)
    @optical_order = Invoice::InventoryOrder.find_by(id: @purchase_order.optical_order_id)

    @locals = {
      mail_job: true, purchase_order: @purchase_order, user: @user, inventory_store: @inventory_store,
      entity_name: @entity_name, vendor: @vendor, indent: @indent, bill_to_store: @bill_to_store,
      ship_to_store: @ship_to_store, requisition: @requisition, optical_order: @optical_order,
      translated_language: @translated_language
    }
    @template = 'inventory/order/purchases/print'
  end
end
