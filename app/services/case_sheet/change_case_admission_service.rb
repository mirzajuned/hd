class CaseSheet::ChangeCaseAdmissionService
  def self.call(params, current_user, old_case_sheet, new_case_sheet)
    admission = Admission.find_by(id: params[:admission_id])
    ot_schedules = OtSchedule.where(admission_id: params[:admission_id])
    ipd_records = Inpatient::IpdRecord.where(admission_id: admission.id.to_s)
    admission_ot_schedule_ids = ot_schedules.pluck(:id)
    admission_ipd_record_ids = ipd_records.pluck(:id)

    new_case_sheet[:specialty_id] ||= admission&.specialty_id

    # Append Admission id to New CaseSheet
    admission_ids = new_case_sheet.admission_ids
    admission_ids << admission.id.to_s

    # Append OtSchedule id to New CaseSheet
    ot_schedule_ids = new_case_sheet.ot_schedule_ids
    ot_schedule_ids = (ot_schedule_ids + admission_ot_schedule_ids).uniq

    # Append IpdRecord id to New CaseSheet
    ipd_record_ids = new_case_sheet.ipd_record_ids
    ipd_record_ids = (ipd_record_ids + admission_ipd_record_ids).uniq

    # Case Switchable
    new_case_sheet[:case_switchable_ipd][admission.id.to_s] = old_case_sheet[:case_switchable_ipd][admission.id.to_s]

    new_case_sheet.save!
    unless new_case_sheet.case_id.present?
      case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', new_case_sheet.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: admission.facility.id.to_s, region_id: admission.facility.try(:region_master_id).to_s})
      new_case_sheet.update(case_id: case_id)
    end

    # Update Related Models
    admission.update(case_sheet_id: new_case_sheet.id)
    ot_schedules.update_all(case_sheet_id: new_case_sheet.id)
    ipd_records.update_all(case_sheet_id: new_case_sheet.id)

    # UPDATE OLD CASE
    switch_admission_ids = old_case_sheet.admission_ids
    switch_admission_ids.delete(admission.id.to_s)

    switch_ot_schedule_ids = old_case_sheet.ot_schedule_ids
    admission_ot_schedule_ids.each do |ot_schedule_id|
      switch_ot_schedule_ids.delete(ot_schedule_id)
    end

    switch_ipd_record_ids = old_case_sheet.ipd_record_ids
    admission_ipd_record_ids.each do |ipd_record_id|
      switch_ipd_record_ids.delete(ipd_record_id)
    end

    # Delete OldCase Switchable
    old_case_sheet.case_switchable_ipd.delete(admission.id.to_s)

    old_case_sheet[:admission_ids] = switch_admission_ids
    old_case_sheet[:ot_schedules] = switch_ot_schedule_ids
    old_case_sheet[:ipd_record_ids] = switch_ipd_record_ids

    old_case_sheet.save!
  end
end
