class CounsellorRecordJobs::PatientCounselledJob < ActiveJob::Base
  queue_as :urgent

  def perform(counsellor_record_id)
    @counsellor_record = CounsellorRecord.find_by(id: counsellor_record_id)
    if @counsellor_record.present?
      @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @counsellor_record.appointment_id.to_s)
      @converted_flag = false

      # InvestigationDetails Update
      Investigation::InvestigationDetails::CounsellorCreateService.call(@counsellor_record)

      # CaseSheet Update
      @case_sheet = CaseSheet::CreateCounsellorRecordService.call(@counsellor_record)

      # CounsellorWorkflow
      if @counsellor_workflow.present?
        if @counsellor_record.try(:procedures).count > 0
          @counsellor_record.procedures.each do |procedure|
            if procedure.is_converted
              unless @counsellor_workflow.converted_state.include?("Surgery")
                @counsellor_workflow.add_to_set(converted_state: "Surgery")
              end
              @counsellor_workflow.converted if @counsellor_workflow.state != "converted"
              @converted_flag = true
              break
            else
              @counsellor_workflow.undo_converted if (@counsellor_workflow.state == "converted" && !@converted_flag)
            end
          end
        end

        if @counsellor_record.try(:ophthal_investigations).count > 0 || @counsellor_record.try(:laboratory_investigations).count > 0 || @counsellor_record.try(:radiology_investigations).count > 0
          @counsellor_record.ophthal_investigations.each do |investigation|
            if investigation.is_converted
              unless @counsellor_workflow.converted_state.include?("Investigation")
                @counsellor_workflow.add_to_set(converted_state: "Investigation")
              end
              @counsellor_workflow.converted if @counsellor_workflow.state != "converted"
              @converted_flag = true
              break
            else
              @counsellor_workflow.undo_converted if (@counsellor_workflow.state == "converted" && !@converted_flag)
            end
          end

          @counsellor_record.laboratory_investigations.each do |investigation|
            if investigation.is_converted
              unless @counsellor_workflow.converted_state.include?("Investigation")
                @counsellor_workflow.add_to_set(converted_state: "Investigation")
              end
              @counsellor_workflow.converted if @counsellor_workflow.state != "converted"
              @converted_flag = true
              break
            else
              @counsellor_workflow.undo_converted if (@counsellor_workflow.state == "converted" && !@converted_flag)
            end
          end

          @counsellor_record.radiology_investigations.each do |investigation|
            if investigation.is_converted
              unless @counsellor_workflow.converted_state.include?("Investigation")
                @counsellor_workflow.add_to_set(converted_state: "Investigation")
              end
              @counsellor_workflow.converted if @counsellor_workflow.state != "converted"
              @converted_flag = true
              break
            else
              @counsellor_workflow.undo_converted if (@counsellor_workflow.state == "converted" && !@converted_flag)
            end
          end
        end
      end
    end
  end
end
