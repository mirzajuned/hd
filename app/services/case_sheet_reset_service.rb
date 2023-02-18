class CaseSheetResetService
  def self.call(patient_id)
    case_sheets = CaseSheet.where(patient_id: patient_id)
    if case_sheets.count > 0
      case_sheet_ids = case_sheets.pluck(:id).map(&:to_s)

      Appointment.where(:case_sheet_id.in => case_sheet_ids).update_all(case_sheet_id: nil)
      Admission.where(:case_sheet_id.in => case_sheet_ids).update_all(case_sheet_id: nil)
      OtSchedule.where(:case_sheet_id.in => case_sheet_ids).update_all(case_sheet_id: nil)
      OpdRecord.where(:case_sheet_id.in => case_sheet_ids).update_all(case_sheet_id: nil)
      Inpatient::IpdRecord.where(:case_sheet_id.in => case_sheet_ids).update_all(case_sheet_id: nil)
      Investigation::InvestigationDetail.where(:case_sheet_id.in => case_sheet_ids).update_all(case_sheet_id: nil)

      Patient.find_by(id: patient_id).update(case_sheet_linked: false)

      case_sheets.delete_all
    end
  end
end
