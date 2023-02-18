class IpdRecords::CreateService
  def self.call(admission, case_sheet_params, location)
    ipd_record = Inpatient::IpdRecord.find_by(admission_id: admission.id.to_s) || Inpatient::IpdRecord.new

    case_sheet = CaseSheet.find_by(id: admission.case_sheet_id)

    @doctor = User.find_by(id: admission.doctor)
    @admission_facility = Facility.find_by(id: admission.facility_id)
    @admission_organisation = @admission_facility.organisation_id
    @department = Department.find_by(id: admission.department_id)

    ipd_record_diagnoses = ipd_record.diagnosislist
    ipd_record_procedures = ipd_record.procedure
    ipd_record_complications = ipd_record.complications
    ipd_record_ophthal_investigations = ipd_record.ophthal_investigations_list
    ipd_record_laboratory_investigations = ipd_record.laboratory_investigations_list
    ipd_record_radiology_investigations = ipd_record.radiology_investigations_list

    case_sheet_diagnoses = case_sheet.diagnoses
    case_sheet_procedures = case_sheet.procedures
    case_sheet_complications = case_sheet.complications
    case_sheet_ophthal_investigations = case_sheet.ophthal_investigations
    case_sheet_laboratory_investigations = case_sheet.laboratory_investigations
    case_sheet_radiology_investigations = case_sheet.radiology_investigations

    if ipd_record.admission_id.present?
      case_sheet_diagnoses = case_sheet_diagnoses.where(ipd_record_id: ipd_record.id)
      case_sheet_procedures = case_sheet_procedures.where(ipd_record_id: ipd_record.id)
      case_sheet_complications = case_sheet_complications.where(ipd_record_id: ipd_record.id)
      case_sheet_ophthal_investigations = case_sheet_ophthal_investigations.where(ipd_record_id: ipd_record.id)
      case_sheet_laboratory_investigations = case_sheet_laboratory_investigations.where(ipd_record_id: ipd_record.id)
      case_sheet_radiology_investigations = case_sheet_radiology_investigations.where(ipd_record_id: ipd_record.id)
    end

    case_sheet_diagnosis_ids = case_sheet_diagnoses.where(ipd_record_id: ipd_record.id).pluck(:id).map(&:to_s)
    case_sheet_procedure_ids = case_sheet_procedures.where(ipd_record_id: ipd_record.id).pluck(:id).map(&:to_s)
    case_sheet_complication_ids = case_sheet_complications.where(ipd_record_id: ipd_record.id).pluck(:id).map(&:to_s)

    ipd_record[:patient_id] = admission.patient_id
    ipd_record[:admission_id] = admission.id
    ipd_record[:doctor_id] = admission.doctor
    ipd_record[:organisation_id] = @admission_organisation
    ipd_record[:facility_id] = admission.facility_id
    ipd_record[:case_sheet_id] = admission.case_sheet_id
    ipd_record[:department_id] = admission.department_id
    ipd_record[:department] = @department.name
    ipd_record[:specialty_id] = admission.specialty_id
    ipd_record[:admissiondate] = admission.admissiondate || Date.current
    ipd_record[:admissiontime] = admission.admissiontime || Time.current
    ipd_record[:admissionreason] = admission.admissionreason
    ipd_record[:management_plan] = admission.managementplan
    ipd_record[:discharge_date] = admission.dischargedate
    ipd_record[:is_deleted] = false
    ipd_record[:_type] = nil
    if ipd_record.clinical_note.present?
      ipd_record[:clinical_data_present] = true
    end

    if case_sheet.present? && case_sheet_params.present?
      # Destroy Removed Diagnosis before creating new so new doesnt get destroyed
      if case_sheet_params[:diagnoses].present?
        clinical_diagnosis_ids = case_sheet_params[:diagnoses].to_unsafe_h.select { |k, v| v if (v[:flow_in_ipd] == "true") }.map { |k, v| v[:id] }
      else
        clinical_diagnosis_ids = []
      end
      diagnosis_ids = []
      ipd_record_diagnoses.each do |diagnosis|
        unless clinical_diagnosis_ids.include?(diagnosis.case_sheet_diagnosis_id.to_s)
          diagnosis_ids << diagnosis.id.to_s
        end
      end
      ipd_record_diagnoses.where(:id.in => diagnosis_ids).delete_all

      if case_sheet_diagnoses.count > 0
        case_sheet_diagnoses.where(flow_in_ipd: true).each do |diagnosis|
          ipd_diagnosis = ipd_record_diagnoses.find_by(case_sheet_diagnosis_id: diagnosis.id.to_s)
          if ipd_diagnosis.present?
            new_diagnosis = ipd_diagnosis
          else
            new_diagnosis = ipd_record.diagnosislist.new
          end
          if new_diagnosis.present?
            diagnosis_params(new_diagnosis, diagnosis)

            if new_diagnosis.save
              # Update IPD fields in Diagnosis
              diagnosis[:ipd_diagnosis_ids] = diagnosis.ipd_diagnosis_ids
              diagnosis[:ipd_diagnosis_ids][ipd_record.id.to_s] = Hash[record_id: ipd_record.id.to_s, diagnosis_id: new_diagnosis.id.to_s]
              diagnosis[:ipd_record_id] = ipd_record.id

              diagnosis.save
            end
          end
        end
      end

      # Destroy Removed Diagnosis before creating new so new doesnt get destroyed
      if case_sheet_params[:procedures].present?
        clinical_procedure_ids = case_sheet_params[:procedures].to_unsafe_h.select { |k, v| v if (v[:flow_in_ipd] == "true") }.map { |k, v| v[:id] }
      else
        clinical_procedure_ids = []
      end
      procedure_ids = []
      ipd_record_procedures.each do |procedure|
        unless clinical_procedure_ids.include?(procedure.case_sheet_procedure_id.to_s)
          procedure_ids << procedure.id.to_s
        end
      end
      ipd_record_procedures.where(:id.in => procedure_ids).delete_all

      if case_sheet_procedures.count > 0
        case_sheet_procedures.or({ ipd_record_id: nil }, { ipd_record_id: ipd_record.id }).where(flow_in_ipd: true).each do |procedure|
          ipd_procedure = ipd_record_procedures.find_by(case_sheet_procedure_id: procedure.id.to_s)
          if ipd_procedure.present?
            new_procedure = ipd_procedure
          else
            new_procedure = ipd_record.procedure.new
          end
          if new_procedure.present?
            procedure_params(new_procedure, procedure)

            if new_procedure.save
              # Update IPD fields in Procedure
              procedure[:ipd_procedure_ids] = procedure.ipd_procedure_ids
              procedure[:ipd_procedure_ids][ipd_record.id.to_s] = Hash[record_id: ipd_record.id.to_s, procedure_id: new_procedure.id.to_s]
              procedure[:ipd_record_id] = ipd_record.id
              procedure[:is_performed] = procedure.performed_datetime.nil? ? false : true

              procedure.save
            end
          end
        end
      end

      if case_sheet_ophthal_investigations.count > 0
        case_sheet_ophthal_investigations.each do |ophthal_investigation|
          ipd_ophthal_investigation = ipd_record_ophthal_investigations.find_by(case_sheet_investigation_id: ophthal_investigation.id.to_s)
          if ipd_ophthal_investigation.present?
            new_ophthal_investigation = ipd_ophthal_investigation
          else
            new_ophthal_investigation = ipd_record.ophthal_investigations_list.new
          end
          if new_ophthal_investigation.present?
            ophthal_investigation_params(new_ophthal_investigation, ophthal_investigation)

            if new_ophthal_investigation.save
              # Update IPD fields in Investigation
              ophthal_investigation[:ipd_investigation_ids] = ophthal_investigation.ipd_investigation_ids
              ophthal_investigation[:ipd_investigation_ids][ipd_record.id.to_s] = Hash[record_id: ipd_record.id.to_s, investigation_id: new_ophthal_investigation.id.to_s]
              ophthal_investigation[:ipd_record_id] = ipd_record.id

              ophthal_investigation.save
            end
          end
        end
      end

      if case_sheet_laboratory_investigations.count > 0
        case_sheet_laboratory_investigations.each do |laboratory_investigation|
          ipd_laboratory_investigation = ipd_record_laboratory_investigations.find_by(case_sheet_investigation_id: laboratory_investigation.id.to_s)
          if ipd_laboratory_investigation.present?
            new_laboratory_investigation = ipd_laboratory_investigation
          else
            new_laboratory_investigation = ipd_record.laboratory_investigations_list.new
          end
          if new_laboratory_investigation.present?
            laboratory_investigation_params(new_laboratory_investigation, laboratory_investigation)

            if new_laboratory_investigation.save
              # Update IPD fields in Investigation
              laboratory_investigation[:ipd_investigation_ids] = laboratory_investigation.ipd_investigation_ids
              laboratory_investigation[:ipd_investigation_ids][ipd_record.id.to_s] = Hash[record_id: ipd_record.id.to_s, investigation_id: new_laboratory_investigation.id.to_s]
              laboratory_investigation[:ipd_record_id] = ipd_record.id

              laboratory_investigation.save
            end
          end
        end
      end

      if case_sheet_radiology_investigations.count > 0
        case_sheet_radiology_investigations.each do |radiology_investigation|
          ipd_radiology_investigation = ipd_record_radiology_investigations.find_by(case_sheet_investigation_id: radiology_investigation.id.to_s)
          if ipd_radiology_investigation.present?
            new_radiology_investigation = ipd_radiology_investigation
          else
            new_radiology_investigation = ipd_record.radiology_investigations_list.new
          end
          if new_radiology_investigation.present?
            radiology_investigation_params(new_radiology_investigation, radiology_investigation)

            if new_radiology_investigation.save
              # Update IPD fields in Investigation
              radiology_investigation[:ipd_investigation_ids] = radiology_investigation.ipd_investigation_ids
              radiology_investigation[:ipd_investigation_ids][ipd_record.id.to_s] = Hash[record_id: ipd_record.id.to_s, investigation_id: new_radiology_investigation.id.to_s]
              radiology_investigation[:ipd_record_id] = ipd_record.id

              radiology_investigation.save
            end
          end
        end
      end
    end

    if ipd_record.save
      # Update CaseSheet with IPD data
      ipd_record_ids = case_sheet.ipd_record_ids
      ipd_record_ids << ipd_record.id.to_s

      case_sheet[:ipd_record_ids] = ipd_record_ids.uniq

      case_sheet.save
    end
  end

  private

  def self.diagnosis_params(new_diagnosis, diagnosis)
    new_diagnosis[:case_sheet_diagnosis_id] = diagnosis.id
    new_diagnosis[:diagnosisname] = diagnosis.diagnosisname
    new_diagnosis[:diagnosisoriginalname] = diagnosis.diagnosisoriginalname
    new_diagnosis[:icddiagnosiscode] = diagnosis.icddiagnosiscode
    new_diagnosis[:saperatedicddiagnosiscode] = diagnosis.saperatedicddiagnosiscode
    new_diagnosis[:icddiagnosiscodelength] = diagnosis.icddiagnosiscodelength
    new_diagnosis[:icd_type] = diagnosis.icd_type
    new_diagnosis[:diagnosis_comment] = diagnosis.diagnosis_comment
    new_diagnosis[:users_comment] = diagnosis.users_comment
    new_diagnosis[:user_id] = diagnosis.user_id
    new_diagnosis[:is_disabled] = diagnosis.is_disabled

    new_diagnosis[:entered_by] = diagnosis.entered_by
    new_diagnosis[:entered_by_id] = diagnosis.entered_by_id
    new_diagnosis[:entry_datetime] = diagnosis.entered_datetime
    new_diagnosis[:entered_from] = diagnosis.entered_from || "ipd_record"
    new_diagnosis[:entered_at_facility] = diagnosis.entered_at_facility
    new_diagnosis[:entered_at_facility_id] = diagnosis.entered_at_facility_id

    new_diagnosis[:advised_by] = diagnosis.advised_by || @doctor.try(:fullname)
    new_diagnosis[:advised_by_id] = diagnosis.advised_by_id || @doctor.try(:id)
    new_diagnosis[:advised_from] = diagnosis.advised_from || "ipd_record"
    new_diagnosis[:advised_datetime] = diagnosis.advised_datetime || Time.current
    new_diagnosis[:advised_at_facility] = diagnosis.advised_at_facility || @admission_facility.try(:name)
    new_diagnosis[:advised_at_facility_id] = diagnosis.advised_at_facility_id || @admission_facility.try(:id)
  end

  def self.procedure_params(new_procedure, procedure)
    new_procedure[:case_sheet_procedure_id] = procedure.id
    new_procedure[:order_advised_id] = procedure.order_advised_id

    new_procedure[:order_display_id] = procedure.order_display_id
    new_procedure[:iol_present] = procedure[:iol_present]
    new_procedure[:iol1_inventory_item_id] = procedure[:iol1_inventory_item_id]
    new_procedure[:iol2_inventory_item_id] = procedure[:iol2_inventory_item_id]
    new_procedure[:iol3_inventory_item_id] = procedure[:iol3_inventory_item_id]

    new_procedure[:procedurestage] = procedure.procedurestage
    new_procedure[:procedurename] = procedure.procedurename
    new_procedure[:procedure_id] = procedure.procedure_id
    new_procedure[:procedure_performed] = procedure.procedure_performed
    new_procedure[:procedureoriginalside] = procedure.procedureoriginalside
    new_procedure[:procedureside] = procedure.procedureside
    new_procedure[:procedurefullcode] = procedure.procedurefullcode
    new_procedure[:procedure_type] = procedure.procedure_type
    new_procedure[:procedure_comment] = procedure.procedure_comment
    new_procedure[:users_comment] = procedure.users_comment
    new_procedure[:user_id] = procedure.user_id

    new_procedure[:ot_checklist] = procedure.ot_checklist
    new_procedure[:ot_checklist_id] = procedure.ot_checklist_id

    new_procedure[:entered_by] = procedure.entered_by
    new_procedure[:entered_by_id] = procedure.entered_by_id
    new_procedure[:entry_datetime] = procedure.entry_datetime
    new_procedure[:entered_from] = procedure.entered_from || "ipd_record"
    new_procedure[:entered_at_facility] = procedure.entered_at_facility
    new_procedure[:entered_at_facility_id] = procedure.entered_at_facility_id

    new_procedure[:advised_by] = procedure.advised_by || @doctor.try(:fullname)
    new_procedure[:advised_by_id] = procedure.advised_by_id || @doctor.try(:id)
    new_procedure[:advised_from] = procedure.advised_from || "ipd_record"
    new_procedure[:advised_datetime] = procedure.advised_datetime || Time.current
    new_procedure[:advised_at_facility] = procedure.advised_at_facility || @admission_facility.try(:name)
    new_procedure[:advised_at_facility_id] = procedure.advised_at_facility_id || @admission_facility.try(:id)

    new_procedure[:has_complication_created_by] = procedure.has_complication_created_by if procedure.has_complication_created_by.present?
    new_procedure[:has_complication_created_by_id] = procedure.has_complication_created_by_id if procedure.has_complication_created_by_id.present?
    new_procedure[:has_complication_created_by_datetime] = procedure.has_complication_created_by_datetime if procedure.has_complication_created_by_datetime.present?

    if procedure.is_performed && procedure.performed_datetime.present?
      new_procedure[:is_performed] = procedure.is_performed
      new_procedure[:performed_by] = procedure.performed_by
      new_procedure[:performed_by_id] = procedure.performed_by_id
      new_procedure[:performed_from] = procedure.performed_from
      new_procedure[:performed_datetime] = procedure.performed_datetime
      new_procedure[:performed_at_facility] = procedure.performed_at_facility
      new_procedure[:performed_at_facility_id] = procedure.performed_at_facility_id
      new_procedure[:performed_note_id] = procedure.performed_note_id
      new_procedure[:has_complications] = procedure.has_complications
      new_procedure[:procedure_cnt] = procedure.procedure_cnt
      new_procedure[:complication_comment] = procedure.complication_comment
    end
  end

  def self.ophthal_investigation_params(new_ophthal_investigation, ophthal_investigation)
    new_ophthal_investigation[:case_sheet_investigation_id] = ophthal_investigation.id
    new_ophthal_investigation[:investigationstage] = ophthal_investigation.investigationstage
    new_ophthal_investigation[:investigationname] = ophthal_investigation.investigationname
    new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
    new_ophthal_investigation[:investigationoriginalside] = ophthal_investigation.investigationoriginalside
    new_ophthal_investigation[:investigationside] = ophthal_investigation.investigationside
    new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigation_full_code
    new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type

    new_ophthal_investigation[:user_id] = ophthal_investigation.entered_by
    new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by
    new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by_username
    new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_at
    new_ophthal_investigation[:entered_from] = ophthal_investigation.entered_from
    new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility_name
    new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id

    new_ophthal_investigation[:is_advised] = ophthal_investigation.is_advised
    new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by_username
    new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by
    new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_at
    new_ophthal_investigation[:advised_from] = ophthal_investigation.advised_from
    new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility_name
    new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id

    new_ophthal_investigation[:is_performed] = ophthal_investigation.is_performed
    new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by_username
    new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by
    new_ophthal_investigation[:performed_datetime] = ophthal_investigation.performed_at
    new_ophthal_investigation[:performed_from] = ophthal_investigation.performed_from
    new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility_name
    new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id

    new_ophthal_investigation[:template_created] = ophthal_investigation.template_created
    new_ophthal_investigation[:template_created_by] = ophthal_investigation.template_created_by_username
    new_ophthal_investigation[:template_created_by_id] = ophthal_investigation.template_created_by
    new_ophthal_investigation[:template_created_datetime] = ophthal_investigation.template_created_at
    new_ophthal_investigation[:template_created_from] = ophthal_investigation.performed_from
    new_ophthal_investigation[:template_created_at_facility] = ophthal_investigation.template_created_at_facility_name
    new_ophthal_investigation[:template_created_at_facility_id] = ophthal_investigation.template_created_at_facility_id

    new_ophthal_investigation[:investigation_val] = ophthal_investigation.investigation_val
    new_ophthal_investigation[:investigation_comment] = ophthal_investigation.investigation_comment
    new_ophthal_investigation[:doctors_remark] = ophthal_investigation.doctors_remark
  end

  def self.laboratory_investigation_params(new_laboratory_investigation, laboratory_investigation)
    new_laboratory_investigation[:case_sheet_investigation_id] = laboratory_investigation.id
    new_laboratory_investigation[:investigationstage] = laboratory_investigation.investigationstage
    new_laboratory_investigation[:investigationname] = laboratory_investigation.investigationname
    new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
    new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigation_full_code
    new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
    new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
    new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type

    new_laboratory_investigation[:user_id] = laboratory_investigation.entered_by
    new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by
    new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by_username
    new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_at
    new_laboratory_investigation[:entered_from] = laboratory_investigation.entered_from
    new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility_name
    new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id

    new_laboratory_investigation[:is_advised] = true
    new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by_username
    new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by
    new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_at
    new_laboratory_investigation[:advised_from] = laboratory_investigation.advised_from
    new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility_name
    new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id

    new_laboratory_investigation[:is_performed] = laboratory_investigation.is_performed
    new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by_username
    new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by
    new_laboratory_investigation[:performed_datetime] = laboratory_investigation.performed_at
    new_laboratory_investigation[:performed_from] = laboratory_investigation.performed_from
    new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility_name
    new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id

    new_laboratory_investigation[:template_created] = laboratory_investigation.template_created
    new_laboratory_investigation[:template_created_by] = laboratory_investigation.template_created_by_username
    new_laboratory_investigation[:template_created_by_id] = laboratory_investigation.template_created_by
    new_laboratory_investigation[:template_created_datetime] = laboratory_investigation.template_created_at
    new_laboratory_investigation[:template_created_from] = laboratory_investigation.performed_from
    new_laboratory_investigation[:template_created_at_facility] = laboratory_investigation.template_created_at_facility_name
    new_laboratory_investigation[:template_created_at_facility_id] = laboratory_investigation.template_created_at_facility_id

    new_laboratory_investigation[:investigation_val] = laboratory_investigation.investigation_val
    new_laboratory_investigation[:normal_range] = laboratory_investigation.normal_range
    new_laboratory_investigation[:investigation_comment] = laboratory_investigation.investigation_comment
    new_laboratory_investigation[:doctors_remark] = laboratory_investigation.doctors_remark
    new_laboratory_investigation[:laboratory_panel_records] = laboratory_investigation.laboratory_panel_records.map { |h| h.attributes }
  end

  def self.radiology_investigation_params(new_radiology_investigation, radiology_investigation)
    new_radiology_investigation[:case_sheet_investigation_id] = radiology_investigation.id
    new_radiology_investigation[:investigationstage] = radiology_investigation.investigationstage
    new_radiology_investigation[:investigationname] = radiology_investigation.investigationname
    new_radiology_investigation[:investigation_id] = radiology_investigation.investigation_id
    new_radiology_investigation[:investigationfullcode] = radiology_investigation.investigation_full_code
    new_radiology_investigation[:is_spine] = radiology_investigation.is_spine
    new_radiology_investigation[:laterality] = radiology_investigation.laterality
    new_radiology_investigation[:haslaterality] = radiology_investigation.has_laterality
    new_radiology_investigation[:radiologyoptions] = radiology_investigation.radiologyoptions
    new_radiology_investigation[:investigation_type] = radiology_investigation.investigation_type

    new_radiology_investigation[:user_id] = radiology_investigation.entered_by
    new_radiology_investigation[:entered_by_id] = radiology_investigation.entered_by
    new_radiology_investigation[:entered_by] = radiology_investigation.entered_by_username
    new_radiology_investigation[:entered_datetime] = radiology_investigation.entered_at
    new_radiology_investigation[:entered_from] = radiology_investigation.entered_from
    new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility_name
    new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id

    new_radiology_investigation[:is_advised] = true
    new_radiology_investigation[:advised_by] = radiology_investigation.advised_by_username
    new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by
    new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_at
    new_radiology_investigation[:advised_from] = radiology_investigation.advised_from
    new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility_name
    new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id

    new_radiology_investigation[:is_performed] = radiology_investigation.is_performed
    new_radiology_investigation[:performed_by] = radiology_investigation.performed_by_username
    new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by
    new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_at
    new_radiology_investigation[:performed_from] = radiology_investigation.performed_from
    new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility_name
    new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id

    new_radiology_investigation[:template_created] = radiology_investigation.template_created
    new_radiology_investigation[:template_created_by] = radiology_investigation.template_created_by_username
    new_radiology_investigation[:template_created_by_id] = radiology_investigation.template_created_by
    new_radiology_investigation[:template_created_datetime] = radiology_investigation.template_created_at
    new_radiology_investigation[:template_created_from] = radiology_investigation.performed_from
    new_radiology_investigation[:template_created_at_facility] = radiology_investigation.template_created_at_facility_name
    new_radiology_investigation[:template_created_at_facility_id] = radiology_investigation.template_created_at_facility_id

    new_radiology_investigation[:investigation_val] = radiology_investigation.investigation_val
    new_radiology_investigation[:investigation_comment] = radiology_investigation.investigation_comment
    new_radiology_investigation[:doctors_remark] = radiology_investigation.doctors_remark
  end
end
