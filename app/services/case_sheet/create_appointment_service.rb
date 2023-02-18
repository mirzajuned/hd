class CaseSheet::CreateAppointmentService
  def self.call(patient, appointment, current_user, params_case_sheet)
    case_sheets = CaseSheet.where(patient_id: patient.id, specialty_id: appointment.specialty_id).update_all(is_active: false)
    case_sheet = CaseSheet.find_by(id: appointment.case_sheet_id) || CaseSheet.new

    if case_sheet.present?
      appointment_ids = case_sheet.appointment_ids
      appointment_ids << appointment.id.to_s

      # used for clinical data analytics
      case_sheet[:patient_age] = "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}" if patient.dob_year.present?
      case_sheet[:patient_gender] = patient.gender
      case_sheet[:specialty_id] = appointment.specialty_id

      case_sheet[:appointment_ids] = appointment_ids.uniq
      case_sheet[:patient_id] = patient.id
      case_sheet[:organisation_id] = current_user.organisation_id
      case_sheet[:is_active] = true
      case_sheet[:case_name] = case_sheet.case_name || (params_case_sheet[:case_name] if params_case_sheet.present?) || nil
      case_sheet[:start_date] = case_sheet.start_date || (params_case_sheet[:start_date] if params_case_sheet.present?) || nil
      case_sheet[:case_switchable_opd] = case_sheet.case_switchable_opd
      case_sheet[:case_switchable_opd][appointment.id.to_s] = Hash[case_switchable: true]

      if case_sheet.save
        appointment.update(case_sheet_id: case_sheet.id) unless appointment.case_sheet_id.present?
        unless case_sheet.case_id.present?
          case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', case_sheet.id.to_s, {organisation_id: appointment.organisation_id.to_s, facility_id: appointment.facility_id.to_s, region_id: appointment.facility.try(:region_master_id).to_s})
          case_sheet.update(case_id: case_id)
        end
        # begin# this will allow creation of orders for casesheet advised procedure/investigation etc
          if patient.case_sheet_order_migrated != true
            OrderJobs::AdvisedJob.perform_later(case_sheet.id.to_s, current_user.id.to_s, appointment.facility_id.to_s)
            patient.update(case_sheet_order_migrated: true)
          end
        # rescue
        # end
      end
    end
  end
end
