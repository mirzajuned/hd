class IpdRecords::ComplicationService
  def self.call(ipd_record, operative_note, ipd_record_params)
    case_sheet = CaseSheet.find_by(id: ipd_record.case_sheet_id)

    # ipd record complications
    if operative_note.complication == 'No'

      ipd_record.procedure.where(performed_note_id: operative_note.id).update_all(has_complications: 'No', complication_comment_entered_by: '', complication_comment_entered_by_id: '', complication_comment_entered_at_facility: '', complication_comment_entered_at_facility_id: '', complication_comment_entered_datetime: '', complication_comment_updated_by: '', complication_comment_updated_by_id: '', complication_comment_updated_at_facility: '', complication_comment_updated_at_facility_id: '', complication_comment_updated_datetime: '', has_complication_created_by: '', has_complication_created_by_id: '', has_complication_created_by_datetime: '', has_complication_removed_by: '', has_complication_removed_by_id: '', has_complication_removed_by_datetime: '')

      ipd_record.complications.where(operative_note_id: operative_note.id).destroy_all
    elsif ipd_record_params[:complications_attributes].present?
      ipd_record_params[:complications_attributes].each do |k, complication|
        ipd_record_complication = ipd_record.complications.find_by(id: complication[:id])
        if ipd_record_complication.present?
          if ipd_record_complication.save!
            case_sheet_complication = case_sheet.complications.find_by(id: ipd_record_complication.case_sheet_complication_id)
            unless case_sheet_complication # create new case sheet
              case_sheet_complication = case_sheet.complications.new

              case_sheet_complication[:complication_name] = ipd_record_complication.complication_name
              case_sheet_complication[:code] = ipd_record_complication.code
              case_sheet_complication[:complication_original_side] = ipd_record_complication.complication_original_side

              case_sheet_complication[:operative_note_id] = ipd_record_complication.operative_note_id
              case_sheet_complication[:ipd_record_id] = ipd_record_complication.ipd_record_id
              case_sheet_complication[:procedure_id] = ipd_record_complication.procedure_id
              case_sheet_complication[:procedure_code] = ipd_record_complication.procedure_code

              case_sheet_complication[:entered_by] = ipd_record_complication.updated_by
              case_sheet_complication[:entered_by_id] = ipd_record_complication.updated_by_id
              case_sheet_complication[:entered_at_facility] = ipd_record_complication.updated_at_facility
              case_sheet_complication[:entered_at_facility_id] = ipd_record_complication.updated_at_facility_id
              case_sheet_complication[:entered_datetime] = ipd_record_complication.updated_datetime
            end

            case_sheet_complication[:comment] = ipd_record_complication.comment
            case_sheet_complication[:updated_datetime] = ipd_record_complication.updated_datetime
            case_sheet_complication[:updated_by] = ipd_record_complication.updated_by
            case_sheet_complication[:updated_by_id] = ipd_record_complication.updated_by_id
            case_sheet_complication[:updated_at_facility] = ipd_record_complication.updated_at_facility
            case_sheet_complication[:updated_at_facility_id] = ipd_record_complication.updated_at_facility_id

            case_sheet_complication.save!

            ipd_record_complication.update_attributes!(case_sheet_complication_id: case_sheet_complication.id)
          end
        end
      end
    end
    # EOF ipd record complications
  end
end
