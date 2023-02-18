class CaseSheet::ChangeCaseAppointmentService
  def self.call(params, current_user, old_case_sheet, new_case_sheet)
    appointment = Appointment.find_by(id: params[:appointment_id])
    opd_records = OpdRecord.where(appointmentid: appointment.id.to_s)
    investigation_details = Investigation::InvestigationDetail.where(appointment_id: appointment.id.to_s)
    appointment_opd_record_ids = opd_records.pluck(:id)

    # Append Appointment id to New CaseSheet
    appointment_ids = new_case_sheet.appointment_ids
    appointment_ids << appointment.id.to_s

    # Append OpdRecord id to New CaseSheet
    opd_record_ids = new_case_sheet.opd_record_ids
    opd_record_ids = (opd_record_ids + appointment_opd_record_ids).uniq

    # Pull embedded data to be switched from Old CaseSheet to New CaseSheet
    switch_chief_complaints = old_case_sheet.chief_complaints.where(appointment_id: appointment.id.to_s)
    switch_diagnoses = old_case_sheet.diagnoses.where(appointment_id: appointment.id.to_s)
    switch_procedures = old_case_sheet.procedures.where(appointment_id: appointment.id.to_s)
    switch_ophthal_investigations = old_case_sheet.ophthal_investigations.where(appointment_id: appointment.id.to_s)
    switch_laboratory_investigations = old_case_sheet.laboratory_investigations.where(appointment_id: appointment.id.to_s)
    switch_radiology_investigations = old_case_sheet.radiology_investigations.where(appointment_id: appointment.id.to_s)

    # CaseSheet Params
    new_case_sheet[:appointment_ids] = appointment_ids
    new_case_sheet[:opd_record_ids] = opd_record_ids.uniq
    new_case_sheet[:is_active] = true
    new_case_sheet[:updated_by_id] = current_user.try(:id)
    new_case_sheet[:specialty_id] ||= appointment&.specialty_id

    # Case Switchable
    new_case_sheet[:case_switchable_opd] = new_case_sheet.case_switchable_opd
    new_case_sheet[:case_switchable_opd][appointment.id.to_s] = old_case_sheet[:case_switchable_opd][appointment.id.to_s]

    # Freeform Diagnosis/Procedure/Investigation
    opd_records.each do |record|
      if record.templatetype == "freeform"
        new_case_sheet[:free_form_histories][record.id.to_s] = Hash[record_id: record.id.to_s, record_type: "opd_record", consultant_id: record.consultant_id, consultant_name: record.consultant_name, content: record.clincalevaluation, date: record.updated_at]
        new_case_sheet[:free_form_diagnoses][record.id.to_s] = Hash[record_id: record.id.to_s, record_type: "opd_record", consultant_id: record.consultant_id, consultant_name: record.consultant_name, content: record.diagnosis, date: record.updated_at]
        new_case_sheet[:free_form_procedures][record.id.to_s] = Hash[record_id: record.id.to_s, record_type: "opd_record", consultant_id: record.consultant_id, consultant_name: record.consultant_name, content: record.free_procedure, date: record.updated_at]
        new_case_sheet[:free_form_investigations][record.id.to_s] = Hash[record_id: record.id.to_s, record_type: "opd_record", consultant_id: record.consultant_id, consultant_name: record.consultant_name, content: record.plan, date: record.updated_at]
      end
      if record.specalityid == "309989009"
        new_case_sheet[:free_form_procedures][record.id.to_s] = Hash[record_id: record.id.to_s, record_type: "opd_record", consultant_id: record.consultant_id, consultant_name: record.consultant_name, content: record.procedurecomments]
      end
    end

    # Cheif Complaints
    switch_chief_complaints.each do |chief_complaint|
      new_case_sheet.chief_complaints.new(chief_complaint.attributes).save
    end

    # Diagnoses
    switch_diagnoses.each do |diagnosis|
      new_case_sheet.diagnoses.new(diagnosis.attributes).save
    end

    # Procedures
    switch_procedures.each do |procedure|
      new_case_sheet.procedures.new(procedure.attributes).save
    end

    # Ophthal Investigations
    switch_ophthal_investigations.each do |ophthal_investigation|
      new_case_sheet.ophthal_investigations.new(ophthal_investigation.attributes).save
    end

    # Laboratory Investigations
    switch_laboratory_investigations.each do |laboratory_investigation|
      new_case_sheet.laboratory_investigations.new(laboratory_investigation.attributes).save
    end

    # Radiology Investigations
    switch_radiology_investigations.each do |radiology_investigation|
      new_case_sheet.radiology_investigations.new(radiology_investigation.attributes).save
    end
    # CaseSheet Params Ends

    new_case_sheet.save!
    unless new_case_sheet.case_id.present?
      case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', new_case_sheet.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: appointment.facility.id.to_s, region_id: appointment.facility.try(:region_master_id).to_s})
      new_case_sheet.update(case_id: case_id)
    end

    # Update Related Models
    appointment.update(case_sheet_id: new_case_sheet.id)
    opd_records.update_all(case_sheet_id: new_case_sheet.id)
    investigation_details.update_all(case_sheet_id: new_case_sheet.id)

    # UPDATE OLD CASE
    switch_appointment_ids = old_case_sheet.appointment_ids
    switch_appointment_ids.delete(appointment.id.to_s)

    switch_opd_record_ids = old_case_sheet.opd_record_ids
    appointment_opd_record_ids.each do |opd_record_id|
      switch_opd_record_ids.delete(opd_record_id)
    end

    # Delete ChiefComplaints/Diagnosis/Procedure/Investigation
    switch_chief_complaints.delete_all
    switch_diagnoses.delete_all
    switch_procedures.delete_all
    switch_ophthal_investigations.delete_all
    switch_laboratory_investigations.delete_all
    switch_radiology_investigations.delete_all

    # Delete OldCase Switchable
    old_case_sheet.case_switchable_opd.delete(appointment.id.to_s)

    # Freeform Diagnosis/Procedure/Investigation
    opd_records.each do |record|
      old_case_sheet.free_form_diagnoses.delete(record.id.to_s)
      old_case_sheet.free_form_procedures.delete(record.id.to_s)
      old_case_sheet.free_form_investigations.delete(record.id.to_s)
    end

    old_case_sheet[:free_form_histories] = old_case_sheet.free_form_histories
    old_case_sheet[:free_form_diagnoses] = old_case_sheet.free_form_diagnoses
    old_case_sheet[:free_form_procedures] = old_case_sheet.free_form_procedures
    old_case_sheet[:free_form_investigations] = old_case_sheet.free_form_investigations

    old_case_sheet[:appointment_ids] = switch_appointment_ids
    old_case_sheet[:opd_record_ids] = switch_opd_record_ids
    old_case_sheet[:is_active] = false
    old_case_sheet[:updated_by_id] = current_user.try(:id)

    old_case_sheet.save!
  end

  private

  def self.diagnosis_params(new_diagnosis, diagnosis)
    new_diagnosis[:id] = diagnosis.id
    new_diagnosis[:record_id] = diagnosis.record_id
    new_diagnosis[:opd_diagnosis_id] = diagnosis.opd_diagnosis_id
    new_diagnosis[:diagnosisname] = diagnosis.diagnosisname
    new_diagnosis[:diagnosisoriginalname] = diagnosis.diagnosisoriginalname
    new_diagnosis[:icddiagnosiscode] = diagnosis.icddiagnosiscode
    new_diagnosis[:saperatedicddiagnosiscode] = diagnosis.saperatedicddiagnosiscode
    new_diagnosis[:icddiagnosiscodelength] = diagnosis.icddiagnosiscodelength
    new_diagnosis[:icd_type] = diagnosis.icd_type

    new_diagnosis[:user_id] = diagnosis.user_id
    new_diagnosis[:consultant_id] = diagnosis.consultant_id
    new_diagnosis[:consultant_name] = diagnosis.consultant_name
    new_diagnosis[:template_type] = diagnosis.template_type

    new_diagnosis[:entered_by] = diagnosis.entered_by
    new_diagnosis[:entered_by_id] = diagnosis.entered_by_id
    new_diagnosis[:entered_datetime] = diagnosis.entered_datetime
    new_diagnosis[:entered_at_facility] = diagnosis.entered_at_facility
    new_diagnosis[:entered_at_facility_id] = diagnosis.entered_at_facility_id

    new_diagnosis[:is_advised] = diagnosis.is_advised
    new_diagnosis[:advised_by] = diagnosis.advised_by
    new_diagnosis[:advised_by_id] = diagnosis.advised_by_id
    new_diagnosis[:advised_datetime] = diagnosis.advised_datetime
    new_diagnosis[:advised_at_facility] = diagnosis.advised_at_facility
    new_diagnosis[:advised_at_facility_id] = diagnosis.advised_at_facility_id
  end

  def self.procedure_params(new_procedure, procedure)
    new_procedure[:record_id] = procedure.record_id
    new_procedure[:opd_procedure_id] = procedure.opd_procedure_id
    new_procedure[:procedurestage] = procedure.procedurestage
    new_procedure[:procedurename] = procedure.procedurename
    new_procedure[:procedure_id] = procedure.procedure_id
    new_procedure[:procedureside] = procedure.procedureside
    new_procedure[:procedurefullcode] = procedure.procedurefullcode
    new_procedure[:procedure_type] = procedure.procedure_type

    new_procedure[:user_id] = procedure.user_id
    new_procedure[:consultant_id] = procedure.consultant_id
    new_procedure[:consultant_name] = procedure.consultant_name
    new_procedure[:template_type] = procedure.template_type

    new_procedure[:entered_by_id] = procedure.entered_by_id
    new_procedure[:entered_by] = procedure.entered_by
    new_procedure[:entered_datetime] = procedure.entered_datetime
    new_procedure[:entered_from] = procedure.entered_from
    new_procedure[:entered_at_facility_id] = procedure.entered_at_facility_id
    new_procedure[:entered_at_facility] = procedure.entered_at_facility

    new_procedure[:is_advised] = procedure.is_advised
    new_procedure[:advised_by] = procedure.advised_by
    new_procedure[:advised_by_id] = procedure.advised_by_id
    new_procedure[:advised_datetime] = procedure.advised_datetime
    new_procedure[:advised_at_facility] = procedure.advised_at_facility
    new_procedure[:advised_at_facility_id] = procedure.advised_at_facility_id

    new_procedure[:is_performed] = procedure.is_performed
    new_procedure[:performed_by_id] = procedure.performed_by_id
    new_procedure[:performed_by] = procedure.performed_by
    new_procedure[:performed_at] = procedure.performed_at
    new_procedure[:performed_from] = procedure.performed_from
    new_procedure[:performed_at_facility_id] = procedure.performed_at_facility_id
    new_procedure[:performed_at_facility] = procedure.performed_at_facility
    new_procedure[:performed_comment] = procedure.performed_comment
    new_procedure[:users_comment] = procedure.users_comment
  end

  def self.ophthal_investigation_params(new_ophthal_investigation, ophthal_investigation)
    new_ophthal_investigation[:record_id] = ophthal_investigation.record_id
    new_ophthal_investigation[:opd_investigation_id] = ophthal_investigation.opd_investigation_id
    new_ophthal_investigation[:investigationstage] = ophthal_investigation.investigationstage
    new_ophthal_investigation[:investigationname] = ophthal_investigation.investigationname
    new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
    new_ophthal_investigation[:investigationside] = ophthal_investigation.investigationside
    new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigationfullcode
    new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type

    new_ophthal_investigation[:user_id] = ophthal_investigation.user_id
    new_ophthal_investigation[:consultant_id] = ophthal_investigation.consultant_id
    new_ophthal_investigation[:consultant_name] = ophthal_investigation.consultant_name
    new_ophthal_investigation[:template_type] = ophthal_investigation.template_type

    new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by_id
    new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by
    new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_datetime
    new_ophthal_investigation[:entered_from] = ophthal_investigation.entered_from
    new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id
    new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility

    new_ophthal_investigation[:is_advised] = ophthal_investigation.is_advised
    new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by
    new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by_id
    new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_datetime
    new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility
    new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id

    new_ophthal_investigation[:is_performed] = ophthal_investigation.is_performed
    new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by_id
    new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by
    new_ophthal_investigation[:performed_at] = ophthal_investigation.performed_at
    new_ophthal_investigation[:performed_from] = ophthal_investigation.performed_from
    new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id
    new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility
    new_ophthal_investigation[:performed_comment] = ophthal_investigation.performed_comment
  end

  def self.laboratory_investigation_params(new_laboratory_investigation, laboratory_investigation)
    new_laboratory_investigation[:record_id] = laboratory_investigation.record_id
    new_laboratory_investigation[:opd_investigation_id] = laboratory_investigation.opd_investigation_id
    new_laboratory_investigation[:investigationstage] = laboratory_investigation.investigationstage
    new_laboratory_investigation[:investigationname] = laboratory_investigation.investigationname
    new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
    new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigationfullcode
    new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
    new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
    new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type

    new_laboratory_investigation[:user_id] = laboratory_investigation.user_id
    new_laboratory_investigation[:consultant_id] = laboratory_investigation.consultant_id
    new_laboratory_investigation[:consultant_name] = laboratory_investigation.consultant_name
    new_laboratory_investigation[:template_type] = laboratory_investigation.template_type

    new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by_id
    new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by
    new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_datetime
    new_laboratory_investigation[:entered_from] = laboratory_investigation.entered_from
    new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id
    new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility

    new_laboratory_investigation[:is_advised] = laboratory_investigation.is_advised
    new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by
    new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by_id
    new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_datetime
    new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility
    new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id

    new_laboratory_investigation[:is_performed] = laboratory_investigation.is_performed
    new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by_id
    new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by
    new_laboratory_investigation[:performed_at] = laboratory_investigation.performed_at
    new_laboratory_investigation[:performed_from] = laboratory_investigation.performed_from
    new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id
    new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility
    new_laboratory_investigation[:performed_comment] = laboratory_investigation.performed_comment
  end

  def self.radiology_investigation_params(new_radiology_investigation, radiology_investigation)
    new_radiology_investigation[:record_id] = radiology_investigation.record_id
    new_radiology_investigation[:opd_investigation_id] = radiology_investigation.opd_investigation_id
    new_radiology_investigation[:investigationstage] = radiology_investigation.investigationstage
    new_radiology_investigation[:investigationname] = radiology_investigation.investigationname
    new_radiology_investigation[:investigation_id] = radiology_investigation.investigation_id
    new_radiology_investigation[:investigationfullcode] = radiology_investigation.investigationfullcode
    new_radiology_investigation[:is_spine] = radiology_investigation.is_spine
    new_radiology_investigation[:laterality] = radiology_investigation.laterality
    new_radiology_investigation[:haslaterality] = radiology_investigation.haslaterality
    new_radiology_investigation[:radiologyoptions] = radiology_investigation.radiologyoptions
    new_radiology_investigation[:investigation_type] = radiology_investigation.investigation_type

    new_radiology_investigation[:user_id] = radiology_investigation.user_id
    new_radiology_investigation[:consultant_id] = radiology_investigation.consultant_id
    new_radiology_investigation[:consultant_name] = radiology_investigation.consultant_name
    new_radiology_investigation[:template_type] = radiology_investigation.template_type

    new_radiology_investigation[:entered_by_id] = radiology_investigation.entered_by_id
    new_radiology_investigation[:entered_by] = radiology_investigation.entered_by
    new_radiology_investigation[:entered_datetime] = radiology_investigation.entered_datetime
    new_radiology_investigation[:entered_from] = radiology_investigation.entered_from
    new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id
    new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility

    new_radiology_investigation[:is_advised] = radiology_investigation.is_advised
    new_radiology_investigation[:advised_by] = radiology_investigation.advised_by
    new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by_id
    new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_datetime
    new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility
    new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id

    new_radiology_investigation[:is_performed] = radiology_investigation.is_performed
    new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by_id
    new_radiology_investigation[:performed_by] = radiology_investigation.performed_by
    new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_datetime
    new_radiology_investigation[:performed_from] = radiology_investigation.performed_from
    new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id
    new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility
    new_radiology_investigation[:performed_comment] = radiology_investigation.performed_comment
  end
end
