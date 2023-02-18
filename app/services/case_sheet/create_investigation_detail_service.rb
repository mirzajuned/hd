class CaseSheet::CreateInvestigationDetailService
  def self.call(_appointment, investigation, current_facility_id, current_user)
    current_facility = Facility.find_by(id: current_facility_id)
    case_sheet = CaseSheet.find_by(id: investigation.case_sheet_id)
    if case_sheet.present?
      counsellor_record = CounsellorRecord.find_by(patient_id: investigation.patient_id, created_at: Date.current.beginning_of_day..Date.current.end_of_day)

      @analytics_params = {}
      analytics_before_params_investigations(case_sheet)

      case_sheet_ophthal_investigations = case_sheet.ophthal_investigations.pluck(:detail_investigation_id).map(&:to_s)
      case_sheet_laboratory_investigations = case_sheet.laboratory_investigations.pluck(:detail_investigation_id).map(&:to_s)
      case_sheet_radiology_investigations = case_sheet.radiology_investigations.pluck(:detail_investigation_id).map(&:to_s)

      if counsellor_record.present?
        counsellor_record_ophthal_investigations = counsellor_record.ophthal_investigations.pluck(:detail_investigation_id).map(&:to_s)
        counsellor_record_laboratory_investigations = counsellor_record.laboratory_investigations.pluck(:detail_investigation_id).map(&:to_s)
        counsellor_record_radiology_investigations = counsellor_record.radiology_investigations.pluck(:detail_investigation_id).map(&:to_s)
      end

      if investigation._type == 'Investigation::Ophthal'
        new_ophthal_investigation = if case_sheet_ophthal_investigations.include?(investigation.id.to_s)
                                      case_sheet.ophthal_investigations.find_by(detail_investigation_id: investigation.id.to_s)
                                    else
                                      case_sheet.ophthal_investigations.new
                                    end
        ophthal_investigation_params(new_ophthal_investigation, investigation)

        if counsellor_record.present?
          if counsellor_record_ophthal_investigations.include?(investigation.id.to_s)
            new_counsellor_ophthal_investigation = counsellor_record.ophthal_investigations.find_by(detail_investigation_id: investigation.id.to_s)
          else
            new_counsellor_ophthal_investigation = counsellor_record.ophthal_investigations.new
          end
          ophthal_investigation_params(new_counsellor_ophthal_investigation, investigation)

          new_counsellor_ophthal_investigation.save

          new_ophthal_investigation[:counsellor_investigation_ids] = new_ophthal_investigation.counsellor_investigation_ids
          new_ophthal_investigation[:counsellor_investigation_ids][counsellor_record.id.to_s] = Hash[record_id: counsellor_record.id.to_s, investigation_id: new_counsellor_ophthal_investigation.id.to_s]
        end

        if new_ophthal_investigation.save
          Orders::Advised::CreateService.create_orders_from_ophthal_investigation(new_ophthal_investigation, case_sheet, current_facility)
        end
      end

      if investigation._type == 'Investigation::Laboratory'
        if case_sheet_laboratory_investigations.include?(investigation.id.to_s)
          new_laboratory_investigation = case_sheet.laboratory_investigations.find_by(detail_investigation_id: investigation.id.to_s)
        else
          new_laboratory_investigation = case_sheet.laboratory_investigations.new
        end
        laboratory_investigation_params(new_laboratory_investigation, investigation)

        if counsellor_record.present?
          if counsellor_record_laboratory_investigations.include?(investigation.id.to_s)
            new_counsellor_laboratory_investigation = counsellor_record.laboratory_investigations.find_by(detail_investigation_id: investigation.id.to_s)
          else
            new_counsellor_laboratory_investigation = counsellor_record.laboratory_investigations.new
          end
          laboratory_investigation_params(new_counsellor_laboratory_investigation, investigation)

          new_counsellor_laboratory_investigation.save

          new_laboratory_investigation[:counsellor_investigation_ids] = new_laboratory_investigation.counsellor_investigation_ids
          new_laboratory_investigation[:counsellor_investigation_ids][counsellor_record.id.to_s] = Hash[record_id: counsellor_record.id.to_s, investigation_id: new_counsellor_laboratory_investigation.id.to_s]
        end
        if new_laboratory_investigation.save
          Orders::Advised::CreateService.create_orders_from_laboratory_investigation(new_laboratory_investigation, case_sheet, current_facility)
        end
      end

      if investigation._type == 'Investigation::Radiology'
        if case_sheet_radiology_investigations.include?(investigation.id.to_s)
          new_radiology_investigation = case_sheet.radiology_investigations.find_by(detail_investigation_id: investigation.id.to_s)
        else
          new_radiology_investigation = case_sheet.radiology_investigations.new
        end
        radiology_investigation_params(new_radiology_investigation, investigation)

        if counsellor_record.present?
          if counsellor_record_radiology_investigations.include?(investigation.id.to_s)
            new_counsellor_radiology_investigation = counsellor_record.radiology_investigations.find_by(detail_investigation_id: investigation.id.to_s)
          else
            new_counsellor_radiology_investigation = counsellor_record.radiology_investigations.new
          end
          radiology_investigation_params(new_counsellor_radiology_investigation, investigation)

          new_counsellor_radiology_investigation.save

          new_radiology_investigation[:counsellor_investigation_ids] = new_radiology_investigation.counsellor_investigation_ids
          new_radiology_investigation[:counsellor_investigation_ids][counsellor_record.id.to_s] = Hash[record_id: counsellor_record.id.to_s, investigation_id: new_counsellor_radiology_investigation.id.to_s]
        end
        if new_radiology_investigation.save
          Orders::Advised::CreateService.create_orders_from_radiology_investigation(new_radiology_investigation, case_sheet, current_facility)
        end
      end

      analytics_after_params_investigations(case_sheet)
      Analytics::CreateService.call(@analytics_params.to_json, current_user.to_s, current_facility.id.to_s, 'clinical_data')
    end
  end

  private

  def self.ophthal_investigation_params(new_ophthal_investigation, ophthal_investigation)
    new_ophthal_investigation[:detail_investigation_id] = ophthal_investigation.id.to_s
    new_ophthal_investigation[:appointment_id] = ophthal_investigation.appointment_id
    new_ophthal_investigation[:investigationstage] = 'Advised'
    new_ophthal_investigation[:status] = 'Advised'
    new_ophthal_investigation[:investigationname] = ophthal_investigation.name
    new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
    new_ophthal_investigation[:investigationoriginalside] = new_ophthal_investigation[:investigationoriginalside] || ophthal_investigation.investigation_side
    new_ophthal_investigation[:investigationside] = ophthal_investigation.investigation_side
    new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigation_full_code
    new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type
    new_ophthal_investigation[:order_item_advised_id] = ophthal_investigation.order_item_advised_id.to_s

    if new_ophthal_investigation[:entered_by_id].blank?
      new_ophthal_investigation[:user_id] = ophthal_investigation.entered_by
      new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by
      new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by_username
      new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_at
      new_ophthal_investigation[:entered_from] = 'add_investigation_details'
      new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility_name
      new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id
    end

    new_ophthal_investigation[:is_advised] = true
    if new_ophthal_investigation[:advised_by_id].blank?
      new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by_username
      new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by
      new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_at
      new_ophthal_investigation[:advised_from] = 'add_investigation_details'
      new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility_name
      new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id
    end

    if ophthal_investigation.state == 'advised'
      new_ophthal_investigation[:counsellor_options_disabled] = false

      counselled_nil(new_ophthal_investigation)
      payment_taken_nil(new_ophthal_investigation)
      performed_nil(new_ophthal_investigation)
      declined_nil(new_ophthal_investigation)
      removed_nil(new_ophthal_investigation)
    end

    if ophthal_investigation.state == 'counselled'
      new_ophthal_investigation[:counsellor_options_disabled] = false
      new_ophthal_investigation[:is_counselled] = true
      new_ophthal_investigation[:investigationstage] = 'Counselled'
      new_ophthal_investigation[:counselled_by] = ophthal_investigation.counselled_by_username
      new_ophthal_investigation[:counselled_by_id] = ophthal_investigation.counselled_by
      new_ophthal_investigation[:counselled_datetime] = ophthal_investigation.counselled_at
      new_ophthal_investigation[:counselled_from] = 'add_investigation_details'
      new_ophthal_investigation[:counselled_at_facility] = ophthal_investigation.counselled_at_facility_name
      new_ophthal_investigation[:counselled_at_facility_id] = ophthal_investigation.counselled_at_facility_id
      new_ophthal_investigation[:status] = "Counselled"
      payment_taken_nil(new_ophthal_investigation)
      declined_nil(new_ophthal_investigation)
      removed_nil(new_ophthal_investigation)
    end

    if ophthal_investigation.state == 'payment_taken'
      new_ophthal_investigation[:counsellor_options_disabled] = false
      new_ophthal_investigation[:has_agreed] = true
      new_ophthal_investigation[:agreed_by] = ophthal_investigation.collected_by_username
      new_ophthal_investigation[:agreed_by_id] = ophthal_investigation.collected_by
      new_ophthal_investigation[:agreed_datetime] = ophthal_investigation.collected_at
      new_ophthal_investigation[:agreed_from] = 'add_investigation_details'
      new_ophthal_investigation[:agreed_at_facility] = ophthal_investigation.collected_at_facility_name
      new_ophthal_investigation[:agreed_at_facility_id] = ophthal_investigation.collected_at_facility_id

      new_ophthal_investigation[:investigationstage] = 'Payment Taken'
      new_ophthal_investigation[:status] = "Payment Taken"
      new_ophthal_investigation[:payment_taken] = true
      new_ophthal_investigation[:payment_taken_by] = ophthal_investigation.collected_by_username
      new_ophthal_investigation[:payment_taken_by_id] = ophthal_investigation.collected_by
      new_ophthal_investigation[:payment_taken_datetime] = ophthal_investigation.collected_at
      new_ophthal_investigation[:payment_taken_from] = 'add_investigation_details'
      new_ophthal_investigation[:payment_taken_at_facility] = ophthal_investigation.collected_at_facility_name
      new_ophthal_investigation[:payment_taken_at_facility_id] = ophthal_investigation.collected_at_facility_id

      sent_outside_nil(new_ophthal_investigation)
      test_started_nil(new_ophthal_investigation)
    end

    if ophthal_investigation.state == 'declined'
      new_ophthal_investigation[:counsellor_options_disabled] = false
      new_ophthal_investigation[:has_declined] = true
      new_ophthal_investigation[:investigationstage] = 'Declined'
      new_ophthal_investigation[:status] = 'Declined'
      new_ophthal_investigation[:declined_by] = ophthal_investigation.declined_by_username
      new_ophthal_investigation[:declined_by_id] = ophthal_investigation.declined_by
      new_ophthal_investigation[:declined_datetime] = ophthal_investigation.declined_at
      new_ophthal_investigation[:declined_from] = 'add_investigation_details'
      new_ophthal_investigation[:declined_at_facility] = ophthal_investigation.declined_at_facility_name
      new_ophthal_investigation[:declined_at_facility_id] = ophthal_investigation.declined_at_facility_id
    end

    if ophthal_investigation.state == 'removed'
      new_ophthal_investigation[:counsellor_options_disabled] = true
      new_ophthal_investigation[:is_removed] = true
      new_ophthal_investigation[:investigationstage] = 'Removed'
      new_ophthal_investigation[:status] = 'Cancelled'
      new_ophthal_investigation[:removed_by] = ophthal_investigation.removed_by_username
      new_ophthal_investigation[:removed_by_id] = ophthal_investigation.removed_by
      new_ophthal_investigation[:removed_datetime] = ophthal_investigation.removed_at
      new_ophthal_investigation[:removed_from] = 'add_investigation_details'
      new_ophthal_investigation[:removed_at_facility] = ophthal_investigation.removed_at_facility_name
      new_ophthal_investigation[:removed_at_facility_id] = ophthal_investigation.removed_at_facility_id
    end

    if ophthal_investigation.state == 'sent_outside'
      new_ophthal_investigation[:counsellor_options_disabled] = true
      new_ophthal_investigation[:sent_outside] = true
      new_ophthal_investigation[:investigationstage] = 'Sent Outside'
      new_ophthal_investigation[:sent_outside_by] = ophthal_investigation.sent_outside_by_username
      new_ophthal_investigation[:sent_outside_by_id] = ophthal_investigation.sent_outside_by
      new_ophthal_investigation[:sent_outside_datetime] = ophthal_investigation.sent_outside_at
      new_ophthal_investigation[:sent_outside_from] = 'add_investigation_details'
      new_ophthal_investigation[:sent_outside_at_facility] = ophthal_investigation.sent_outside_at_facility_name
      new_ophthal_investigation[:sent_outside_at_facility_id] = ophthal_investigation.sent_outside_at_facility_id

      performed_nil(new_ophthal_investigation)
    end

    if ophthal_investigation.state == 'test_started'
      new_ophthal_investigation[:counsellor_options_disabled] = true
      new_ophthal_investigation[:test_started] = true
      new_ophthal_investigation[:investigationstage] = 'Test Started'
      new_ophthal_investigation[:test_started_by] = ophthal_investigation.test_started_by_username
      new_ophthal_investigation[:test_started_by_id] = ophthal_investigation.test_started_by
      new_ophthal_investigation[:test_started_datetime] = ophthal_investigation.started_test_at
      new_ophthal_investigation[:test_started_from] = 'add_investigation_details'
      new_ophthal_investigation[:test_started_at_facility] = ophthal_investigation.started_test_at_facility_name
      new_ophthal_investigation[:test_started_at_facility_id] = ophthal_investigation.started_test_at_facility_id

      performed_nil(new_ophthal_investigation)
    end

    if ophthal_investigation.state == 'performed'
      new_ophthal_investigation[:counsellor_options_disabled] = true
      # if counselled counselled_by details else advised_by details
      new_ophthal_investigation[:is_converted] = true
      new_ophthal_investigation[:investigationstage] = 'Converted'
      new_ophthal_investigation[:status] = 'Performed'
      new_ophthal_investigation[:converted_by] = (ophthal_investigation.counselled_by_username if ophthal_investigation.counselled_by_username.present?) || ophthal_investigation.advised_by_username
      new_ophthal_investigation[:converted_by_id] = (ophthal_investigation.counselled_by if ophthal_investigation.counselled_by.present?) || ophthal_investigation.advised_by
      new_ophthal_investigation[:converted_datetime] = (ophthal_investigation.counselled_at if ophthal_investigation.counselled_at.present?) || ophthal_investigation.advised_at
      new_ophthal_investigation[:converted_from] = 'add_investigation_details'
      new_ophthal_investigation[:converted_at_facility] = (ophthal_investigation.counselled_at_facility_name if ophthal_investigation.counselled_at_facility_name.present?) || ophthal_investigation.advised_at_facility_name
      new_ophthal_investigation[:converted_at_facility_id] = (ophthal_investigation.counselled_at_facility_id if ophthal_investigation.counselled_at_facility_id.present?) || ophthal_investigation.advised_at_facility_id

      new_ophthal_investigation[:is_performed] = true
      new_ophthal_investigation[:investigationstage] = 'Performed'
      new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by_username
      new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by
      new_ophthal_investigation[:performed_datetime] = ophthal_investigation.performed_at
      new_ophthal_investigation[:performed_from] = 'add_investigation_details'
      new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility_name
      new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id
      if ophthal_investigation.performed_outside
        new_ophthal_investigation[:is_performed_outside] = true
        new_ophthal_investigation[:performed_outside_by] = ophthal_investigation.performed_outside_by
      end
    end

    if ophthal_investigation.state == 'template_created'
      new_ophthal_investigation[:counsellor_options_disabled] = true
      new_ophthal_investigation[:template_created] = true
      new_ophthal_investigation[:investigationstage] = 'Template Created'
      new_ophthal_investigation[:template_created_by] = ophthal_investigation.template_created_by_username
      new_ophthal_investigation[:template_created_by_id] = ophthal_investigation.template_created_by
      new_ophthal_investigation[:template_created_datetime] = ophthal_investigation.template_created_at
      new_ophthal_investigation[:template_created_from] = 'add_investigation_details'
      new_ophthal_investigation[:template_created_at_facility] = ophthal_investigation.template_created_at_facility_name
      new_ophthal_investigation[:template_created_at_facility_id] = ophthal_investigation.template_created_at_facility_id
    end

    if ophthal_investigation.state == 'reviewed'
      new_ophthal_investigation[:counsellor_options_disabled] = true
      new_ophthal_investigation[:is_reviewed] = true
      new_ophthal_investigation[:investigationstage] = 'Reviewed'
      new_ophthal_investigation[:reviewed_by] = ophthal_investigation.reviewed_by_username
      new_ophthal_investigation[:reviewed_by_id] = ophthal_investigation.reviewed_by
      new_ophthal_investigation[:reviewed_datetime] = ophthal_investigation.reviewed_at
      new_ophthal_investigation[:reviewed_from] = 'add_investigation_details'
      new_ophthal_investigation[:reviewed_at_facility] = ophthal_investigation.reviewed_at_facility_name
      new_ophthal_investigation[:reviewed_at_facility_id] = ophthal_investigation.reviewed_at_facility_id
    end

    investigation_template = EhrInvestigation::Record.find_by(investigation_advised_id: ophthal_investigation.id.to_s) || Investigation::Record.find_by(investigation_advised_id: ophthal_investigation.id.to_s)

    if investigation_template.present?
      new_ophthal_investigation[:investigation_val] = investigation_template.investigation_val
      new_ophthal_investigation[:investigation_comment] = investigation_template.investigation_comment
      new_ophthal_investigation[:doctors_remark] = investigation_template.doctors_remark
    end
  end

  def self.laboratory_investigation_params(new_laboratory_investigation, laboratory_investigation)
    new_laboratory_investigation[:detail_investigation_id] = laboratory_investigation.id.to_s
    new_laboratory_investigation[:appointment_id] = laboratory_investigation.appointment_id
    new_laboratory_investigation[:investigationstage] = 'Advised'
    new_laboratory_investigation[:status] = 'Advised'
    new_laboratory_investigation[:investigationname] = laboratory_investigation.name
    new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
    new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigation_full_code
    new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
    new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
    new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type
    new_laboratory_investigation[:order_item_advised_id] = laboratory_investigation.order_item_advised_id.to_s

    if new_laboratory_investigation[:entered_by_id].blank?
      new_laboratory_investigation[:user_id] = laboratory_investigation.entered_by
      new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by
      new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by_username
      new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_at
      new_laboratory_investigation[:entered_from] = 'add_investigation_details'
      new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility_name
      new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id
    end

    new_laboratory_investigation[:is_advised] = true
    if new_laboratory_investigation[:advised_by_id].blank?
      new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by_username
      new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by
      new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_at
      new_laboratory_investigation[:advised_from] = 'add_investigation_details'
      new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility_name
      new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id
    end

    if laboratory_investigation.state == 'advised'
      new_laboratory_investigation[:counsellor_options_disabled] = false

      counselled_nil(new_laboratory_investigation)
      payment_taken_nil(new_laboratory_investigation)
      performed_nil(new_laboratory_investigation)
      declined_nil(new_laboratory_investigation)
      removed_nil(new_laboratory_investigation)
    end

    if laboratory_investigation.state == 'counselled'
      new_laboratory_investigation[:counsellor_options_disabled] = false
      new_laboratory_investigation[:is_counselled] = true
      new_laboratory_investigation[:investigationstage] = 'Counselled'
      new_laboratory_investigation[:counselled_by] = laboratory_investigation.counselled_by_username
      new_laboratory_investigation[:counselled_by_id] = laboratory_investigation.counselled_by
      new_laboratory_investigation[:counselled_datetime] = laboratory_investigation.counselled_at
      new_laboratory_investigation[:counselled_from] = 'add_investigation_details'
      new_laboratory_investigation[:counselled_at_facility] = laboratory_investigation.counselled_at_facility_name
      new_laboratory_investigation[:counselled_at_facility_id] = laboratory_investigation.counselled_at_facility_id

      new_laboratory_investigation[:status] = "Counselled"
      payment_taken_nil(new_laboratory_investigation)
      declined_nil(new_laboratory_investigation)
      removed_nil(new_laboratory_investigation)
    end

    if laboratory_investigation.state == 'payment_taken'
      new_laboratory_investigation[:counsellor_options_disabled] = false
      new_laboratory_investigation[:has_agreed] = true
      new_laboratory_investigation[:agreed_by] = laboratory_investigation.collected_by_username
      new_laboratory_investigation[:agreed_by_id] = laboratory_investigation.collected_by
      new_laboratory_investigation[:agreed_datetime] = laboratory_investigation.collected_at
      new_laboratory_investigation[:agreed_from] = 'add_investigation_details'
      new_laboratory_investigation[:agreed_at_facility] = laboratory_investigation.collected_at_facility_name
      new_laboratory_investigation[:agreed_at_facility_id] = laboratory_investigation.collected_at_facility_id

      new_laboratory_investigation[:investigationstage] = 'Payment Taken'
      new_laboratory_investigation[:status] = 'Payment Taken'
      new_laboratory_investigation[:payment_taken] = true
      new_laboratory_investigation[:payment_taken_by] = laboratory_investigation.collected_by_username
      new_laboratory_investigation[:payment_taken_by_id] = laboratory_investigation.collected_by
      new_laboratory_investigation[:payment_taken_datetime] = laboratory_investigation.collected_at
      new_laboratory_investigation[:payment_taken_from] = 'add_investigation_details'
      new_laboratory_investigation[:payment_taken_at_facility] = laboratory_investigation.collected_at_facility_name
      new_laboratory_investigation[:payment_taken_at_facility_id] = laboratory_investigation.collected_at_facility_id

      sent_outside_nil(new_laboratory_investigation)
      test_started_nil(new_laboratory_investigation)
    end

    if laboratory_investigation.state == 'declined'
      new_laboratory_investigation[:counsellor_options_disabled] = false
      new_laboratory_investigation[:has_declined] = true
      new_laboratory_investigation[:investigationstage] = 'Declined'
      new_laboratory_investigation[:status] = 'Declined'
      new_laboratory_investigation[:declined_by] = laboratory_investigation.declined_by_username
      new_laboratory_investigation[:declined_by_id] = laboratory_investigation.declined_by
      new_laboratory_investigation[:declined_datetime] = laboratory_investigation.declined_at
      new_laboratory_investigation[:declined_from] = 'add_investigation_details'
      new_laboratory_investigation[:declined_at_facility] = laboratory_investigation.declined_at_facility_name
      new_laboratory_investigation[:declined_at_facility_id] = laboratory_investigation.declined_at_facility_id
    end

    if laboratory_investigation.state == 'removed'
      new_laboratory_investigation[:counsellor_options_disabled] = true
      new_laboratory_investigation[:is_removed] = true
      new_laboratory_investigation[:investigationstage] = 'Removed'
      new_laboratory_investigation[:status] = 'Cancelled'
      new_laboratory_investigation[:removed_by] = laboratory_investigation.removed_by_username
      new_laboratory_investigation[:removed_by_id] = laboratory_investigation.removed_by
      new_laboratory_investigation[:removed_datetime] = laboratory_investigation.removed_at
      new_laboratory_investigation[:removed_from] = 'add_investigation_details'
      new_laboratory_investigation[:removed_at_facility] = laboratory_investigation.removed_at_facility_name
      new_laboratory_investigation[:removed_at_facility_id] = laboratory_investigation.removed_at_facility_id
    end

    if laboratory_investigation.state == 'sent_outside'
      new_laboratory_investigation[:counsellor_options_disabled] = true
      new_laboratory_investigation[:sent_outside] = true
      new_laboratory_investigation[:investigationstage] = 'Sent Outside'
      new_laboratory_investigation[:sent_outside_by] = laboratory_investigation.sent_outside_by_username
      new_laboratory_investigation[:sent_outside_by_id] = laboratory_investigation.sent_outside_by
      new_laboratory_investigation[:sent_outside_datetime] = laboratory_investigation.sent_outside_at
      new_laboratory_investigation[:sent_outside_from] = 'add_investigation_details'
      new_laboratory_investigation[:sent_outside_at_facility] = laboratory_investigation.sent_outside_at_facility_name
      new_laboratory_investigation[:sent_outside_at_facility_id] = laboratory_investigation.sent_outside_at_facility_id

      performed_nil(new_laboratory_investigation)
    end

    if laboratory_investigation.state == 'test_started'
      new_laboratory_investigation[:counsellor_options_disabled] = true
      new_laboratory_investigation[:test_started] = true
      new_laboratory_investigation[:investigationstage] = 'Test Started'
      new_laboratory_investigation[:test_started_by] = laboratory_investigation.test_started_by_username
      new_laboratory_investigation[:test_started_by_id] = laboratory_investigation.test_started_by
      new_laboratory_investigation[:test_started_datetime] = laboratory_investigation.started_test_at
      new_laboratory_investigation[:test_started_from] = 'add_investigation_details'
      new_laboratory_investigation[:test_started_at_facility] = laboratory_investigation.started_test_at_facility_name
      new_laboratory_investigation[:test_started_at_facility_id] = laboratory_investigation.started_test_at_facility_id

      performed_nil(new_laboratory_investigation)
    end

    if laboratory_investigation.state == 'performed'
      new_laboratory_investigation[:counsellor_options_disabled] = true
      # if counselled counselled_by details else advised_by details
      new_laboratory_investigation[:is_converted] = true
      new_laboratory_investigation[:investigationstage] = 'Converted'
      new_laboratory_investigation[:converted_by] = (laboratory_investigation.counselled_by_username if laboratory_investigation.counselled_by_username.present?) || laboratory_investigation.advised_by_username
      new_laboratory_investigation[:converted_by_id] = (laboratory_investigation.counselled_by if laboratory_investigation.counselled_by.present?) || laboratory_investigation.advised_by
      new_laboratory_investigation[:converted_datetime] = (laboratory_investigation.counselled_at if laboratory_investigation.counselled_at.present?) || laboratory_investigation.advised_at
      new_laboratory_investigation[:converted_from] = 'add_investigation_details'
      new_laboratory_investigation[:converted_at_facility] = (laboratory_investigation.counselled_at_facility_name if laboratory_investigation.counselled_at_facility_name.present?) || laboratory_investigation.advised_at_facility_name
      new_laboratory_investigation[:converted_at_facility_id] = (laboratory_investigation.counselled_at_facility_id if laboratory_investigation.counselled_at_facility_id.present?) || laboratory_investigation.advised_at_facility_id

      new_laboratory_investigation[:is_performed] = true
      new_laboratory_investigation[:investigationstage] = 'Performed'
      new_laboratory_investigation[:status] = 'Performed'
      new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by_username
      new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by
      new_laboratory_investigation[:performed_datetime] = laboratory_investigation.performed_at
      new_laboratory_investigation[:performed_from] = 'add_investigation_details'
      new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility_name
      new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id
      if laboratory_investigation.performed_outside
        new_laboratory_investigation[:is_performed_outside] = true
        new_laboratory_investigation[:performed_outside_by] = laboratory_investigation.performed_outside_by
      end
    end

    if laboratory_investigation.state == 'template_created'
      new_laboratory_investigation[:counsellor_options_disabled] = true
      new_laboratory_investigation[:template_created] = true
      new_laboratory_investigation[:investigationstage] = 'Template Created'
      new_laboratory_investigation[:template_created_by] = laboratory_investigation.template_created_by_username
      new_laboratory_investigation[:template_created_by_id] = laboratory_investigation.template_created_by
      new_laboratory_investigation[:template_created_datetime] = laboratory_investigation.template_created_at
      new_laboratory_investigation[:template_created_from] = 'add_investigation_details'
      new_laboratory_investigation[:template_created_at_facility] = laboratory_investigation.template_created_at_facility_name
      new_laboratory_investigation[:template_created_at_facility_id] = laboratory_investigation.template_created_at_facility_id
    end

    if laboratory_investigation.state == 'reviewed'
      new_laboratory_investigation[:counsellor_options_disabled] = true
      new_laboratory_investigation[:is_reviewed] = true
      new_laboratory_investigation[:investigationstage] = 'Reviewed'
      new_laboratory_investigation[:reviewed_by] = laboratory_investigation.reviewed_by_username
      new_laboratory_investigation[:reviewed_by_id] = laboratory_investigation.reviewed_by
      new_laboratory_investigation[:reviewed_datetime] = laboratory_investigation.reviewed_at
      new_laboratory_investigation[:reviewed_from] = 'add_investigation_details'
      new_laboratory_investigation[:reviewed_at_facility] = laboratory_investigation.reviewed_at_facility_name
      new_laboratory_investigation[:reviewed_at_facility_id] = laboratory_investigation.reviewed_at_facility_id
    end

    investigation_template = EhrInvestigation::Record.find_by(investigation_advised_id: laboratory_investigation.id.to_s) || Investigation::Record.find_by(investigation_advised_id: laboratory_investigation.id.to_s)

    if investigation_template.present?
      new_laboratory_investigation[:specimen_type] = investigation_template.specimen_type
      new_laboratory_investigation[:specimen_date] = investigation_template.specimen_date

      new_laboratory_investigation[:investigation_val] = investigation_template.investigation_val
      new_laboratory_investigation[:normal_range] = investigation_template.normal_range
      new_laboratory_investigation[:investigation_comment] = investigation_template.investigation_comment
      new_laboratory_investigation[:doctors_remark] = investigation_template.doctors_remark

      if investigation_template.try(:panel_records).try(:count) > 0
        new_laboratory_investigation[:laboratory_panel_records] = investigation_template.panel_records.map(&:attributes)
      end
    end
  end

  def self.radiology_investigation_params(new_radiology_investigation, radiology_investigation)
    new_radiology_investigation[:detail_investigation_id] = radiology_investigation.id.to_s
    new_radiology_investigation[:appointment_id] = radiology_investigation.appointment_id
    new_radiology_investigation[:investigationstage] = 'Advised'
    new_radiology_investigation[:status] = 'Advised'
    new_radiology_investigation[:investigationname] = radiology_investigation.name
    new_radiology_investigation[:investigation_id] = radiology_investigation.investigation_id
    new_radiology_investigation[:investigationfullcode] = radiology_investigation.investigation_full_code
    new_radiology_investigation[:is_spine] = radiology_investigation.is_spine
    new_radiology_investigation[:laterality] = radiology_investigation.laterality
    new_radiology_investigation[:haslaterality] = radiology_investigation.has_laterality
    new_radiology_investigation[:radiologyoptions] = radiology_investigation.radiology_options
    new_radiology_investigation[:investigation_type] = radiology_investigation.investigation_type
    new_radiology_investigation[:order_item_advised_id] = radiology_investigation.order_item_advised_id.to_s
    new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_at

    if new_radiology_investigation[:entered_by_id].blank?
      new_radiology_investigation[:user_id] = radiology_investigation.entered_by
      new_radiology_investigation[:entered_by_id] = radiology_investigation.entered_by
      new_radiology_investigation[:entered_by] = radiology_investigation.entered_by_username
      new_radiology_investigation[:entered_datetime] = radiology_investigation.entered_at
      new_radiology_investigation[:entered_from] = 'add_investigation_details'
      new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility_name
      new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id
    end

    new_radiology_investigation[:is_advised] = true
    if new_radiology_investigation[:advised_by_id].blank?
      new_radiology_investigation[:advised_by] = radiology_investigation.advised_by_username
      new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by
      new_radiology_investigation[:advised_from] = 'add_investigation_details'
      new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility_name
      new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id
    end

    if radiology_investigation.state == 'advised'
      new_radiology_investigation[:counsellor_options_disabled] = false

      counselled_nil(new_radiology_investigation)
      payment_taken_nil(new_radiology_investigation)
      performed_nil(new_radiology_investigation)
      declined_nil(new_radiology_investigation)
      removed_nil(new_radiology_investigation)
    end

    if radiology_investigation.state == 'counselled'
      new_radiology_investigation[:counsellor_options_disabled] = false
      new_radiology_investigation[:is_counselled] = true
      new_radiology_investigation[:investigationstage] = 'Counselled'
      new_radiology_investigation[:counselled_by] = radiology_investigation.counselled_by_username
      new_radiology_investigation[:counselled_by_id] = radiology_investigation.counselled_by
      new_radiology_investigation[:counselled_datetime] = radiology_investigation.counselled_at
      new_radiology_investigation[:counselled_from] = 'add_investigation_details'
      new_radiology_investigation[:counselled_at_facility] = radiology_investigation.counselled_at_facility_name
      new_radiology_investigation[:counselled_at_facility_id] = radiology_investigation.counselled_at_facility_id

      new_radiology_investigation[:status] = 'Counselled'
      payment_taken_nil(new_radiology_investigation)
      declined_nil(new_radiology_investigation)
      removed_nil(new_radiology_investigation)
    end

    if radiology_investigation.state == 'payment_taken'
      new_radiology_investigation[:counsellor_options_disabled] = false
      new_radiology_investigation[:has_agreed] = true
      new_radiology_investigation[:agreed_by] = radiology_investigation.collected_by_username
      new_radiology_investigation[:agreed_by_id] = radiology_investigation.collected_by
      new_radiology_investigation[:agreed_datetime] = radiology_investigation.collected_at
      new_radiology_investigation[:agreed_from] = 'add_investigation_details'
      new_radiology_investigation[:agreed_at_facility] = radiology_investigation.collected_at_facility_name
      new_radiology_investigation[:agreed_at_facility_id] = radiology_investigation.collected_at_facility_id

      new_radiology_investigation[:investigationstage] = 'Payment Taken'
      new_radiology_investigation[:status] = 'Payment Taken'
      new_radiology_investigation[:payment_taken] = true
      new_radiology_investigation[:payment_taken_by] = radiology_investigation.collected_by_username
      new_radiology_investigation[:payment_taken_by_id] = radiology_investigation.collected_by
      new_radiology_investigation[:payment_taken_datetime] = radiology_investigation.collected_at
      new_radiology_investigation[:payment_taken_from] = 'add_investigation_details'
      new_radiology_investigation[:payment_taken_at_facility] = radiology_investigation.collected_at_facility_name
      new_radiology_investigation[:payment_taken_at_facility_id] = radiology_investigation.collected_at_facility_id

      sent_outside_nil(new_radiology_investigation)
      test_started_nil(new_radiology_investigation)
    end

    if radiology_investigation.state == 'declined'
      new_radiology_investigation[:counsellor_options_disabled] = false
      new_radiology_investigation[:has_declined] = true
      new_radiology_investigation[:investigationstage] = 'Declined'
      new_radiology_investigation[:status] = 'Declined'
      new_radiology_investigation[:declined_by] = radiology_investigation.declined_by_username
      new_radiology_investigation[:declined_by_id] = radiology_investigation.declined_by
      new_radiology_investigation[:declined_datetime] = radiology_investigation.declined_at
      new_radiology_investigation[:declined_from] = 'add_investigation_details'
      new_radiology_investigation[:declined_at_facility] = radiology_investigation.declined_at_facility_name
      new_radiology_investigation[:declined_at_facility_id] = radiology_investigation.declined_at_facility_id
    end

    if radiology_investigation.state == 'removed'
      new_radiology_investigation[:counsellor_options_disabled] = true
      new_radiology_investigation[:is_removed] = true
      new_radiology_investigation[:investigationstage] = 'Removed'
      new_radiology_investigation[:status] = 'Cancelled'
      new_radiology_investigation[:removed_by] = radiology_investigation.removed_by_username
      new_radiology_investigation[:removed_by_id] = radiology_investigation.removed_by
      new_radiology_investigation[:removed_datetime] = radiology_investigation.removed_at
      new_radiology_investigation[:removed_from] = 'add_investigation_details'
      new_radiology_investigation[:removed_at_facility] = radiology_investigation.removed_at_facility_name
      new_radiology_investigation[:removed_at_facility_id] = radiology_investigation.removed_at_facility_id
    end

    if radiology_investigation.state == 'sent_outside'
      new_radiology_investigation[:counsellor_options_disabled] = true
      new_radiology_investigation[:sent_outside] = true
      new_radiology_investigation[:investigationstage] = 'Sent Outside'
      new_radiology_investigation[:sent_outside_by] = radiology_investigation.sent_outside_by_username
      new_radiology_investigation[:sent_outside_by_id] = radiology_investigation.sent_outside_by
      new_radiology_investigation[:sent_outside_datetime] = radiology_investigation.sent_outside_at
      new_radiology_investigation[:sent_outside_from] = 'add_investigation_details'
      new_radiology_investigation[:sent_outside_at_facility] = radiology_investigation.sent_outside_at_facility_name
      new_radiology_investigation[:sent_outside_at_facility_id] = radiology_investigation.sent_outside_at_facility_id

      performed_nil(new_radiology_investigation)
    end

    if radiology_investigation.state == 'test_started'
      new_radiology_investigation[:counsellor_options_disabled] = true
      new_radiology_investigation[:test_started] = true
      new_radiology_investigation[:investigationstage] = 'Test Started'
      new_radiology_investigation[:test_started_by] = radiology_investigation.test_started_by_username
      new_radiology_investigation[:test_started_by_id] = radiology_investigation.test_started_by
      new_radiology_investigation[:test_started_datetime] = radiology_investigation.started_test_at
      new_radiology_investigation[:test_started_from] = 'add_investigation_details'
      new_radiology_investigation[:test_started_at_facility] = radiology_investigation.started_test_at_facility_name
      new_radiology_investigation[:test_started_at_facility_id] = radiology_investigation.started_test_at_facility_id

      performed_nil(new_radiology_investigation)
    end

    if radiology_investigation.state == 'performed'
      new_radiology_investigation[:counsellor_options_disabled] = true
      # if counselled counselled_by details else advised_by details
      new_radiology_investigation[:is_converted] = true
      new_radiology_investigation[:investigationstage] = 'Converted'
      new_radiology_investigation[:converted_by] = (radiology_investigation.counselled_by_username if radiology_investigation.counselled_by_username.present?) || radiology_investigation.advised_by_username
      new_radiology_investigation[:converted_by_id] = (radiology_investigation.counselled_by if radiology_investigation.counselled_by.present?) || radiology_investigation.advised_by
      new_radiology_investigation[:converted_datetime] = (radiology_investigation.counselled_at if radiology_investigation.counselled_at.present?) || radiology_investigation.advised_at
      new_radiology_investigation[:converted_from] = 'add_investigation_details'
      new_radiology_investigation[:converted_at_facility] = (radiology_investigation.counselled_at_facility_name if radiology_investigation.counselled_at_facility_name.present?) || radiology_investigation.advised_at_facility_name
      new_radiology_investigation[:converted_at_facility_id] = (radiology_investigation.counselled_at_facility_id if radiology_investigation.counselled_at_facility_id.present?) || radiology_investigation.advised_at_facility_id

      new_radiology_investigation[:is_performed] = true
      new_radiology_investigation[:investigationstage] = 'Performed'
      new_radiology_investigation[:status] = 'Performed'
      new_radiology_investigation[:performed_by] = radiology_investigation.performed_by_username
      new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by
      new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_at
      new_radiology_investigation[:performed_from] = 'add_investigation_details'
      new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility_name
      new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id
      if radiology_investigation.performed_outside
        new_radiology_investigation[:is_performed_outside] = true
        new_radiology_investigation[:performed_outside_by] = radiology_investigation.performed_outside_by
      end
    end

    if radiology_investigation.state == 'template_created'
      new_radiology_investigation[:counsellor_options_disabled] = true
      new_radiology_investigation[:template_created] = true
      new_radiology_investigation[:investigationstage] = 'Template Created'
      new_radiology_investigation[:template_created_by] = radiology_investigation.template_created_by_username
      new_radiology_investigation[:template_created_by_id] = radiology_investigation.template_created_by
      new_radiology_investigation[:template_created_datetime] = radiology_investigation.template_created_at
      new_radiology_investigation[:template_created_from] = 'add_investigation_details'
      new_radiology_investigation[:template_created_at_facility] = radiology_investigation.template_created_at_facility_name
      new_radiology_investigation[:template_created_at_facility_id] = radiology_investigation.template_created_at_facility_id
    end

    if radiology_investigation.state == 'reviewed'
      new_radiology_investigation[:counsellor_options_disabled] = true
      new_radiology_investigation[:is_reviewed] = true
      new_radiology_investigation[:investigationstage] = 'Reviewed'
      new_radiology_investigation[:reviewed_by] = radiology_investigation.reviewed_by_username
      new_radiology_investigation[:reviewed_by_id] = radiology_investigation.reviewed_by
      new_radiology_investigation[:reviewed_datetime] = radiology_investigation.reviewed_at
      new_radiology_investigation[:reviewed_from] = 'add_investigation_details'
      new_radiology_investigation[:reviewed_at_facility] = radiology_investigation.reviewed_at_facility_name
      new_radiology_investigation[:reviewed_at_facility_id] = radiology_investigation.reviewed_at_facility_id
    end

    investigation_template = EhrInvestigation::Record.find_by(investigation_advised_id: radiology_investigation.id.to_s) || Investigation::Record.find_by(investigation_advised_id: radiology_investigation.id.to_s)

    if investigation_template.present?
      new_radiology_investigation[:investigation_val] = investigation_template.investigation_val
      new_radiology_investigation[:investigation_comment] = investigation_template.investigation_comment
      new_radiology_investigation[:doctors_remark] = investigation_template.doctors_remark
    end
  end

  def self.counselled_nil(investigation_params)
    investigation_params[:is_counselled] = false
    investigation_params[:counselled_by] = nil
    investigation_params[:counselled_by_id] = nil
    investigation_params[:counselled_datetime] = nil
    investigation_params[:counselled_from] = nil
    investigation_params[:counselled_at_facility] = nil
    investigation_params[:counselled_at_facility_id] = nil
  end

  def self.payment_taken_nil(investigation_params)
    investigation_params[:has_agreed] = false
    investigation_params[:agreed_by] = nil
    investigation_params[:agreed_by_id] = nil
    investigation_params[:agreed_datetime] = nil
    investigation_params[:agreed_from] = nil
    investigation_params[:agreed_at_facility] = nil
    investigation_params[:agreed_at_facility_id] = nil

    investigation_params[:payment_taken] = false
    investigation_params[:payment_taken_by] = nil
    investigation_params[:payment_taken_by_id] = nil
    investigation_params[:payment_taken_datetime] = nil
    investigation_params[:payment_taken_from] = nil
    investigation_params[:payment_taken_at_facility] = nil
    investigation_params[:payment_taken_at_facility_id] = nil
  end

  def self.declined_nil(investigation_params)
    investigation_params[:has_declined] = false
    investigation_params[:declined_by] = nil
    investigation_params[:declined_by_id] = nil
    investigation_params[:declined_datetime] = nil
    investigation_params[:declined_from] = nil
    investigation_params[:declined_at_facility] = nil
    investigation_params[:declined_at_facility_id] = nil
  end

  def self.removed_nil(investigation_params)
    investigation_params[:is_removed] = false
    investigation_params[:removed_by] = nil
    investigation_params[:removed_by_id] = nil
    investigation_params[:removed_datetime] = nil
    investigation_params[:removed_from] = nil
    investigation_params[:removed_at_facility] = nil
    investigation_params[:removed_at_facility_id] = nil
  end

  def self.sent_outside_nil(investigation_params)
    investigation_params[:sent_outside] = false
    investigation_params[:sent_outside_by] = nil
    investigation_params[:sent_outside_by_id] = nil
    investigation_params[:sent_outside_datetime] = nil
    investigation_params[:sent_outside_from] = nil
    investigation_params[:sent_outside_at_facility] = nil
    investigation_params[:sent_outside_at_facility_id] = nil
  end

  def self.test_started_nil(investigation_params)
    investigation_params[:test_started] = false
    investigation_params[:test_started_by] = nil
    investigation_params[:test_started_by_id] = nil
    investigation_params[:test_started_datetime] = nil
    investigation_params[:test_started_from] = nil
    investigation_params[:test_started_at_facility] = nil
    investigation_params[:test_started_at_facility_id] = nil
  end

  def self.performed_nil(investigation_params)
    investigation_params[:is_performed] = false
    investigation_params[:performed_by] = nil
    investigation_params[:performed_by_id] = nil
    investigation_params[:performed_datetime] = nil
    investigation_params[:performed_from] = nil
    investigation_params[:performed_at_facility] = nil
    investigation_params[:performed_at_facility_id] = nil
  end

  def self.analytics_before_params_investigations(case_sheet)
    analytics_case_sheet = CaseSheet.find_by(id: case_sheet.id) # done intentionally, data was getting updated as of after save method

    @analytics_params['before_save_patient_age'] = analytics_case_sheet.patient_age
    @analytics_params['before_save_patient_gender'] = analytics_case_sheet.patient_gender
    @analytics_params['before_save_diagnosis'] = analytics_case_sheet.diagnoses.to_a
    @analytics_params['before_save_procedure'] = analytics_case_sheet.procedures.to_a
    @analytics_params['before_save_ophthal_investigations'] = analytics_case_sheet.ophthal_investigations.to_a
    @analytics_params['before_save_radiology_investigations'] = analytics_case_sheet.radiology_investigations.to_a
    @analytics_params['before_save_laboratory_investigations'] = analytics_case_sheet.laboratory_investigations.to_a
  end

  def self.analytics_after_params_investigations(case_sheet)
    patient = Patient.find_by(id: case_sheet.patient_id)

    options = {}
    options = options.merge(patient_gender: patient.gender) if case_sheet.patient_gender != patient.gender
    options = options.merge(patient_age: "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}") if (case_sheet.patient_age.present? && case_sheet.patient_age.split('/')[2] != patient.dob_year) || case_sheet.patient_age.nil?
    case_sheet.update(options)

    @analytics_params['data_from'] = 'investigation_details'
    @analytics_params['case_sheet_id'] = case_sheet.id
    @analytics_params['after_save_patient_age'] = case_sheet.patient_age
    @analytics_params['after_save_patient_gender'] = case_sheet.patient_gender
    @analytics_params['after_save_diagnosis'] = case_sheet.diagnoses
    @analytics_params['after_save_procedure'] = case_sheet.procedures
    @analytics_params['after_save_ophthal_investigations'] = case_sheet.ophthal_investigations
    @analytics_params['after_save_radiology_investigations'] = case_sheet.radiology_investigations
    @analytics_params['after_save_laboratory_investigations'] = case_sheet.laboratory_investigations
  end
end
