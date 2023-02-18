class IpdRecordWorker
  attr_accessor :record_id
  def initialize(id, template_id, template_type)
    @record_id = id
    @ipdrecord = ::Inpatient::IpdRecord.find_by(id: @record_id)
    @template_type = template_type
    @template_id = template_id
    case template_type
    when 'clinical_note'
      @clinical_note = @ipdrecord.clinical_note
    when 'operative_note'
      @operative_note = @ipdrecord.operative_notes.find_by(id: template_id)
    when 'discharge_note'
      @discharge_note = @ipdrecord.discharge_note
    when 'ward_note'
      @ward_note = @ipdrecord.ward_notes.find_by(id: template_id)
    end
  end

  def call
    # Create PatientDiagnosis
    @patient_diagnosis = PatientDiagnoses::CreateService.call(@ipdrecord, 'ipd')

    # Create PatientProcedure
    @patient_procedure = PatientProcedures::CreateService.call(@ipdrecord, 'ipd')

    # create generic name
    if @discharge_note.present?
      GenericComposition::CreateService.call(@discharge_note)
    end

    admission = Admission.find_by(id: @ipdrecord.admission_id)
    doctor = User.find_by(id: admission.doctor.to_s)

    PatientTimeline.find_by(record_id: @ipdrecord.id, patient_id: @ipdrecord.patient_id).try(:destroy)
    @patient_prescription = PatientPrescription.find_by(record_id: @ipdrecord.id, patient_id: @ipdrecord.patient_id)
    # @patient_prescription.update(is_deleted: true) if @patient_prescription.count > 0

    patient_timeline = PatientTimeline.new
    patient_timeline['doctor_name'] = doctor.fullname
    patient_timeline['doctor'] = admission.doctor.to_s
    patient_timeline['user_id'] = admission.doctor.to_s
    patient_timeline['facility_id'] = admission.facility_id
    patient_timeline['patient_id'] = @ipdrecord.patient_id
    patient_timeline['record_id'] = @ipdrecord.id
    patient_timeline['encountertype'] = @ipdrecord.encountertype
    patient_timeline['encountertypeid'] = @ipdrecord.encountertypeid
    patient_timeline['admission_id'] = @ipdrecord.admission_id
    patient_timeline['templatetype'] = @template_type
    patient_timeline['templateid'] = @template_id
    patient_timeline['specalityid'] = @ipdrecord.specialty_id
    patient_timeline['specialty_name'] = @ipdrecord.specalityname
    patient_timeline['encounterdate'] = @ipdrecord.created_at
    patient_timeline.save

    if @discharge_note.present?
      if @patient_prescription.present?
        if @discharge_note.has_treatmentmedication?
          prescription_data = @discharge_note[:treatmentmedication]
          patient_prescriptions = {}
          patient_prescriptions['consultant_name'] = doctor.fullname
          patient_prescriptions['consultant_id'] = admission.doctor.to_s
          patient_prescriptions['user_id'] = admission.doctor.to_s
          patient_prescriptions['specalityname'] = @ipdrecord.specalityname
          patient_prescriptions['specalityid'] = @ipdrecord.specialty_id
          patient_prescriptions['facility_id'] = admission.facility_id
          patient_prescriptions['patient_id'] = @ipdrecord.patient_id
          patient_prescriptions['encounterdate'] = @discharge_note.note_created_at
          patient_prescriptions['store_name'] = @discharge_note.store_name
          patient_prescriptions['store_id'] = @discharge_note.store_id
          patient_prescriptions['store_present'] = @discharge_note.store_present
          patient_prescriptions['is_deleted'] = false
          patient_prescriptions['medications'] = []
          if prescription_data.present? && prescription_data.count > 0
            prescription_data.each_with_index do |medication, i|
              patient_prescriptions['medications'][i.to_i] = Hash['position' => (i.to_i + 1).to_s,
                                                                  'medicinename' => (medication[:medicinename]).to_s,
                                                                  'medicinequantity' => (medication[:medicinequantity]).to_s,
                                                                  'medicinefrequency' => (medication[:medicinefrequency]).to_s,
                                                                  'medicinedurationoption' => (medication[:medicinedurationoption]).to_s,
                                                                  'medicineduration' => (medication[:medicineduration]).to_s,
                                                                  'prescriptiondate' => @discharge_note.note_created_at.to_s,
                                                                  'medicineinstructions' => (medication[:medicineinstructions]).to_s,
                                                                  'instruction' => (medication[:instruction]).to_s,
                                                                  'pharmacy_item_id' => (medication[:pharmacy_item_id]).to_s,
                                                                  'generic_display_name' => (medication[:generic_display_name]).to_s,
                                                                  'generic_display_ids' => (medication[:generic_display_ids]).to_s,
                                                                  'medicine_from' => (medication[:medicine_from]).to_s]
            end
            patient_prescriptions['prescription_date'] = Date.current
            patient_prescriptions['prescription_datetime'] = Time.current
            patient_prescriptions['authorid'] =  admission.user_id.to_s
          end
          @patient_prescription.update(patient_prescriptions)
        else
          @patient_prescription.update(is_deleted: true)
        end
        InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @patient_prescription.id.to_s)
      else
        patient = Patient.find_by(id: @ipdrecord.patient_id)
        patient_name = (patient.firstname.to_s + ' ' + patient.middlename.to_s + ' ' + patient.lastname.to_s).split.join(' ')
        patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
        mobile_number = patient.mobilenumber
        mr_no = patient.patient_mrn
        mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
        reg_hosp_ids = patient.reg_hosp_ids
        patient_identifier_id = patient.patient_identifier_id
        patient_identifier_id_search = patient_identifier_id.to_s.split('').map { |x| x[/\d+/] }.join('')
        search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name} #{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search} #{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search} #{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}".downcase

        prescription_data = @discharge_note[:treatmentmedication]
        patient_prescriptions = PatientPrescription.new
        patient_prescriptions['my_queue'] = true
        patient_prescriptions['consultant_name'] = doctor.fullname
        patient_prescriptions['consultant_id'] = admission.doctor.to_s
        patient_prescriptions['user_id'] = admission.doctor.to_s
        patient_prescriptions['facility_id'] = admission.facility_id
        patient_prescriptions['patient_id'] = @ipdrecord.patient_id
        patient_prescriptions['store_name'] = @discharge_note.store_name
        patient_prescriptions['store_id'] = @discharge_note.store_id
        patient_prescriptions['store_present'] = @discharge_note.store_present

        patient_prescriptions['search'] = search
        patient_prescriptions['patient_name'] = patient_name
        patient_prescriptions['mobile_number'] = mobile_number
        patient_prescriptions['patient_identifier_id'] = patient_identifier_id
        patient_prescriptions['mr_no'] = mr_no
        patient_prescriptions['patient_identifier_id_search'] = patient_identifier_id_search
        patient_prescriptions['mr_no_search'] = mr_no_search
        patient_prescriptions['patient_name_search'] = patient_name_search
        patient_prescriptions['reg_hosp_ids'] = reg_hosp_ids

        patient_prescriptions['record_id'] = @ipdrecord.id
        patient_prescriptions['encountertype'] = @ipdrecord.encountertype
        patient_prescriptions['encountertypeid'] = @ipdrecord.encountertypeid
        patient_prescriptions['admission_id'] = @ipdrecord.admission_id
        patient_prescriptions['tepmlatetype'] = @ipdrecord.templatetype
        patient_prescriptions['templateid'] = @ipdrecord.templateid
        patient_prescriptions['specalityid'] = @ipdrecord.specialty_id
        patient_prescriptions['specialty_id'] = @ipdrecord.specialty_id
        patient_prescriptions['specalityname'] = @ipdrecord.specalityname
        patient_prescriptions['encounterdate'] = @discharge_note.note_created_at
        if prescription_data.present? && prescription_data.count > 0
          prescription_data.each_with_index do |medication, i|
            patient_prescriptions['medications'][i.to_i] = Hash['position' => (i.to_i + 1).to_s,
                                                                'medicinename' => (medication[:medicinename]).to_s,
                                                                'medicinequantity' => (medication[:medicinequantity]).to_s,
                                                                'medicinefrequency' => (medication[:medicinefrequency]).to_s,
                                                                'medicinedurationoption' => (medication[:medicinedurationoption]).to_s,
                                                                'medicineduration' => (medication[:medicineduration]).to_s,
                                                                'prescriptiondate' => @discharge_note.note_created_at.to_s,
                                                                'medicineinstructions' => (medication[:medicineinstructions]).to_s,
                                                                'instruction' => (medication[:instruction]).to_s,
                                                                'pharmacy_item_id' => (medication[:pharmacy_item_id]).to_s,
                                                                'generic_display_name' => (medication[:generic_display_name]).to_s,
                                                                'generic_display_ids' => (medication[:generic_display_ids]).to_s,
                                                                'medicine_from' => (medication[:medicine_from]).to_s]
          end
          patient_prescriptions['prescription_date'] = Date.current
          patient_prescriptions['prescription_datetime'] = Time.current
          patient_prescriptions['authorid'] =  admission.user_id.to_s
        end
        patient_prescriptions.save
        InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', patient_prescriptions.id.to_s)
      end
    end

    update_document_service if @template_type == 'discharge_note' && admission.insurance_status != 'Not Insured'
  end

  private

  def update_document_service
    facility = Facility.find_by(id: @ipdrecord.facility_id)
    return if facility.nil?

    integration_key = facility.integration_keys.find { |key| key[:url] == 'updateDocumentService' }
    provider = integration_key[:providers][0] if integration_key.present?
    return if provider.nil?

    create_document = Document::Create.new
    create_document.call('DischargeNote', @ipdrecord.id.to_s, @ipdrecord.facility_id.to_s, provider)
  end
end
