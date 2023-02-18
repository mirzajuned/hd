class CaseSheet::ChangeCaseService
  def self.call(params, current_user)
    old_case_sheet = CaseSheet.find_by(id: params[:old_case_sheet_id]) if params[:old_case_sheet_id].present?
    new_case_sheet = CaseSheet.find_by(id: params[:case_selected]) || CaseSheet.new

    if old_case_sheet.present? && new_case_sheet.present?
      patient = Patient.find_by(id: params[:patient_id])

      # Common CaseSheet Params
      new_case_sheet[:case_name] = params[:case_sheet][:case_name]
      new_case_sheet[:patient_id] = patient.id
      new_case_sheet[:organisation_id] = current_user.organisation_id
      new_case_sheet[:specialty_id] = old_case_sheet&.specialty_id

      if params[:case_selected] == "new_case"
        new_case_sheet[:created_by_id] = current_user.try(:id)
      end

      if params[:appointment_id].present?
        CaseSheet::ChangeCaseAppointmentService.call(params, current_user, old_case_sheet, new_case_sheet)
      elsif params[:admission_id].present?
        CaseSheet::ChangeCaseAdmissionService.call(params, current_user, old_case_sheet, new_case_sheet)
      elsif params[:ot_schedule_id].present?
        CaseSheet::ChangeCaseOtScheduleService.call(params, current_user, old_case_sheet, new_case_sheet)
      end
    end
  end
end
