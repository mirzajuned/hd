class CaseSheet::CreateCounsellorRecordService
  def self.call(record)
    case_sheet = CaseSheet.find_by(id: record.case_sheet_id)
    if case_sheet.present? # CaseSheet Present

      @analytics_params = {}
      analytics_before_params_counsellor_record(case_sheet)

      # counsellor_record_id
      counsellor_record_ids = case_sheet.counsellor_record_ids
      counsellor_record_ids << record.id.to_s
      case_sheet[:counsellor_record_ids] = counsellor_record_ids.uniq
      case_sheet[:case_switchable_opd] = case_sheet.case_switchable_opd
      case_sheet[:case_switchable_opd][record.appointment_id.to_s] = Hash[case_switchable: false]

      counsellor_diagnoses = record.diagnoses
      counsellor_procedures = record.procedures
      counsellor_ophthal_investigations = record.ophthal_investigations
      counsellor_laboratory_investigations = record.laboratory_investigations
      counsellor_radiology_investigations = record.radiology_investigations

      # DIAGNOSIS
      # Add Diagnosis
      counsellor_diagnoses.each do |diagnosis|
        new_diagnosis = case_sheet.diagnoses.find_by(id: diagnosis.case_sheet_diagnosis_id.to_s)
        if new_diagnosis.present?
          new_diagnosis[:counsellor_diagnosis_ids] = new_diagnosis.counsellor_diagnosis_ids
          new_diagnosis[:counsellor_diagnosis_ids][record.id.to_s] = Hash[record_id: record.id.to_s, diagnosis_id: diagnosis.id.to_s]

          new_diagnosis.save
        else
          diagnosis.delete
        end
      end
      # DIAGNOSIS ENDS

      # PROCEDURES
      # Add Procedure
      counsellor_procedures.each do |procedure|
        case_sheet_procedure = case_sheet.procedures.find_by(id: procedure.case_sheet_procedure_id.to_s)
        if case_sheet_procedure.present?
          new_procedure = case_sheet_procedure
        else # from counsellor_record_new
          new_procedure = case_sheet.procedures.new
        end
        procedure_params(new_procedure, record, procedure)

        if new_procedure.save
          same_cs_procedures = case_sheet.procedures.where(procedurefullcode: new_procedure.procedurefullcode, procedureside: new_procedure.procedureside)
          same_cs_procedures.each do |same_procedure|
            same_new_procedure = same_procedure

            procedure_params(same_new_procedure, record, procedure)
            same_new_procedure.save
          end
        end
      end
      # PROCEDURES ENDS

      # OPHTHAL INVESTIGATION
      # Add Ophthal
      counsellor_ophthal_investigations.each do |ophthal_investigation|
        if ophthal_investigation.counsellor_options_disabled != true
          case_sheet_ophthal_investigation = case_sheet.ophthal_investigations.find_by(id: ophthal_investigation.case_sheet_ophthal_investigation_id.to_s)
          if case_sheet_ophthal_investigation.present?
            new_ophthal_investigation = case_sheet_ophthal_investigation
          else # from counsellor_record_new
            new_ophthal_investigation = case_sheet.ophthal_investigations.new
          end
          ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)

          new_ophthal_investigation.save
        end
      end
      # OPHTHAL INVESTIGATION ENDS

      # LABORATORY INVESTIGATION
      # Add Laboratory
      counsellor_laboratory_investigations.each do |laboratory_investigation|
        if laboratory_investigation.counsellor_options_disabled != true
          case_sheet_laboratory_investigation = case_sheet.laboratory_investigations.find_by(id: laboratory_investigation.case_sheet_laboratory_investigation_id.to_s)
          if case_sheet_laboratory_investigation.present?
            new_laboratory_investigation = case_sheet_laboratory_investigation
          else # from counsellor_record_new
            new_laboratory_investigation = case_sheet.laboratory_investigations.new
          end
          laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

          new_laboratory_investigation.save
        end
      end
      # LABORATORY INVESTIGATION ENDS

      # RADIOLOGY INVESTIGATION
      # Add Radiology
      counsellor_radiology_investigations.each do |radiology_investigation|
        if radiology_investigation.counsellor_options_disabled != true
          case_sheet_radiology_investigation = case_sheet.radiology_investigations.find_by(id: radiology_investigation.case_sheet_radiology_investigation_id.to_s)
          if case_sheet_radiology_investigation.present?
            new_radiology_investigation = case_sheet_radiology_investigation
          else # from counsellor_record_new
            new_radiology_investigation = case_sheet.radiology_investigations.new
          end
          radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

          new_radiology_investigation.save
        end
      end
      # RADIOLOGY INVESTIGATION ENDS

      # Patient Discussion
      case_sheet[:counsellor_patient_discussions] = case_sheet.counsellor_patient_discussions
      record.patient_discussions.each do |k, discussion|
        if k.to_s == record.id.to_s # So that old CounsellorRecord Data is not overwritten in CaseSheet
          case_sheet[:counsellor_patient_discussions][record.id.to_s] = Hash[record_id: record.id.to_s, note_date: discussion[:note_date], note: discussion[:note]]
        end
      end

      # Surgery Package
      case_sheet[:patient_surgery_packages] = case_sheet.patient_surgery_packages
      if record.patient_surgery_package.count > 0
        patient_package = record.patient_surgery_package

        surgery_package_hash = Hash[
                                  record_id: record.id.to_s,
                                  package_id: patient_package[:package_id],
                                  package_name: patient_package[:package_name],
                                  pricing_amount: patient_package[:pricing_amount],
                                  discount_amount: patient_package[:discount_amount],
                                  discount_percent: patient_package[:discount_percent],
                                  package_price: patient_package[:package_price],
                                  package_selection_date: Time.current.strftime('%H:%M %p %d/%m/%Y'),
                                  services: patient_package[:services]
                                ]

        case_sheet[:latest_surgery_package] = surgery_package_hash
        case_sheet[:patient_surgery_packages][record.id.to_s] = surgery_package_hash
      else
        case_sheet[:latest_surgery_package] = {}
        case_sheet[:patient_surgery_packages][record.id.to_s] = {}
      end

      if case_sheet.save
        unless case_sheet.case_id.present?
          case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', case_sheet.id.to_s, {organisation_id: record.organisation_id.to_s, facility_id: record.facility.id.to_s, region_id: record.facility.try(:region_master_id).to_s})
          case_sheet.update(case_id: case_id)
        end
        analytics_after_params_counsellor_record(case_sheet)
        Analytics::CreateService.call(@analytics_params.to_json, record.user_id.to_s, record.try(:facility).try(:id).to_s, "clinical_data")
      end

    end
  end

  private

  def self.procedure_params(new_procedure, record, procedure)
    new_procedure[:counsellor_procedure_ids] = new_procedure.counsellor_procedure_ids
    new_procedure[:counsellor_procedure_ids][record.id.to_s] = Hash[record_id: record.id.to_s, procedure_id: procedure.id.to_s]
    unless procedure.opd_procedure_id.present?
      new_procedure[:id] = procedure.case_sheet_procedure_id
      new_procedure[:record_id] = record.id.to_s
      new_procedure[:appointment_id] = record.appointment_id.to_s
      new_procedure[:procedurestage] = "Advised"
      new_procedure[:procedurename] = procedure.procedurename
      new_procedure[:procedure_id] = procedure.procedure_id
      new_procedure[:procedureside] = procedure.procedureside
      new_procedure[:procedurefullcode] = procedure.procedurefullcode
      new_procedure[:procedure_type] = procedure.procedure_type
      new_procedure[:procedure_comment] = procedure.procedure_comment
      new_procedure[:users_comment] = procedure.users_comment

      new_procedure[:entered_by_id] = procedure.entered_by_id
      new_procedure[:entered_by] = procedure.entered_by
      new_procedure[:entered_datetime] = procedure.entered_datetime
      new_procedure[:entered_from] = 'counsellor_record'
      new_procedure[:entered_at_facility_id] = procedure.entered_at_facility_id
      new_procedure[:entered_at_facility] = procedure.entered_at_facility

      new_procedure[:is_advised] = true
      new_procedure[:advised_by_id] = procedure.advised_by_id
      new_procedure[:advised_by] = procedure.advised_by
      new_procedure[:advised_datetime] = procedure.advised_datetime
      new_procedure[:advised_from] = 'counsellor_record'
      new_procedure[:advised_at_facility_id] = procedure.advised_at_facility_id
      new_procedure[:advised_at_facility] = procedure.advised_at_facility

      if procedure.procedurestage == "P" || procedure.procedurestage == "Performed"
        new_procedure[:is_performed] = true
        new_procedure[:performed_by_id] = procedure.performed_by_id
        new_procedure[:performed_by] = procedure.performed_by
        new_procedure[:performed_datetime] = procedure.performed_datetime
        new_procedure[:performed_from] = 'counsellor_record'
        new_procedure[:performed_at_facility_id] = procedure.performed_at_facility_id
        new_procedure[:performed_at_facility] = procedure.performed_at_facility
        new_procedure[:performed_comment] = procedure.performed_comment
      else
        new_procedure[:is_performed] = false
        new_procedure[:performed_by_id] = nil
        new_procedure[:performed_by] = nil
        new_procedure[:performed_datetime] = nil
        new_procedure[:performed_from] = nil
        new_procedure[:performed_at_facility_id] = nil
        new_procedure[:performed_at_facility] = nil
        new_procedure[:performed_comment] = nil
      end
    end

    new_procedure[:iol_present] = procedure.iol_present
    if procedure.iol_present
      new_procedure[:iol_agreed] = procedure.iol_agreed
      new_procedure[:iol_power] = procedure.iol_power
    end

    new_procedure[:is_counselled] = procedure.is_counselled
    if procedure.is_counselled
      new_procedure[:procedurestage] = "Counselled"
      new_procedure[:counselled_by_id] = procedure.counselled_by_id
      new_procedure[:counselled_by] = procedure.counselled_by
      new_procedure[:counselled_datetime] = procedure.counselled_datetime
      new_procedure[:counselled_from] = 'counsellor_record'
      new_procedure[:counselled_at_facility_id] = procedure.counselled_at_facility_id
      new_procedure[:counselled_at_facility] = procedure.counselled_at_facility
    end

    new_procedure[:has_agreed] = procedure.has_agreed
    if procedure.has_agreed
      new_procedure[:procedurestage] = "Agreed"
      new_procedure[:agreed_by_id] = procedure.agreed_by_id
      new_procedure[:agreed_by] = procedure.agreed_by
      new_procedure[:agreed_datetime] = procedure.agreed_datetime
      new_procedure[:agreed_from] = 'counsellor_record'
      new_procedure[:agreed_at_facility_id] = procedure.agreed_at_facility_id
      new_procedure[:agreed_at_facility] = procedure.agreed_at_facility
    end

    new_procedure[:payment_taken] = procedure.payment_taken
    if procedure.payment_taken
      new_procedure[:procedurestage] = "Payment Taken"
      new_procedure[:payment_taken_by_id] = procedure.payment_taken_by_id
      new_procedure[:payment_taken_by] = procedure.payment_taken_by
      new_procedure[:payment_taken_datetime] = procedure.payment_taken_datetime
      new_procedure[:payment_taken_from] = 'counsellor_record'
      new_procedure[:payment_taken_at_facility_id] = procedure.payment_taken_at_facility_id
      new_procedure[:payment_taken_at_facility] = procedure.payment_taken_at_facility
    end

    new_procedure[:has_declined] = procedure.has_declined
    if procedure.has_declined
      new_procedure[:procedurestage] = "Declined"
      new_procedure[:declined_by_id] = procedure.declined_by_id
      new_procedure[:declined_by] = procedure.declined_by
      new_procedure[:declined_datetime] = procedure.declined_datetime
      new_procedure[:declined_from] = 'counsellor_record'
      new_procedure[:declined_at_facility_id] = procedure.declined_at_facility_id
      new_procedure[:declined_at_facility] = procedure.declined_at_facility
    end

    new_procedure[:is_removed] = procedure.is_removed
    if procedure.is_removed
      new_procedure[:procedurestage] = "Removed"
      new_procedure[:removed_by_id] = procedure.removed_by_id
      new_procedure[:removed_by] = procedure.removed_by
      new_procedure[:removed_datetime] = procedure.removed_datetime
      new_procedure[:removed_from] = 'counsellor_record'
      new_procedure[:removed_at_facility_id] = procedure.removed_at_facility_id
      new_procedure[:removed_at_facility] = procedure.removed_at_facility
    end
  end

  def self.ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)
    new_ophthal_investigation[:counsellor_investigation_ids] = new_ophthal_investigation.counsellor_investigation_ids
    new_ophthal_investigation[:counsellor_investigation_ids][record.id.to_s] = Hash[record_id: record.id.to_s, investigation_id: ophthal_investigation.id.to_s]
    new_ophthal_investigation[:detail_investigation_id] = ophthal_investigation.detail_investigation_id
    new_ophthal_investigation[:counsellor_options_disabled] = false
    unless ophthal_investigation.opd_investigation_id.present?
      new_ophthal_investigation[:id] = ophthal_investigation.case_sheet_ophthal_investigation_id
      new_ophthal_investigation[:record_id] = record.id.to_s
      new_ophthal_investigation[:appointment_id] = record.appointment_id.to_s
      new_ophthal_investigation[:investigationstage] = "Advised"
      new_ophthal_investigation[:investigationname] = ophthal_investigation.investigationname
      new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
      new_ophthal_investigation[:investigationoriginalside] = ophthal_investigation.investigationside
      new_ophthal_investigation[:investigationside] = ophthal_investigation.investigationside
      new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigationfullcode
      new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type

      new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by_id
      new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by
      new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_datetime
      new_ophthal_investigation[:entered_from] = 'counsellor_record'
      new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id
      new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility

      new_ophthal_investigation[:is_advised] = true
      new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by_id
      new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by
      new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_datetime
      new_ophthal_investigation[:advised_from] = 'counsellor_record'
      new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id
      new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility

      if ophthal_investigation.investigationstage == "P"
        new_ophthal_investigation[:is_performed] = true
        new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by_id
        new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by
        new_ophthal_investigation[:performed_datetime] = ophthal_investigation.performed_datetime
        new_ophthal_investigation[:performed_from] = 'counsellor_record'
        new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id
        new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility
        new_ophthal_investigation[:performed_comment] = ophthal_investigation.performed_comment
      elsif ophthal_investigation.performed_by_id.present?
        new_ophthal_investigation[:is_performed] = false
        new_ophthal_investigation[:performed_by_id] = nil
        new_ophthal_investigation[:performed_by] = nil
        new_ophthal_investigation[:performed_datetime] = nil
        new_ophthal_investigation[:performed_from] = nil
        new_ophthal_investigation[:performed_at_facility_id] = nil
        new_ophthal_investigation[:performed_at_facility] = nil
        new_ophthal_investigation[:performed_comment] = nil
      end
    end

    new_ophthal_investigation[:iol_present] = ophthal_investigation.iol_present
    if ophthal_investigation.iol_present
      new_ophthal_investigation[:iol_agreed] = ophthal_investigation.iol_agreed
      new_ophthal_investigation[:iol_power] = ophthal_investigation.iol_power
    end

    new_ophthal_investigation[:is_counselled] = ophthal_investigation.is_counselled
    if ophthal_investigation.is_counselled
      new_ophthal_investigation[:investigationstage] = "Counselled"
      new_ophthal_investigation[:counselled_by_id] = ophthal_investigation.counselled_by_id
      new_ophthal_investigation[:counselled_by] = ophthal_investigation.counselled_by
      new_ophthal_investigation[:counselled_datetime] = ophthal_investigation.counselled_datetime
      new_ophthal_investigation[:counselled_from] = 'counsellor_record'
      new_ophthal_investigation[:counselled_at_facility_id] = ophthal_investigation.counselled_at_facility_id
      new_ophthal_investigation[:counselled_at_facility] = ophthal_investigation.counselled_at_facility
    end

    new_ophthal_investigation[:has_agreed] = ophthal_investigation.has_agreed
    if ophthal_investigation.has_agreed
      new_ophthal_investigation[:investigationstage] = "Agreed"
      new_ophthal_investigation[:agreed_by_id] = ophthal_investigation.agreed_by_id
      new_ophthal_investigation[:agreed_by] = ophthal_investigation.agreed_by
      new_ophthal_investigation[:agreed_datetime] = ophthal_investigation.agreed_datetime
      new_ophthal_investigation[:agreed_from] = 'counsellor_record'
      new_ophthal_investigation[:agreed_at_facility_id] = ophthal_investigation.agreed_at_facility_id
      new_ophthal_investigation[:agreed_at_facility] = ophthal_investigation.agreed_at_facility
    end

    new_ophthal_investigation[:payment_taken] = ophthal_investigation.payment_taken
    if ophthal_investigation.payment_taken
      new_ophthal_investigation[:investigationstage] = "Payment Taken"
      new_ophthal_investigation[:payment_taken_by_id] = ophthal_investigation.payment_taken_by_id
      new_ophthal_investigation[:payment_taken_by] = ophthal_investigation.payment_taken_by
      new_ophthal_investigation[:payment_taken_datetime] = ophthal_investigation.payment_taken_datetime
      new_ophthal_investigation[:payment_taken_from] = 'counsellor_record'
      new_ophthal_investigation[:payment_taken_at_facility_id] = ophthal_investigation.payment_taken_at_facility_id
      new_ophthal_investigation[:payment_taken_at_facility] = ophthal_investigation.payment_taken_at_facility
    end

    new_ophthal_investigation[:has_declined] = ophthal_investigation.has_declined
    if ophthal_investigation.has_declined
      new_ophthal_investigation[:investigationstage] = "Declined"
      new_ophthal_investigation[:declined_by_id] = ophthal_investigation.declined_by_id
      new_ophthal_investigation[:declined_by] = ophthal_investigation.declined_by
      new_ophthal_investigation[:declined_datetime] = ophthal_investigation.declined_datetime
      new_ophthal_investigation[:declined_from] = 'counsellor_record'
      new_ophthal_investigation[:declined_at_facility_id] = ophthal_investigation.declined_at_facility_id
      new_ophthal_investigation[:declined_at_facility] = ophthal_investigation.declined_at_facility
    end

    new_ophthal_investigation[:is_removed] = ophthal_investigation.is_removed
    if ophthal_investigation.is_removed
      new_ophthal_investigation[:investigationstage] = "Removed"
      new_ophthal_investigation[:removed_by_id] = ophthal_investigation.removed_by_id
      new_ophthal_investigation[:removed_by] = ophthal_investigation.removed_by
      new_ophthal_investigation[:removed_datetime] = ophthal_investigation.removed_datetime
      new_ophthal_investigation[:removed_from] = 'counsellor_record'
      new_ophthal_investigation[:removed_at_facility_id] = ophthal_investigation.removed_at_facility_id
      new_ophthal_investigation[:removed_at_facility] = ophthal_investigation.removed_at_facility
    end
  end

  def self.laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)
    new_laboratory_investigation[:counsellor_investigation_ids] = new_laboratory_investigation.counsellor_investigation_ids
    new_laboratory_investigation[:counsellor_investigation_ids][record.id.to_s] = Hash[record_id: record.id.to_s, investigation_id: laboratory_investigation.id.to_s]
    new_laboratory_investigation[:detail_investigation_id] = laboratory_investigation.detail_investigation_id
    new_laboratory_investigation[:counsellor_options_disabled] = false
    unless laboratory_investigation.opd_investigation_id.present?
      new_laboratory_investigation[:id] = laboratory_investigation.case_sheet_laboratory_investigation_id
      new_laboratory_investigation[:record_id] = record.id.to_s
      new_laboratory_investigation[:appointment_id] = record.appointment_id.to_s
      new_laboratory_investigation[:investigationstage] = "Advised"
      new_laboratory_investigation[:investigationname] = laboratory_investigation.investigationname
      new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
      new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigationfullcode
      new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
      new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
      new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type

      new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by_id
      new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by
      new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_datetime
      new_laboratory_investigation[:entered_from] = 'counsellor_record'
      new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id
      new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility

      new_laboratory_investigation[:is_advised] = true
      new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by_id
      new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by
      new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_datetime
      new_laboratory_investigation[:advised_from] = 'counsellor_record'
      new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id
      new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility

      if laboratory_investigation.investigationstage == "P"
        new_laboratory_investigation[:is_performed] = true
        new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by_id
        new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by
        new_laboratory_investigation[:performed_datetime] = laboratory_investigation.performed_datetime
        new_laboratory_investigation[:performed_from] = 'counsellor_record'
        new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id
        new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility
        new_laboratory_investigation[:performed_comment] = laboratory_investigation.performed_comment
      elsif laboratory_investigation.performed_by_id.present?
        new_laboratory_investigation[:is_performed] = false
        new_laboratory_investigation[:performed_by_id] = nil
        new_laboratory_investigation[:performed_by] = nil
        new_laboratory_investigation[:performed_datetime] = nil
        new_laboratory_investigation[:performed_from] = nil
        new_laboratory_investigation[:performed_at_facility_id] = nil
        new_laboratory_investigation[:performed_at_facility] = nil
        new_laboratory_investigation[:performed_comment] = nil
      end
    end

    new_laboratory_investigation[:iol_present] = laboratory_investigation.iol_present
    if laboratory_investigation.iol_present
      new_laboratory_investigation[:iol_agreed] = laboratory_investigation.iol_agreed
      new_laboratory_investigation[:iol_power] = laboratory_investigation.iol_power
    end

    new_laboratory_investigation[:is_counselled] = laboratory_investigation.is_counselled
    if laboratory_investigation.is_counselled
      new_laboratory_investigation[:investigationstage] = "Counselled"
      new_laboratory_investigation[:counselled_by_id] = laboratory_investigation.counselled_by_id
      new_laboratory_investigation[:counselled_by] = laboratory_investigation.counselled_by
      new_laboratory_investigation[:counselled_datetime] = laboratory_investigation.counselled_datetime
      new_laboratory_investigation[:counselled_from] = 'counsellor_record'
      new_laboratory_investigation[:counselled_at_facility_id] = laboratory_investigation.counselled_at_facility_id
      new_laboratory_investigation[:counselled_at_facility] = laboratory_investigation.counselled_at_facility
    end

    new_laboratory_investigation[:has_agreed] = laboratory_investigation.has_agreed
    if laboratory_investigation.has_agreed
      new_laboratory_investigation[:investigationstage] = "Agreed"
      new_laboratory_investigation[:agreed_by_id] = laboratory_investigation.agreed_by_id
      new_laboratory_investigation[:agreed_by] = laboratory_investigation.agreed_by
      new_laboratory_investigation[:agreed_datetime] = laboratory_investigation.agreed_datetime
      new_laboratory_investigation[:agreed_from] = 'counsellor_record'
      new_laboratory_investigation[:agreed_at_facility_id] = laboratory_investigation.agreed_at_facility_id
      new_laboratory_investigation[:agreed_at_facility] = laboratory_investigation.agreed_at_facility
    end

    new_laboratory_investigation[:payment_taken] = laboratory_investigation.payment_taken
    if laboratory_investigation.payment_taken
      new_laboratory_investigation[:investigationstage] = "Payment Taken"
      new_laboratory_investigation[:payment_taken_by_id] = laboratory_investigation.payment_taken_by_id
      new_laboratory_investigation[:payment_taken_by] = laboratory_investigation.payment_taken_by
      new_laboratory_investigation[:payment_taken_datetime] = laboratory_investigation.payment_taken_datetime
      new_laboratory_investigation[:payment_taken_from] = 'counsellor_record'
      new_laboratory_investigation[:payment_taken_at_facility_id] = laboratory_investigation.payment_taken_at_facility_id
      new_laboratory_investigation[:payment_taken_at_facility] = laboratory_investigation.payment_taken_at_facility
    end

    new_laboratory_investigation[:has_declined] = laboratory_investigation.has_declined
    if laboratory_investigation.has_declined
      new_laboratory_investigation[:investigationstage] = "Declined"
      new_laboratory_investigation[:declined_by_id] = laboratory_investigation.declined_by_id
      new_laboratory_investigation[:declined_by] = laboratory_investigation.declined_by
      new_laboratory_investigation[:declined_datetime] = laboratory_investigation.declined_datetime
      new_laboratory_investigation[:declined_from] = 'counsellor_record'
      new_laboratory_investigation[:declined_at_facility_id] = laboratory_investigation.declined_at_facility_id
      new_laboratory_investigation[:declined_at_facility] = laboratory_investigation.declined_at_facility
    end

    new_laboratory_investigation[:is_removed] = laboratory_investigation.is_removed
    if laboratory_investigation.is_removed
      new_laboratory_investigation[:investigationstage] = "Removed"
      new_laboratory_investigation[:removed_by_id] = laboratory_investigation.removed_by_id
      new_laboratory_investigation[:removed_by] = laboratory_investigation.removed_by
      new_laboratory_investigation[:removed_datetime] = laboratory_investigation.removed_datetime
      new_laboratory_investigation[:removed_from] = 'counsellor_record'
      new_laboratory_investigation[:removed_at_facility_id] = laboratory_investigation.removed_at_facility_id
      new_laboratory_investigation[:removed_at_facility] = laboratory_investigation.removed_at_facility
    end
  end

  def self.radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)
    new_radiology_investigation[:counsellor_investigation_ids] = new_radiology_investigation.counsellor_investigation_ids
    new_radiology_investigation[:counsellor_investigation_ids][record.id.to_s] = Hash[record_id: record.id.to_s, investigation_id: radiology_investigation.id.to_s]
    new_radiology_investigation[:detail_investigation_id] = radiology_investigation.detail_investigation_id
    new_radiology_investigation[:counsellor_options_disabled] = false
    unless radiology_investigation.opd_investigation_id.present?
      new_radiology_investigation[:id] = radiology_investigation.case_sheet_radiology_investigation_id
      new_radiology_investigation[:record_id] = record.id.to_s
      new_radiology_investigation[:appointment_id] = record.appointment_id.to_s
      new_radiology_investigation[:investigationstage] = "Advised"
      new_radiology_investigation[:investigationname] = radiology_investigation.investigationname
      new_radiology_investigation[:investigation_id] = radiology_investigation.investigation_id
      new_radiology_investigation[:investigationfullcode] = radiology_investigation.investigationfullcode
      new_radiology_investigation[:is_spine] = radiology_investigation.is_spine
      new_radiology_investigation[:laterality] = radiology_investigation.laterality
      new_radiology_investigation[:haslaterality] = radiology_investigation.haslaterality
      new_radiology_investigation[:radiologyoptions] = radiology_investigation.radiologyoptions
      new_radiology_investigation[:investigation_type] = radiology_investigation.investigation_type

      new_radiology_investigation[:entered_by_id] = radiology_investigation.entered_by_id
      new_radiology_investigation[:entered_by] = radiology_investigation.entered_by
      new_radiology_investigation[:entered_datetime] = radiology_investigation.entered_datetime
      new_radiology_investigation[:entered_from] = 'counsellor_record'
      new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id
      new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility

      new_radiology_investigation[:is_advised] = true
      new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by_id
      new_radiology_investigation[:advised_by] = radiology_investigation.advised_by
      new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_datetime
      new_radiology_investigation[:advised_from] = 'counsellor_record'
      new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id
      new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility

      if radiology_investigation.investigationstage == "P"
        new_radiology_investigation[:is_performed] = true
        new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by_id
        new_radiology_investigation[:performed_by] = radiology_investigation.performed_by
        new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_datetime
        new_radiology_investigation[:performed_from] = 'counsellor_record'
        new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id
        new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility
        new_radiology_investigation[:performed_comment] = radiology_investigation.performed_comment
      elsif radiology_investigation.performed_by_id.present?
        new_radiology_investigation[:is_performed] = false
        new_radiology_investigation[:performed_by_id] = nil
        new_radiology_investigation[:performed_by] = nil
        new_radiology_investigation[:performed_datetime] = nil
        new_radiology_investigation[:performed_from] = nil
        new_radiology_investigation[:performed_at_facility_id] = nil
        new_radiology_investigation[:performed_at_facility] = nil
        new_radiology_investigation[:performed_comment] = nil
      end
    end

    new_radiology_investigation[:iol_present] = radiology_investigation.iol_present
    if radiology_investigation.iol_present
      new_radiology_investigation[:iol_agreed] = radiology_investigation.iol_agreed
      new_radiology_investigation[:iol_power] = radiology_investigation.iol_power
    end

    new_radiology_investigation[:is_counselled] = radiology_investigation.is_counselled
    if radiology_investigation.is_counselled
      new_radiology_investigation[:investigationstage] = "Counselled"
      new_radiology_investigation[:counselled_by_id] = radiology_investigation.counselled_by_id
      new_radiology_investigation[:counselled_by] = radiology_investigation.counselled_by
      new_radiology_investigation[:counselled_datetime] = radiology_investigation.counselled_datetime
      new_radiology_investigation[:counselled_from] = 'counsellor_record'
      new_radiology_investigation[:counselled_at_facility_id] = radiology_investigation.counselled_at_facility_id
      new_radiology_investigation[:counselled_at_facility] = radiology_investigation.counselled_at_facility
    end

    new_radiology_investigation[:has_agreed] = radiology_investigation.has_agreed
    if radiology_investigation.has_agreed
      new_radiology_investigation[:investigationstage] = "Agreed"
      new_radiology_investigation[:agreed_by_id] = radiology_investigation.agreed_by_id
      new_radiology_investigation[:agreed_by] = radiology_investigation.agreed_by
      new_radiology_investigation[:agreed_datetime] = radiology_investigation.agreed_datetime
      new_radiology_investigation[:agreed_from] = 'counsellor_record'
      new_radiology_investigation[:agreed_at_facility_id] = radiology_investigation.agreed_at_facility_id
      new_radiology_investigation[:agreed_at_facility] = radiology_investigation.agreed_at_facility
    end

    new_radiology_investigation[:payment_taken] = radiology_investigation.payment_taken
    if radiology_investigation.payment_taken
      new_radiology_investigation[:investigationstage] = "Payment Taken"
      new_radiology_investigation[:payment_taken_by_id] = radiology_investigation.payment_taken_by_id
      new_radiology_investigation[:payment_taken_by] = radiology_investigation.payment_taken_by
      new_radiology_investigation[:payment_taken_datetime] = radiology_investigation.payment_taken_datetime
      new_radiology_investigation[:payment_taken_from] = 'counsellor_record'
      new_radiology_investigation[:payment_taken_at_facility_id] = radiology_investigation.payment_taken_at_facility_id
      new_radiology_investigation[:payment_taken_at_facility] = radiology_investigation.payment_taken_at_facility
    end

    new_radiology_investigation[:has_declined] = radiology_investigation.has_declined
    if radiology_investigation.has_declined
      new_radiology_investigation[:investigationstage] = "Declined"
      new_radiology_investigation[:declined_by_id] = radiology_investigation.declined_by_id
      new_radiology_investigation[:declined_by] = radiology_investigation.declined_by
      new_radiology_investigation[:declined_datetime] = radiology_investigation.declined_datetime
      new_radiology_investigation[:declined_from] = 'counsellor_record'
      new_radiology_investigation[:declined_at_facility_id] = radiology_investigation.declined_at_facility_id
      new_radiology_investigation[:declined_at_facility] = radiology_investigation.declined_at_facility
    end

    new_radiology_investigation[:is_removed] = radiology_investigation.is_removed
    if radiology_investigation.is_removed
      new_radiology_investigation[:investigationstage] = "Removed"
      new_radiology_investigation[:removed_by_id] = radiology_investigation.removed_by_id
      new_radiology_investigation[:removed_by] = radiology_investigation.removed_by
      new_radiology_investigation[:removed_datetime] = radiology_investigation.removed_datetime
      new_radiology_investigation[:removed_from] = 'counsellor_record'
      new_radiology_investigation[:removed_at_facility_id] = radiology_investigation.removed_at_facility_id
      new_radiology_investigation[:removed_at_facility] = radiology_investigation.removed_at_facility
    end
  end

  def self.analytics_before_params_counsellor_record(case_sheet)
    analytics_case_sheet = CaseSheet.find_by(id: case_sheet.id) # done intentionally, data was getting updated as of after save method

    @analytics_params["before_save_patient_age"] = analytics_case_sheet.patient_age
    @analytics_params["before_save_patient_gender"] = analytics_case_sheet.patient_gender
    @analytics_params["before_save_diagnosis"] = analytics_case_sheet.diagnoses.to_a
    @analytics_params["before_save_procedure"] = analytics_case_sheet.procedures.to_a
    @analytics_params["before_save_ophthal_investigations"] = analytics_case_sheet.ophthal_investigations.to_a
    @analytics_params["before_save_radiology_investigations"] = analytics_case_sheet.radiology_investigations.to_a
    @analytics_params["before_save_laboratory_investigations"] = analytics_case_sheet.laboratory_investigations.to_a
  end

  def self.analytics_after_params_counsellor_record(case_sheet)
    patient = Patient.find_by(id: case_sheet.patient_id)

    options = {}
    options = options.merge(patient_gender: patient.gender) if case_sheet.patient_gender != patient.gender
    options = options.merge(patient_age: "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}") if (case_sheet.patient_age.present? && case_sheet.patient_age.split("/")[2] != patient.dob_year) || case_sheet.patient_age.nil?
    case_sheet.update(options)

    @analytics_params["data_from"] = "counsellor_record"
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
