class CaseSheet::ChangeCaseOtScheduleService
  def self.call(params, current_user, old_case_sheet, new_case_sheet)
    ot_schedule = OtSchedule.find_by(id: params[:ot_schedule_id])

    new_case_sheet[:specialty_id] ||= ot_schedule&.specialty_id
    # Append ot_schedule id to New CaseSheet
    ot_schedule_ids = new_case_sheet.ot_schedule_ids
    ot_schedule_ids << ot_schedule.id.to_s

    new_case_sheet.save!
    unless new_case_sheet.case_id.present?
      case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', new_case_sheet.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: ot_schedule.facility.id.to_s, region_id: ot_schedule.facility.try(:region_master_id).to_s})
      new_case_sheet.update(case_id: case_id)
    end

    # Update Related Models
    ot_schedule.update(case_sheet_id: new_case_sheet.id, admission_id: nil)

    # UPDATE OLD CASE
    switch_ot_schedule_ids = old_case_sheet.ot_schedule_ids
    switch_ot_schedule_ids.delete(ot_schedule.id.to_s)

    old_case_sheet[:ot_schedule_ids] = switch_ot_schedule_ids

    old_case_sheet.save!
  end
end
