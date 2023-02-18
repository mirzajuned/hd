class IpdRecords::UpdateService
  def self.call(ipd_record, operative_note, ipd_record_params)
    case_sheet = CaseSheet.find_by(id: ipd_record.case_sheet_id)

    # ipd record procedure
    if ipd_record_params[:procedure].present?

      @analytics_params = {}
      analytics_before_params_operative_note(case_sheet)

      ipd_record_params[:procedure].each do |k, procedure|
        ipd_record_procedure = ipd_record.procedure.find_by(id: procedure[:id])
        if ipd_record_procedure.present?
          performing_doctor = User.find_by(id: procedure[:performed_by])
          ipd_record_procedure[:is_performed] = procedure[:is_performed]
          if ipd_record_procedure.performed_from != "opd_record"
            ipd_record_procedure[:procedure_cnt] = procedure[:procedure_cnt]
            if procedure[:is_performed] == 'true'
              ipd_record_procedure[:previous_stage] = ipd_record_procedure.procedurestage if ipd_record_procedure.previous_stage.nil?
              ipd_record_procedure[:procedurestage] = "Performed"
              ipd_record_procedure[:has_complications] = procedure[:has_complications] if procedure[:has_complications]
              ipd_record_procedure[:complication_comment] = procedure[:complication_comment] if procedure[:complication_comment]
              ipd_record_procedure[:performed_by_id] = procedure[:performed_by]
              ipd_record_procedure[:performed_by] = performing_doctor&.fullname
              ipd_record_procedure[:performed_datetime] = (Time.zone.parse(procedure[:performed_datetime].to_s + Time.current.strftime(', %I:%M %p')) if procedure[:performed_datetime].present?) || Time.current
              ipd_record_procedure[:performed_date] = (Date.parse(procedure[:performed_date].to_s) if procedure[:performed_date].present?) || Date.current
              ipd_record_procedure[:performed_time] = (Time.zone.parse(procedure[:performed_time].to_s) if procedure[:performed_time].present?) || Time.current
              ipd_record_procedure[:performed_from] = 'ipd_record'
              ipd_record_procedure[:performed_note_id] = ipd_record_procedure.performed_note_id || operative_note.id
              ipd_record_procedure[:performed_at_facility_id] = ipd_record.facility_id
              ipd_record_procedure[:performed_at_facility] = ipd_record.facility.try(:name)

              # procedure comment created by/updated by record
              ipd_record_procedure[:complication_comment_entered_by] = procedure[:complication_comment_entered_by] if procedure[:complication_comment_entered_by].present?
              ipd_record_procedure[:complication_comment_entered_by_id] = procedure[:complication_comment_entered_by_id] if procedure[:complication_comment_entered_by_id].present?
              ipd_record_procedure[:complication_comment_entered_at_facility] = procedure[:complication_comment_entered_at_facility] if procedure[:complication_comment_entered_at_facility].present?
              ipd_record_procedure[:complication_comment_entered_at_facility_id] = procedure[:complication_comment_entered_at_facility_id] if procedure[:complication_comment_entered_at_facility_id].present?
              ipd_record_procedure[:complication_comment_entered_datetime] = procedure[:complication_comment_entered_datetime] if procedure[:complication_comment_entered_datetime].present?
              ipd_record_procedure[:complication_comment_updated_by] = procedure[:complication_comment_updated_by] if procedure[:complication_comment_updated_by].present?
              ipd_record_procedure[:complication_comment_updated_by_id] = procedure[:complication_comment_updated_by_id] if procedure[:complication_comment_updated_by_id].present?
              ipd_record_procedure[:complication_comment_updated_at_facility] = procedure[:complication_comment_updated_at_facility] if procedure[:complication_comment_updated_at_facility].present?
              ipd_record_procedure[:complication_comment_updated_at_facility_id] = procedure[:complication_comment_updated_at_facility_id] if procedure[:complication_comment_updated_at_facility_id].present?
              ipd_record_procedure[:complication_comment_updated_datetime] = procedure[:complication_comment_updated_datetime] if procedure[:complication_comment_updated_datetime].present?

              ipd_record_procedure[:has_complication_created_by] = procedure[:has_complication_created_by] if procedure[:has_complication_created_by].present?
              ipd_record_procedure[:has_complication_created_by_id] = procedure[:has_complication_created_by_id] if procedure[:has_complication_created_by_id].present?
              ipd_record_procedure[:has_complication_created_by_datetime] = procedure[:has_complication_created_by_datetime] if procedure[:has_complication_created_by_datetime].present?

              ipd_record_procedure[:has_complication_removed_by] = procedure[:has_complication_removed_by] if procedure[:has_complication_removed_by].present?
              ipd_record_procedure[:has_complication_removed_by_id] = procedure[:has_complication_removed_by_id] if procedure[:has_complication_removed_by_id].present?
              ipd_record_procedure[:has_complication_removed_by_datetime] = procedure[:has_complication_removed_by_datetime] if procedure[:has_complication_removed_by_datetime].present?
            else
              ipd_record_procedure[:procedurestage] = ipd_record_procedure.previous_stage || ipd_record_procedure.procedurestage
              ipd_record_procedure[:previous_stage] = nil
              ipd_record_procedure[:performed_by_id] = nil
              ipd_record_procedure[:performed_by] = nil
              ipd_record_procedure[:performed_datetime] = nil
              ipd_record_procedure[:performed_date] = nil
              ipd_record_procedure[:performed_time] = nil
              ipd_record_procedure[:performed_from] = nil
              ipd_record_procedure[:performed_note_id] = nil
              ipd_record_procedure[:performed_at_facility_id] = nil
              ipd_record_procedure[:performed_at_facility] = nil

              ipd_record.complications.where(procedure_id: ipd_record_procedure.id).destroy_all
              ipd_record_procedure[:has_complications] = 'No'
              ipd_record_procedure[:complication_comment] = nil
              ipd_record_procedure[:complication_comment_entered_by] = nil
              ipd_record_procedure[:complication_comment_entered_by_id] = nil
              ipd_record_procedure[:complication_comment_entered_at_facility] = nil
              ipd_record_procedure[:complication_comment_entered_at_facility_id] = nil
              ipd_record_procedure[:complication_comment_entered_datetime] = nil
              ipd_record_procedure[:complication_comment_updated_by] = nil
              ipd_record_procedure[:complication_comment_updated_by_id] = nil
              ipd_record_procedure[:complication_comment_updated_at_facility] = nil
              ipd_record_procedure[:complication_comment_updated_at_facility_id] = nil
              ipd_record_procedure[:complication_comment_updated_datetime] = nil

              ipd_record_procedure[:has_complication_created_by] = nil
              ipd_record_procedure[:has_complication_created_by_id] = nil
              ipd_record_procedure[:has_complication_created_by_datetime] = nil
              ipd_record_procedure[:has_complication_removed_by] = nil
              ipd_record_procedure[:has_complication_removed_by_id] = nil
              ipd_record_procedure[:has_complication_removed_by_datetime] = nil
            end

            if ipd_record_procedure.save!
              same_procedures = ipd_record.procedure.where(procedurefullcode: ipd_record_procedure.procedurefullcode, procedureside: ipd_record_procedure.procedureside)
              if ipd_record_procedure.is_performed
                same_procedures.update_all(performed_inline: true)
              else
                same_procedures.update_all(performed_inline: false)
              end

              case_sheet_procedure = case_sheet.procedures.find_by(id: ipd_record_procedure.case_sheet_procedure_id)
              if case_sheet_procedure
                case_sheet_procedure[:is_performed] = ipd_record_procedure.is_performed
                case_sheet_procedure[:procedurestage] = ipd_record_procedure.procedurestage
                case_sheet_procedure[:previous_stage] = ipd_record_procedure.previous_stage
                case_sheet_procedure[:performed_by_id] = ipd_record_procedure.performed_by_id
                case_sheet_procedure[:performed_by] = ipd_record_procedure.performed_by
                case_sheet_procedure[:performed_datetime] = ipd_record_procedure.performed_datetime
                case_sheet_procedure[:performed_date] = ipd_record_procedure.performed_date
                case_sheet_procedure[:performed_time] = ipd_record_procedure.performed_time
                case_sheet_procedure[:performed_from] = ipd_record_procedure.performed_from
                case_sheet_procedure[:performed_note_id] = ipd_record_procedure.performed_note_id
                case_sheet_procedure[:performed_at_facility_id] = ipd_record_procedure.performed_at_facility_id
                case_sheet_procedure[:performed_at_facility] = ipd_record_procedure.performed_at_facility

                if case_sheet_procedure.save!
                  same_cs_procedures = case_sheet.procedures.where(:id.in => same_procedures.pluck(:case_sheet_procedure_id))
                  if case_sheet_procedure.is_performed
                    same_cs_procedures.update_all(performed_inline: true)
                  else
                    same_cs_procedures.update_all(performed_inline: false)
                  end
                end
              end
            end
          end
        end
      end

      analytics_after_params_operative_note(case_sheet)
      Analytics::CreateService.call(@analytics_params.to_json, ipd_record.doctor_id.to_s, ipd_record.facility_id.to_s, "clinical_data")
    end
    # EOF ipd record procedure
  end

  def self.update_checklist_inprocedure(ipd_record, ot_checklist, ipd_record_params)
    case_sheet = CaseSheet.find_by(id: ipd_record.case_sheet_id)
    if ipd_record_params[:procedure].present?
      ipd_record_params[:procedure].each do |k, procedure|
        ipd_record_procedure = ipd_record.procedure.find_by(id: procedure[:id])
        if ipd_record_procedure.present?
          ipd_record_procedure[:ot_checklist] = procedure[:ot_checklist]
          if ipd_record_procedure[:ot_checklist]
            ipd_record_procedure[:ot_checklist_id] = ot_checklist.id
          else
            ipd_record_procedure.ot_checklist_id = nil
          end
          ipd_record_procedure.save!

          case_sheet_procedure = case_sheet.procedures.find_by(id: ipd_record_procedure.case_sheet_procedure_id)
          if case_sheet_procedure.present?
            case_sheet_procedure[:ot_checklist] = procedure[:ot_checklist]
            if case_sheet_procedure[:ot_checklist]
              case_sheet_procedure[:ot_checklist_id] = ot_checklist.id
            else
              case_sheet_procedure.ot_checklist_id = nil
            end
            case_sheet_procedure.save!
          end
        end
      end
    end
  end

  private

  def self.analytics_before_params_operative_note(case_sheet)
    analytics_case_sheet = CaseSheet.find_by(id: case_sheet.id) # done intentionally, data was getting updated as of after save method

    @analytics_params["before_save_diagnosis"] = analytics_case_sheet.diagnoses.to_a
    @analytics_params["before_save_procedure"] = analytics_case_sheet.procedures.to_a
    @analytics_params["before_save_ophthal_investigations"] = analytics_case_sheet.ophthal_investigations.to_a
    @analytics_params["before_save_radiology_investigations"] = analytics_case_sheet.radiology_investigations.to_a
    @analytics_params["before_save_laboratory_investigations"] = analytics_case_sheet.laboratory_investigations.to_a
  end

  def self.analytics_after_params_operative_note(case_sheet)
    @analytics_params["data_from"] = "operative_note"
    @analytics_params["case_sheet_id"] = case_sheet.id
    @analytics_params["after_save_diagnosis"] = case_sheet.diagnoses
    @analytics_params["after_save_procedure"] = case_sheet.procedures
    @analytics_params["after_save_ophthal_investigations"] = case_sheet.ophthal_investigations
    @analytics_params["after_save_radiology_investigations"] = case_sheet.radiology_investigations
    @analytics_params["after_save_laboratory_investigations"] = case_sheet.laboratory_investigations
  end
end
