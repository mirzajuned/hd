class CaseSheet::CreateOpdRecordService
  def self.call(record)
    case_sheet = CaseSheet.find_by(id: record.case_sheet_id)

    return unless case_sheet.present?

    @analytics_params = {}
    analytics_before_params_opd_record(case_sheet.id)

    record_user = User.find(record.userid).try(:fullname)

    # opd_record_id
    opd_record_ids = case_sheet.opd_record_ids
    opd_record_ids << record.id.to_s
    case_sheet[:opd_record_ids] = opd_record_ids.uniq

    # Freeform fields
    case_sheet[:free_form_histories] = case_sheet.free_form_histories
    case_sheet[:free_form_examinations] = case_sheet.free_form_examinations
    case_sheet[:free_form_diagnoses] = case_sheet.free_form_diagnoses
    case_sheet[:free_form_procedures] = case_sheet.free_form_procedures
    case_sheet[:free_form_investigations] = case_sheet.free_form_investigations

    case_sheet[:provisional_diagnosis] = case_sheet.provisional_diagnosis

    # embeded case_sheet free_form fields
    options = { record_id: record.id.to_s, record_type: 'opd_record', consultant_id: record.consultant_id,
                consultant_name: record.consultant_name, date: record.updated_at }

    unless record.clincalevaluation.blank? || record.clincalevaluation == '<br>'
      case_sheet[:free_form_histories][record.id.to_s] = options.merge(content: record.clincalevaluation)
    end
    unless record.examination.blank? || record.examination == '<br>'
      case_sheet[:free_form_examinations][record.id.to_s] = options.merge(content: record.examination)
    end
    unless record.diagnosiscomments.blank? || record.diagnosiscomments == '<br>'
      case_sheet[:free_form_diagnoses][record.id.to_s] = options.merge(content: record.diagnosiscomments)
    end
    unless record.diagnosis_text.blank? || record.diagnosis_text == '<br>'
      case_sheet[:free_form_diagnoses][record.id.to_s] = options.merge(content: record.diagnosis_text)
    end
    unless record.procedurecomments.blank? || record.procedurecomments == '<br>'
      case_sheet[:free_form_procedures][record.id.to_s] = options.merge(content: record.procedurecomments)
    end
    unless record.free_procedure.blank? || record.free_procedure == '<br>'
      case_sheet[:free_form_procedures][record.id.to_s] = options.merge(content: record.free_procedure)
    end
    unless record.plan.blank? || record.plan == '<br>'
      case_sheet[:free_form_investigations][record.id.to_s] = options.merge(content: record.plan)
    end

    if record.specalityid == '309989009' && !record.procedurecomments.blank?
      case_sheet[:free_form_procedures][record.id.to_s] = options.merge(content: record.procedurecomments)
    end

    # provisional diagnosis
    if record.provisional_diagnosis
      case_sheet[:provisional_diagnosis][record.id.to_s] = Hash[record_id: record.id.to_s, record_type: "opd_record", consultant_id: record.consultant_id, consultant_name: record.consultant_name, content: record.provisional_diagnosis, date: Time.current]
    end

    # embeded record documents
    opd_chief_complaints = record.chief_complaints
    opd_diagnoses = record.diagnosislist
    opd_procedures = record.procedure
    opd_ophthal_investigations = record.ophthalinvestigationlist
    opd_laboratory_investigations = record.addedlaboratoryinvestigationlist
    opd_radiology_investigations = record.investigationlist

    # embeded record document ids
    record_chief_complaint_ids = opd_chief_complaints.pluck(:id).map(&:to_s)
    record_diagnosis_ids = opd_diagnoses.pluck(:id).map(&:to_s)
    record_procedure_ids = opd_procedures.pluck(:id).map(&:to_s)
    record_ophthal_investigation_ids = opd_ophthal_investigations.pluck(:id).map(&:to_s)
    record_laboratory_investigation_ids = opd_laboratory_investigations.pluck(:id).map(&:to_s)
    record_radiology_investigation_ids = opd_radiology_investigations.pluck(:id).map(&:to_s)

    # HISTORY
    # Add Chief Complaints
    opd_chief_complaints.each do |chief_complaint|
      case_sheet_chief_complaint = case_sheet.chief_complaints.find_by(opd_chief_complaint_id: chief_complaint.id.to_s, record_id: record.id.to_s)
      if case_sheet_chief_complaint.present?
        new_chief_complaint = case_sheet_chief_complaint
      else
        new_chief_complaint = case_sheet.chief_complaints.new
      end
      if new_chief_complaint.present?
        chief_complaint_params(new_chief_complaint, record, chief_complaint)

        new_chief_complaint.save

        chief_complaint.update(case_sheet_chief_complaint_id: new_chief_complaint.id)
      end
    end

    # Remove Chief Complaints
    case_sheet.chief_complaints.where(record_id: record.id.to_s).each do |chief_complaint|
      unless record_chief_complaint_ids.include?(chief_complaint.opd_chief_complaint_id.to_s)
        chief_complaint.destroy
      end
    end
    # HISTORY ENDS

    # DIAGNOSIS
    # Add Diagnosis
    opd_diagnoses.each do |diagnosis|
      case_sheet_diagnosis = case_sheet.diagnoses.find_by(opd_diagnosis_id: diagnosis.id.to_s, record_id: record.id.to_s)
      if case_sheet_diagnosis.present?
        new_diagnosis = case_sheet_diagnosis
      else
        new_diagnosis = case_sheet.diagnoses.new
      end
      if new_diagnosis.present?
        diagnosis_params(new_diagnosis, record, diagnosis)

        new_diagnosis.save

        diagnosis.update(case_sheet_diagnosis_id: new_diagnosis.id)
      end
    end

    # Remove Diagnosis
    case_sheet.diagnoses.where(record_id: record.id.to_s).each do |diagnosis|
      unless record_diagnosis_ids.include?(diagnosis.opd_diagnosis_id.to_s)
        diagnosis.destroy
      end
    end

    # Disable Diagnosis
    disabled_diagnosis_array = record.disabled_diagnosis_codes.to_s.split(",")
    case_sheet.diagnoses.where(:icddiagnosiscode.in => disabled_diagnosis_array).each do |diagnosis|
      diagnosis.update(is_disabled: true, disabled_by_id: record.userid, disabled_by: record_user.try(:fullname))
    end
    # DIAGNOSIS ENDS

    # PROCEDURES
    # Add Procedure
    opd_procedures.each_with_index do |procedure, i|
      procedure_side_array = (['18944008', '8966001'] if procedure.procedureside.to_s == "40638003") || [procedure.procedureside.to_s]

      case_sheet_procedure = case_sheet.procedures.where(opd_procedure_id: procedure.id.to_s, record_id: record.id.to_s)
      procedure_side_array.each_with_index do |side, i|
        case_sheet_procedure_side = case_sheet_procedure.find_by(procedureside: side)
        if case_sheet_procedure.count > 0
          if procedure.procedureside == case_sheet_procedure_side.try(:procedureoriginalside) #no change done in the procedure
            if case_sheet_procedure_side.present?
              new_procedure = case_sheet_procedure_side
            end
          else #change is done in the procedure
            if case_sheet_procedure.count > 1 #originally BE procedure was given
              removed_procedure = case_sheet_procedure.find_by(:procedureside.nin => [side]) #originally BE was given and updated to single lateral and the other side is deleted from casesheet
              procedure_order_advised = Order::Advised.find_by(display_id: removed_procedure.try(:order_display_id).to_s, patient_id: case_sheet.try(:patient_id))
              procedure_order_advised.update(active: false, status: "Cancelled")
              removed_procedure.try(:destroy) if procedure_order_advised.present?

              new_procedure = case_sheet_procedure_side
            elsif case_sheet_procedure.count == 1 #originally single lateral procedure was given and  updated to another laterality
              if case_sheet_procedure_side.present? # single lateral procedure was given either 18944008 or 8966001
                new_procedure = case_sheet_procedure_side
              elsif procedure_side_array.count == 1 # procedureside other than 40638003, 18944008, 8966001
                new_procedure = case_sheet_procedure[0]
              else

                new_procedure = case_sheet.procedures.new # not sure
              end
            else  #case_sheet_procedure.count == 0
              new_procedure = case_sheet.procedures.new
            end
          end
        else #case_sheet_procedure.count == 0
          new_procedure = case_sheet.procedures.new
        end
        if new_procedure.present?
          if new_procedure.procedurestage.blank? || new_procedure.procedurestage == "Advised" || (new_procedure.procedurestage == "Performed" && new_procedure.performed_from == "opd_record")
            procedure_params(new_procedure, record, procedure, side)
            new_procedure.save

            procedure.update(case_sheet_procedure_id: new_procedure.id)
            if new_procedure.procedurestage != "Performed"
              procedure_order_status_params(new_procedure, record, side)
            end
          end
        end
      end
    end

    # Remove Procedure
    case_sheet.procedures.where(record_id: record.id.to_s).each do |procedure|
      unless record_procedure_ids.include?(procedure.opd_procedure_id.to_s)
        procedure_order_advised = Order::Advised.where(display_id: procedure.try(:order_display_id).to_s, patient_id: case_sheet.try(:patient_id))
        if procedure_order_advised.present?
          procedure_order_advised.update_all(active: false, status: 'Cancelled')
        end
        procedure.destroy
      end
    end

    # Disable Procedure
    disabled_procedure_array = record.disabled_procedure_codes.to_s.split(",")
    case_sheet.procedures.where(:procedurefullcode.in => disabled_procedure_array, is_performed: false).each do |procedure|
      procedure.update(is_disabled: true, disabled_by_id: record.userid, disabled_by: record_user.try(:fullname))
    end
    # PROCEDURES ENDS

    # OPHTHAL INVESTIGATION
    # Add Investigation
    opd_ophthal_investigations.each do |ophthal_investigation|
      ophthal_investigation_side_array = [ophthal_investigation.investigationside.to_s]

      case_sheet_ophthal_investigation = case_sheet.ophthal_investigations.where(opd_investigation_id: ophthal_investigation.id.to_s, record_id: record.id.to_s)
      ophthal_investigation_side_array.each_with_index do |side, i|
        case_sheet_ophthal_investigation_side = case_sheet_ophthal_investigation.find_by(investigationside: side)
        if case_sheet_ophthal_investigation.count > 0
          if ophthal_investigation.investigationside == case_sheet_ophthal_investigation_side.try(:investigationoriginalside)
            if case_sheet_ophthal_investigation_side.present?
              new_ophthal_investigation = case_sheet_ophthal_investigation_side
            end
          else
            if case_sheet_ophthal_investigation.count > 1
              removed_ophthal_investigation = case_sheet_ophthal_investigation.find_by(:investigationside.nin => [side])

              investigation_order_advised = Order::Advised.find_by(display_id: removed_ophthal_investigation.try(:order_display_id).to_s, patient_id: case_sheet.try(:patient_id))
              investigation_order_advised.update(active: false, status: "Cancelled")

              removed_ophthal_investigation.try(:destroy)

              new_ophthal_investigation = case_sheet_ophthal_investigation_side
            elsif case_sheet_ophthal_investigation.count == 1
              if case_sheet_ophthal_investigation_side.present?
                new_ophthal_investigation = case_sheet_ophthal_investigation_side
              elsif ophthal_investigation_side_array.count == 1
                new_ophthal_investigation = case_sheet_ophthal_investigation[0]
              else
                new_ophthal_investigation = case_sheet.ophthal_investigations.new
              end
            else
              new_ophthal_investigation = case_sheet.ophthal_investigations.new
            end
          end
        else
          new_ophthal_investigation = case_sheet.ophthal_investigations.new
        end
        if new_ophthal_investigation.present?
          if new_ophthal_investigation.investigationstage.blank? || new_ophthal_investigation.investigationstage == "Advised" || (new_ophthal_investigation.investigationstage == "Performed" && new_ophthal_investigation.performed_from == "opd_record")
            ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation, side)

            new_ophthal_investigation.save

            ophthal_investigation.update(case_sheet_investigation_id: new_ophthal_investigation.id)
            if new_ophthal_investigation.investigationstage != "Performed"
              ophthal_investigation_order_status_params(new_ophthal_investigation, record, side)
            end
          end
        end
      end
    end

    # Remove Investigation
    case_sheet.ophthal_investigations.where(record_id: record.id.to_s).each do |ophthal_investigation|
      unless record_ophthal_investigation_ids.include?(ophthal_investigation.opd_investigation_id.to_s)
        investigation_order_advised = Order::Advised.find_by(display_id: ophthal_investigation.try(:order_display_id).to_s, patient_id: case_sheet.try(:patient_id))
        if investigation_order_advised.present?
          investigation_order_advised.update(active: false, status: "Cancelled")
        end
        ophthal_investigation.destroy
      end
    end
    # OPHTHAL INVESTIGATION ENDS

    # LABORATORY INVESTIGATION
    # Add Investigation
    opd_laboratory_investigations.each do |laboratory_investigation|
      case_sheet_laboratory_investigation = case_sheet.laboratory_investigations.find_by(opd_investigation_id: laboratory_investigation.id.to_s, record_id: record.id.to_s)
      if case_sheet_laboratory_investigation.present?
        new_laboratory_investigation = case_sheet_laboratory_investigation
      else
        new_laboratory_investigation = case_sheet.laboratory_investigations.new
      end
      if new_laboratory_investigation.present?
        if new_laboratory_investigation.investigationstage.blank? || new_laboratory_investigation.investigationstage == "Advised" || (new_laboratory_investigation.investigationstage == "Performed" && new_laboratory_investigation.performed_from == "opd_record")
          laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

          new_laboratory_investigation.save

          laboratory_investigation.update(case_sheet_investigation_id: new_laboratory_investigation.id)
          if new_laboratory_investigation.investigationstage != "Performed"
            laboratory_investigation_order_status_params(new_laboratory_investigation, record, '')
          end
        end
      end
    end

    # Remove Investigation
    case_sheet.laboratory_investigations.where(record_id: record.id.to_s).each do |laboratory_investigation|
      unless record_laboratory_investigation_ids.include?(laboratory_investigation.opd_investigation_id.to_s)
        investigation_order_advised = Order::Advised.find_by(display_id: laboratory_investigation.try(:order_display_id).to_s, patient_id: case_sheet.try(:patient_id))
        if investigation_order_advised.present?
          investigation_order_advised.update(active: false, status: "Cancelled")
        end
        laboratory_investigation.destroy
      end
    end
    # LABORATORY INVESTIGATION ENDS

    # RADIOLOGY INVESTIGATION
    # Add Investigation
    opd_radiology_investigations.each do |radiology_investigation|
      case_sheet_radiology_investigation = case_sheet.radiology_investigations.find_by(opd_investigation_id: radiology_investigation.id.to_s, record_id: record.id.to_s)
      if case_sheet_radiology_investigation.present?
        new_radiology_investigation = case_sheet_radiology_investigation
      else
        new_radiology_investigation = case_sheet.radiology_investigations.new
      end
      if new_radiology_investigation.present?
        if new_radiology_investigation.investigationstage.blank? || new_radiology_investigation.investigationstage == "Advised" || (new_radiology_investigation.investigationstage == "Performed" && new_radiology_investigation.performed_from == "opd_record")
          radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

          new_radiology_investigation.save

          radiology_investigation.update(case_sheet_investigation_id: new_radiology_investigation.id)
          if new_radiology_investigation.investigationstage != "Performed"
            radiology_investigation_order_status_params(new_radiology_investigation, record, '')
          end
        end
      end
    end

    # Remove Investigation
    case_sheet.radiology_investigations.where(record_id: record.id.to_s).each do |radiology_investigation|
      unless record_radiology_investigation_ids.include?(radiology_investigation.opd_investigation_id.to_s)
        investigation_order_advised = Order::Advised.find_by(display_id: radiology_investigation.try(:order_display_id).to_s, patient_id: case_sheet.try(:patient_id))
        if investigation_order_advised.present?
          investigation_order_advised.update(active: false, status: "Cancelled")
        end
        radiology_investigation.destroy
      end
    end
    # RADIOLOGY INVESTIGATION ENDS

    if case_sheet.save!

      analytics_after_params_opd_record(case_sheet)

      if record.consultant_id.present?
        Analytics::TestCaseSheetOpdRecordJob.perform_later(@analytics_params.to_json, record.consultant_id.to_s, record.facility_id.to_s)
      end
      # Analytics::CreateService.call(@analytics_params.to_json, record.consultant_id.to_s, record.facility_id.to_s, "clinical_data")
    end
  end

  private

  def self.procedure_order_status_params(case_sheet_record_procedure, record, side)
    organisation = Organisation.find_by(id: record.try(:organisation_id))
    organisations_setting = organisation.try(:organisations_setting)
    advise_order_rule = organisations_setting.try(:active_advise_order_rule).to_s

    case_sheet = CaseSheet.find_by(id: record.try(:case_sheet_id))

    if advise_order_rule == 'LIFO'
      case_sheet_existing_procedures = case_sheet.procedures.where(procedurefullcode: case_sheet_record_procedure.procedurefullcode, procedureside: side, :order_status.ne => "closed").order_by('created_at DESC')
    else
      case_sheet_existing_procedures = case_sheet.procedures.where(procedurefullcode: case_sheet_record_procedure.procedurefullcode, procedureside: side, :order_status.ne => "closed").order_by('created_at ASC')
    end

    case_sheet_processing_procedures = case_sheet_existing_procedures.where(order_status: "processing")

    if case_sheet_processing_procedures.present?
      case_sheet_remaining_procedures = case_sheet_existing_procedures.where(:order_status.ne => "processing")
      case_sheet_remaining_procedures.update_all(order_status: "closed")
      active_case_sheet_procedure = case_sheet_processing_procedures.first
    else
      case_sheet_remaining_procedures = case_sheet_existing_procedures.skip(1)
      case_sheet_remaining_procedures.update_all(order_status: "closed")
      active_case_sheet_procedure = case_sheet_existing_procedures.first
      active_case_sheet_procedure.update(order_status: "open")
    end
    remaining_order_advised = Order::Advised.where(:display_id.in => case_sheet_remaining_procedures.to_a.pluck(:order_display_id), patient_id: case_sheet.try(:patient_id))
    remaining_order_advised.update_all(active: false, status: 'Cancelled')

    procedure_attributes = active_case_sheet_procedure.attributes.except(:_id)
    active_order_advised = Order::Advised.find_by(order_item_advised_id: active_case_sheet_procedure.order_item_advised_id.to_s, procedureside: active_case_sheet_procedure.procedureside)


    if active_order_advised
      active_order_advised.assign_attributes(procedure_attributes)
    else
      active_order_advised = Order::Advised.new(procedure_attributes)
      active_order_advised.assign_attributes(display_id: CommonHelper.get_procedure_order_identifier(organisation.id),
                                             organisation_id: record.try(:organisation_id), facility_id: record.try(:facility_id),
                                             patient_id: case_sheet.try(:patient_id), case_sheet_id: case_sheet.id,
                                             status: 'Advised', active: true)
    end
    active_order_advised.quantity = 1
    active_order_advised.active = true
    active_order_advised.type = 'procedures'
    active_order_advised.save
    if active_order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', active_order_advised)
    end
    active_case_sheet_procedure.update(order_advised_id: active_order_advised.id.to_s, order_display_id: active_order_advised.display_id)

  end

  def self.ophthal_investigation_order_status_params(investigation, record, side)
    case_sheet = CaseSheet.find_by(id: record.try(:case_sheet_id))

    investigation_attributes = investigation.attributes.except(:_id)
    if investigation.investigationstage == "Counselled" && investigation.status == "Agreed"
      investigation_attributes.merge(
          {
              agreed_by: investigation.counselled_by,
              agreed_by_id: investigation.counselled_by_id,
              agreed_datetime: investigation.counselled_datetime,
              agreed_at_facility: investigation.counselled_at_facility,
              agreed_at_facility_id: investigation.counselled_at_facility_id,
              has_agreed: true
          }
      )
    end
    order_advised = Order::Advised.find_by(order_item_advised_id: investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.assign_attributes(investigation_attributes)
    else
      order_advised = Order::Advised.new(investigation_attributes)
      order_advised.assign_attributes(display_id: CommonHelper.get_investigation_order_identifier(record.organisation_id),
                                      organisation_id: record.try(:organisation_id), facility_id: record.try(:facility_id),
                                      patient_id: case_sheet.try(:patient_id), case_sheet_id: record.try(:case_sheet_id),
                                      type: 'ophthal_investigations',
                                      status: 'Advised'
      )
    end
    if investigation.investigationside == "40638003"
      order_advised.quantity = 2
    else
      order_advised.quantity = 1
    end
    order_advised.active = true
    order_advised.save

    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    end

    investigation.update(order_advised_id: order_advised.id.to_s, order_display_id: order_advised.display_id)

  end


  def self.radiology_investigation_order_status_params(investigation, record, side)
    case_sheet = CaseSheet.find_by(id: record.try(:case_sheet_id))
    investigation_attributes = investigation.attributes.except(:_id)
    if investigation.investigationstage == "Counselled" && investigation.status == "Agreed"
      investigation_attributes.merge(
          {
              agreed_by: investigation.counselled_by,
              agreed_by_id: investigation.counselled_by_id,
              agreed_datetime: investigation.counselled_datetime,
              agreed_at_facility: investigation.counselled_at_facility,
              agreed_at_facility_id: investigation.counselled_at_facility_id,
              has_agreed: true
          }
      )
    end
    order_advised = Order::Advised.find_by(order_item_advised_id: investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.assign_attributes(investigation_attributes)
    else
      order_advised = Order::Advised.new(investigation_attributes)
      order_advised.assign_attributes(display_id: CommonHelper.get_investigation_order_identifier(record.organisation_id),
                                      organisation_id: record.try(:organisation_id), facility_id: record.try(:facility_id),
                                      patient_id: case_sheet.try(:patient_id), case_sheet_id: record.try(:case_sheet_id),
                                      type: 'radiology_investigations',
                                      status: 'Advised'
      )
    end
    order_advised.quantity = 1
    order_advised.active = true
    order_advised.save
    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    end
  end

  def self.laboratory_investigation_order_status_params(investigation, record, side)
    case_sheet = CaseSheet.find_by(id: record.try(:case_sheet_id))
    investigation_attributes = investigation.attributes.except(:_id)
    if investigation.investigationstage == "Counselled" && investigation.status == "Agreed"
      investigation_attributes.merge(
          {
              agreed_by: investigation.counselled_by,
              agreed_by_id: investigation.counselled_by_id,
              agreed_datetime: investigation.counselled_datetime,
              agreed_at_facility: investigation.counselled_at_facility,
              agreed_at_facility_id: investigation.counselled_at_facility_id,
              has_agreed: true
          }
      )
    end
    order_advised = Order::Advised.find_by(order_item_advised_id: investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.assign_attributes(investigation_attributes)
    else
      order_advised = Order::Advised.new(investigation_attributes)
      order_advised.assign_attributes(display_id: CommonHelper.get_investigation_order_identifier(record.organisation_id),
                                      organisation_id: record.try(:organisation_id), facility_id: record.try(:facility_id),
                                      patient_id: case_sheet.try(:patient_id), case_sheet_id: record.try(:case_sheet_id),
                                      type: 'laboratory_investigations',
                                      status: 'Advised'
      )
    end
    order_advised.quantity = 1
    order_advised.active = true
    order_advised.save
    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    end
  end


  def self.chief_complaint_params(new_chief_complaint, record, chief_complaint)
    new_chief_complaint[:record_id] = record.id.to_s
    new_chief_complaint[:appointment_id] = record.appointmentid
    new_chief_complaint[:opd_chief_complaint_id] = chief_complaint.id

    new_chief_complaint[:name] = chief_complaint.name
    new_chief_complaint[:side] = chief_complaint.side
    new_chief_complaint[:duration] = chief_complaint.duration
    new_chief_complaint[:duration_unit] = chief_complaint.duration_unit
    new_chief_complaint[:comment] = chief_complaint.comment
    new_chief_complaint[:complaint_options] = chief_complaint.complaint_options

    new_chief_complaint[:user_id] = record.userid
    new_chief_complaint[:consultant_id] = record.consultant_id
    new_chief_complaint[:consultant_name] = record.consultant_name
    new_chief_complaint[:template_type] = record.templatetype

    new_chief_complaint[:entered_by] = record.consultant_name
    new_chief_complaint[:entered_by_id] = record.consultant_id
    new_chief_complaint[:entered_datetime] = chief_complaint.created_at
    new_chief_complaint[:entered_from] = 'opd_record'
  end

  def self.diagnosis_params(new_diagnosis, record, diagnosis)
    new_diagnosis[:record_id] = record.id.to_s
    new_diagnosis[:appointment_id] = record.appointmentid
    new_diagnosis[:opd_diagnosis_id] = diagnosis.id
    new_diagnosis[:diagnosisname] = diagnosis.diagnosisname
    new_diagnosis[:diagnosisoriginalname] = diagnosis.diagnosisoriginalname
    new_diagnosis[:icddiagnosiscode] = diagnosis.icddiagnosiscode
    new_diagnosis[:saperatedicddiagnosiscode] = diagnosis.saperatedicddiagnosiscode
    new_diagnosis[:icddiagnosiscodelength] = diagnosis.icddiagnosiscodelength
    new_diagnosis[:icd_type] = diagnosis.icd_type
    new_diagnosis[:diagnosis_comment] = diagnosis.diagnosis_comment
    new_diagnosis[:users_comment] = diagnosis.users_comment

    new_diagnosis[:user_id] = record.userid
    new_diagnosis[:consultant_id] = record.consultant_id
    new_diagnosis[:consultant_name] = record.consultant_name
    new_diagnosis[:template_type] = record.templatetype

    new_diagnosis[:entered_by] = diagnosis.entered_by
    new_diagnosis[:entered_by_id] = diagnosis.entered_by_id
    new_diagnosis[:entered_datetime] = diagnosis.entry_datetime
    new_diagnosis[:entered_from] = 'opd_record'
    new_diagnosis[:entered_at_facility] = diagnosis.entered_at_facility
    new_diagnosis[:entered_at_facility_id] = diagnosis.entered_at_facility_id

    new_diagnosis[:is_advised] = true
    new_diagnosis[:advised_by] = diagnosis.advised_by
    new_diagnosis[:advised_by_id] = diagnosis.advised_by_id
    new_diagnosis[:advised_datetime] = diagnosis.advised_datetime
    new_diagnosis[:advised_from] = 'opd_record'
    new_diagnosis[:advised_at_facility] = diagnosis.advised_at_facility
    new_diagnosis[:advised_at_facility_id] = diagnosis.advised_at_facility_id
  end

  def self.procedure_params(new_procedure, record, procedure, side)
    if procedure.procedurestage == "A"
      stage = "Advised"
    elsif procedure.procedurestage == "P"
      stage = "Performed"
      new_procedure[:order_status] = "closed"
      new_procedure[:order_created] = false
    end

    new_procedure[:record_id] = record.id.to_s
    new_procedure[:appointment_id] = record.appointmentid
    new_procedure[:opd_procedure_id] = procedure.id
    new_procedure[:procedurestage] = stage
    new_procedure[:procedurename] = procedure.procedurename
    new_procedure[:procedure_id] = procedure.procedure_id
    new_procedure[:procedureoriginalside] = procedure.procedureside
    new_procedure[:procedureside] = side
    new_procedure[:procedurefullcode] = procedure.procedurefullcode
    new_procedure[:procedure_type] = procedure.procedure_type
    new_procedure[:procedure_comment] = procedure.procedure_comment
    new_procedure[:users_comment] = procedure.users_comment
    new_procedure[:order_item_advised_id] = procedure.order_item_advised_id.to_s

    new_procedure[:user_id] = record.userid
    new_procedure[:consultant_id] = record.consultant_id
    new_procedure[:consultant_name] = record.consultant_name
    new_procedure[:template_type] = record.templatetype

    new_procedure[:entered_by_id] = procedure.entered_by_id
    new_procedure[:entered_by] = procedure.entered_by
    new_procedure[:entered_datetime] = procedure.entered_datetime
    new_procedure[:entered_from] = 'opd_record'
    new_procedure[:entered_at_facility_id] = procedure.entered_at_facility_id
    new_procedure[:entered_at_facility] = procedure.entered_at_facility

    new_procedure[:is_advised] = true
    new_procedure[:advised_by] = procedure.advised_by
    new_procedure[:advised_by_id] = procedure.advised_by_id
    new_procedure[:advised_datetime] = procedure.advised_datetime
    new_procedure[:advised_from] = 'opd_record'
    new_procedure[:advised_at_facility] = procedure.advised_at_facility
    new_procedure[:advised_at_facility_id] = procedure.advised_at_facility_id

    if procedure.procedurestage == "P"
      new_procedure[:is_performed] = true
      new_procedure[:performed_by_id] = procedure.performed_by_id
      new_procedure[:performed_by] = procedure.performed_by
      new_procedure[:performed_datetime] = procedure.performed_datetime
      new_procedure[:performed_date] = procedure.performed_date
      new_procedure[:performed_time] = procedure.performed_time
      new_procedure[:performed_from] = 'opd_record'
      new_procedure[:performed_at_facility_id] = procedure.performed_at_facility_id
      new_procedure[:performed_at_facility] = procedure.performed_at_facility
      new_procedure[:performed_comment] = procedure.procedure_comment
    else
      new_procedure[:is_performed] = false
      new_procedure[:performed_by_id] = nil
      new_procedure[:performed_by] = nil
      new_procedure[:performed_at] = nil
      new_procedure[:performed_from] = nil
      new_procedure[:performed_at_facility_id] = nil
      new_procedure[:performed_at_facility] = nil
      new_procedure[:performed_comment] = nil
    end
  end

  def self.ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation, side)
    if ophthal_investigation.investigationstage == "A"
      stage = "Advised"
    elsif ophthal_investigation.investigationstage == "P"
      stage = "Performed"
    end
    new_ophthal_investigation[:record_id] = record.id.to_s
    new_ophthal_investigation[:appointment_id] = record.appointmentid
    new_ophthal_investigation[:opd_investigation_id] = ophthal_investigation.id
    new_ophthal_investigation[:investigationstage] = stage
    new_ophthal_investigation[:investigationname] = ophthal_investigation.investigationname
    new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
    new_ophthal_investigation[:investigationoriginalside] = ophthal_investigation.investigationside
    new_ophthal_investigation[:investigationside] = side
    new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigationfullcode
    new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type
    new_ophthal_investigation[:order_item_advised_id] = ophthal_investigation.order_item_advised_id.to_s

    new_ophthal_investigation[:user_id] = record.userid
    new_ophthal_investigation[:consultant_id] = record.consultant_id
    new_ophthal_investigation[:consultant_name] = record.consultant_name
    new_ophthal_investigation[:template_type] = record.templatetype

    new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by_id
    new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by
    new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_datetime
    new_ophthal_investigation[:entered_from] = 'opd_record'
    new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id
    new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility

    new_ophthal_investigation[:is_advised] = true
    new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by
    new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by_id
    new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_datetime
    new_ophthal_investigation[:advised_from] = 'opd_record'
    new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility
    new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id

    if ophthal_investigation.investigationstage == "P"
      new_ophthal_investigation[:is_performed] = true
      new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by_id
      new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by
      new_ophthal_investigation[:performed_datetime] = ophthal_investigation.performed_datetime
      new_ophthal_investigation[:performed_from] = 'opd_record'
      new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id
      new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility
      new_ophthal_investigation[:performed_comment] = ophthal_investigation.investigation_performed
    else
      new_ophthal_investigation[:is_performed] = false
      new_ophthal_investigation[:performed_by_id] = nil
      new_ophthal_investigation[:performed_by] = nil
      new_ophthal_investigation[:performed_at] = nil
      new_ophthal_investigation[:performed_from] = nil
      new_ophthal_investigation[:performed_at_facility_id] = nil
      new_ophthal_investigation[:performed_at_facility] = nil
      new_ophthal_investigation[:performed_comment] = nil
    end
  end

  def self.laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)
    if laboratory_investigation.investigationstage == "A"
      stage = "Advised"
    elsif laboratory_investigation.investigationstage == "P"
      stage = "Performed"
    end

    new_laboratory_investigation[:record_id] = record.id.to_s
    new_laboratory_investigation[:appointment_id] = record.appointmentid
    new_laboratory_investigation[:opd_investigation_id] = laboratory_investigation.id
    new_laboratory_investigation[:investigationstage] = stage
    new_laboratory_investigation[:investigationname] = laboratory_investigation.investigationname
    new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
    new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigationfullcode
    new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
    new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
    new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type

    new_laboratory_investigation[:order_item_advised_id] = laboratory_investigation.order_item_advised_id.to_s

    new_laboratory_investigation[:user_id] = record.userid
    new_laboratory_investigation[:consultant_id] = record.consultant_id
    new_laboratory_investigation[:consultant_name] = record.consultant_name
    new_laboratory_investigation[:template_type] = record.templatetype

    new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by_id
    new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by
    new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_datetime
    new_laboratory_investigation[:entered_from] = 'opd_record'
    new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id
    new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility

    new_laboratory_investigation[:is_advised] = true
    new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by
    new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by_id
    new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_datetime
    new_laboratory_investigation[:advised_from] = 'opd_record'
    new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility
    new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id

    if laboratory_investigation.investigationstage == "P"
      new_laboratory_investigation[:is_performed] = true
      new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by_id
      new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by
      new_laboratory_investigation[:performed_datetime] = laboratory_investigation.performed_datetime
      new_laboratory_investigation[:performed_from] = 'opd_record'
      new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id
      new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility
      new_laboratory_investigation[:performed_comment] = laboratory_investigation.investigation_performed
    else
      new_laboratory_investigation[:is_performed] = false
      new_laboratory_investigation[:performed_by_id] = nil
      new_laboratory_investigation[:performed_by] = nil
      new_laboratory_investigation[:performed_at] = nil
      new_laboratory_investigation[:performed_from] = nil
      new_laboratory_investigation[:performed_at_facility_id] = nil
      new_laboratory_investigation[:performed_at_facility] = nil
      new_laboratory_investigation[:performed_comment] = nil
    end
  end

  def self.radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)
    if radiology_investigation.investigationstage == "A"
      stage = "Advised"
    elsif radiology_investigation.investigationstage == "P"
      stage = "Performed"
    end

    new_radiology_investigation[:record_id] = record.id.to_s
    new_radiology_investigation[:appointment_id] = record.appointmentid
    new_radiology_investigation[:opd_investigation_id] = radiology_investigation.id
    new_radiology_investigation[:investigationstage] = stage
    new_radiology_investigation[:investigationname] = radiology_investigation.investigationname
    new_radiology_investigation[:investigation_id] = radiology_investigation.investigation_id
    new_radiology_investigation[:investigationfullcode] = radiology_investigation.investigationfullcode
    new_radiology_investigation[:is_spine] = radiology_investigation.is_spine
    new_radiology_investigation[:laterality] = radiology_investigation.laterality
    new_radiology_investigation[:haslaterality] = radiology_investigation.haslaterality
    new_radiology_investigation[:radiologyoptions] = radiology_investigation.radiologyoptions
    new_radiology_investigation[:investigation_type] = radiology_investigation.investigation_type

    new_radiology_investigation[:order_item_advised_id] = radiology_investigation.order_item_advised_id.to_s

    new_radiology_investigation[:user_id] = record.userid
    new_radiology_investigation[:consultant_id] = record.consultant_id
    new_radiology_investigation[:consultant_name] = record.consultant_name
    new_radiology_investigation[:template_type] = record.templatetype

    new_radiology_investigation[:entered_by_id] = radiology_investigation.entered_by_id
    new_radiology_investigation[:entered_by] = radiology_investigation.entered_by
    new_radiology_investigation[:entered_datetime] = radiology_investigation.entered_datetime
    new_radiology_investigation[:entered_from] = 'opd_record'
    new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id
    new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility

    new_radiology_investigation[:is_advised] = true
    new_radiology_investigation[:advised_by] = radiology_investigation.advised_by
    new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by_id
    new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_datetime
    new_radiology_investigation[:advised_from] = 'opd_record'
    new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility
    new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id

    if radiology_investigation.investigationstage == "P"
      new_radiology_investigation[:is_performed] = true
      new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by_id
      new_radiology_investigation[:performed_by] = radiology_investigation.performed_by
      new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_datetime
      new_radiology_investigation[:performed_from] = 'opd_record'
      new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id
      new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility
      new_radiology_investigation[:performed_comment] = radiology_investigation.investigation_performed
    else
      new_radiology_investigation[:is_performed] = false
      new_radiology_investigation[:performed_by_id] = nil
      new_radiology_investigation[:performed_by] = nil
      new_radiology_investigation[:performed_at] = nil
      new_radiology_investigation[:performed_from] = nil
      new_radiology_investigation[:performed_at_facility_id] = nil
      new_radiology_investigation[:performed_at_facility] = nil
      new_radiology_investigation[:performed_comment] = nil
    end
  end

  def self.analytics_before_params_opd_record(case_sheet_id)
    analytics_case_sheet = CaseSheet.find_by(id: case_sheet_id) # done intentionally, data was getting updated as of after save method
    if analytics_case_sheet
      @analytics_params["before_save_patient_age"] = analytics_case_sheet.patient_age
      @analytics_params["before_save_patient_gender"] = analytics_case_sheet.patient_gender
      @analytics_params["before_save_diagnosis"] = analytics_case_sheet.diagnoses.to_a
      @analytics_params["before_save_procedure"] = analytics_case_sheet.procedures.to_a
      @analytics_params["before_save_ophthal_investigations"] = analytics_case_sheet.ophthal_investigations.to_a
      @analytics_params["before_save_radiology_investigations"] = analytics_case_sheet.radiology_investigations.to_a
      @analytics_params["before_save_laboratory_investigations"] = analytics_case_sheet.laboratory_investigations.to_a
    else
      @analytics_params["before_save_patient_age"] = ""
      @analytics_params["before_save_patient_gender"] = ""
      @analytics_params["before_save_diagnosis"] = []
      @analytics_params["before_save_procedure"] = []
      @analytics_params["before_save_ophthal_investigations"] = []
      @analytics_params["before_save_radiology_investigations"] = []
      @analytics_params["before_save_laboratory_investigations"] = []
    end
  end

  def self.analytics_after_params_opd_record(case_sheet)
    patient = Patient.find_by(id: case_sheet.patient_id)

    options = {}
    options = options.merge(patient_gender: patient.gender) if case_sheet.patient_gender != patient.gender
    options = options.merge(patient_age: "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}") if (case_sheet.patient_age.present? && case_sheet.patient_age.split("/")[2] != patient.dob_year) || case_sheet.patient_age.nil?
    case_sheet.update(options)

    @analytics_params["data_from"] = "opd_record"
    @analytics_params["case_sheet_id"] = case_sheet.id
    @analytics_params["after_save_patient_age"] = case_sheet.patient_age
    @analytics_params["after_save_patient_gender"] = case_sheet.patient_gender
    @analytics_params["after_save_diagnosis"] = case_sheet.diagnoses
    @analytics_params["after_save_procedure"] = case_sheet.procedures
    @analytics_params["after_save_ophthal_investigations"] = case_sheet.ophthal_investigations
    @analytics_params["after_save_radiology_investigations"] = case_sheet.radiology_investigations
    @analytics_params["after_save_laboratory_investigations"] = case_sheet.laboratory_investigations
  end
end
