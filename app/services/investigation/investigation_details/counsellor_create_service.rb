class Investigation::InvestigationDetails::CounsellorCreateService
  def self.call(counsellor_record)
    user = User.find_by(id: counsellor_record.user_id.to_s)
    facility = Facility.find_by(id: counsellor_record.facility_id.to_s)
    patient = Patient.find_by(id: counsellor_record.patient_id.to_s)
    # OPHTHAL
    counsellor_record.ophthal_investigations.each do |ophthal_investigation|
      investigation_details = Investigation::InvestigationDetail.find_by(id: ophthal_investigation.detail_investigation_id)
      if investigation_details.present?
        options = {}
      else
        # NEW INVESTIGATION
        queue = Investigation::Queues::CreateService.call(counsellor_record.appointment_id.to_s, patient, "ophthal", user, facility, Time.current)

        investigation_details = Investigation::Ophthal.new
        custom = (false if ophthal_investigation.investigation_type == "OphthalmologyInvestigationData") || true

        options = { name: ophthal_investigation.investigationname, investigation_side: ophthal_investigation.investigationside, investigation_id: ophthal_investigation.investigation_id, investigation_full_code: ophthal_investigation.investigationfullcode, is_custom: custom, investigation_type: ophthal_investigation.investigation_type, requested_by: ophthal_investigation.entered_by_id, entered_by: ophthal_investigation.entered_by_id, entered_by_username: ophthal_investigation.entered_by, entered_at: ophthal_investigation.entered_datetime, entered_at_facility_id: ophthal_investigation.entered_at_facility_id, entered_at_facility_name: ophthal_investigation.entered_at_facility, advised_by: ophthal_investigation.advised_by_id, advised_by_username: ophthal_investigation.advised_by, advised_at: ophthal_investigation.advised_datetime, advised_at_facility_id: ophthal_investigation.advised_at_facility_id, advised_at_facility_name: ophthal_investigation.advised_at_facility, facility_id: counsellor_record.facility_id, organisation_id: counsellor_record.organisation_id, patient_id: counsellor_record.patient_id, appointment_id: counsellor_record.appointment_id, queue_id: queue.id, case_sheet_id: counsellor_record.case_sheet_id }
      end

      if investigation_details.present?
        if !ophthal_investigation.is_removed
          if investigation_details.state == "advised" || investigation_details.state == "counselled"
            options = options.merge({ counselled_by: ophthal_investigation.counselled_by_id, counselled_by_username: ophthal_investigation.counselled_by, counselled_at: ophthal_investigation.counselled_datetime, counselled_at_facility_id: ophthal_investigation.counselled_at_facility_id, counselled_at_facility_name: ophthal_investigation.counselled_at_facility })
            counselled = true if investigation_details.state == "advised"

            if ophthal_investigation.has_agreed && ophthal_investigation.payment_taken
              options = options.merge({ payment_done: true, collected_by: ophthal_investigation.payment_taken_by_id, collected_by_username: ophthal_investigation.payment_taken_by, collected_at: ophthal_investigation.payment_taken_datetime, collected_at_facility_id: ophthal_investigation.payment_taken_at_facility_id, collected_at_facility_name: ophthal_investigation.payment_taken_at_facility, removed_by: "", removed_by_username: "", removed_at: "", removed_at_facility_id: "", removed_at_facility_name: "", removing_reason: "", date_removed_at: "" })
              payment_taken = true
            elsif ophthal_investigation.has_declined
              options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", declined_by: ophthal_investigation.declined_by_id, declined_by_username: ophthal_investigation.declined_by, declined_at: ophthal_investigation.declined_datetime, declined_at_facility_id: ophthal_investigation.declined_at_facility_id, declined_at_facility_name: ophthal_investigation.declined_at_facility, date_declined_at: ophthal_investigation.declined_datetime })
              declined = true
            end
          elsif investigation_details.state == "declined"
            if ophthal_investigation.has_agreed
              options = options.merge({ declined_by: "", declined_by_username: "", declined_at: "", declined_at_facility_id: "", declined_at_facility_name: "", date_declined_at: "" })
              if ophthal_investigation.payment_taken
                options = options.merge({ payment_done: true, collected_by: ophthal_investigation.payment_taken_by_id, collected_by_username: ophthal_investigation.payment_taken_by, collected_at: ophthal_investigation.payment_taken_datetime, collected_at_facility_id: ophthal_investigation.payment_taken_at_facility_id, collected_at_facility_name: ophthal_investigation.payment_taken_at_facility })
                payment_taken = true
              end
              options = options.merge({ state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
            end
          elsif investigation_details.state == "payment_taken"
            if ophthal_investigation.has_declined
              options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", declined_by: ophthal_investigation.declined_by_id, declined_by_username: ophthal_investigation.declined_by, declined_at: ophthal_investigation.declined_datetime, declined_at_facility_id: ophthal_investigation.declined_at_facility_id, declined_at_facility_name: ophthal_investigation.declined_at_facility, date_declined_at: ophthal_investigation.declined_datetime })
              options = options.merge({ state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
              declined = true
            end
          end
        else
          options = options.merge({ removed_by: ophthal_investigation.removed_by_id, removed_by_username: ophthal_investigation.removed_by, removed_at: ophthal_investigation.removed_datetime, removed_at_facility_id: ophthal_investigation.removed_at_facility_id, removed_at_facility_name: ophthal_investigation.removed_at_facility, removing_reason: 'Patient Declined', date_removed_at: ophthal_investigation.removed_datetime })
          if investigation_details.state == "payment_taken"
            options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
          end
          removed = true
        end

        if investigation_details.try(:update, options)
          investigation_details.counselled if counselled == true
          investigation_details.payment_taken if payment_taken == true
          investigation_details.declined if declined == true
          investigation_details.removed if removed == true

          ophthal_investigation.update(detail_investigation_id: investigation_details.id)

          if queue.present?
            queue.update(appointment_date: investigation_details.advised_at, appointment_time: investigation_details.advised_at) if investigation_details.advised_at > queue.appointment_time
          end
        end
      end
    end

    # Laboratory
    counsellor_record.laboratory_investigations.each do |laboratory_investigation|
      puts "Entry Point #{laboratory_investigation.detail_investigation_id}"
      investigation_details = Investigation::InvestigationDetail.find_by(id: laboratory_investigation.detail_investigation_id)
      if investigation_details.present?
        puts "present inv lab"
        options = {}
      else
        puts "new inv lab"
        # NEW INVESTIGATION
        queue = Investigation::Queues::CreateService.call(counsellor_record.appointment_id.to_s, patient, "laboratory", user, facility, Time.current)

        investigation_details = Investigation::Laboratory.new
        custom = (false if laboratory_investigation.investigation_type == "LaboratoryInvestigationData") || true

        options = { name: laboratory_investigation.investigationname, loinc_class: laboratory_investigation.loinc_class, loinc_code: laboratory_investigation.loinc_code, investigation_id: laboratory_investigation.investigation_id, investigation_full_code: laboratory_investigation.investigationfullcode, is_custom: custom, investigation_type: laboratory_investigation.investigation_type, requested_by: laboratory_investigation.entered_by_id, entered_by: laboratory_investigation.entered_by_id, entered_by_username: laboratory_investigation.entered_by, entered_at: laboratory_investigation.entered_datetime, entered_at_facility_id: laboratory_investigation.entered_at_facility_id, entered_at_facility_name: laboratory_investigation.entered_at_facility, advised_by: laboratory_investigation.advised_by_id, advised_by_username: laboratory_investigation.advised_by, advised_at: laboratory_investigation.advised_datetime, advised_at_facility_id: laboratory_investigation.advised_at_facility_id, advised_at_facility_name: laboratory_investigation.advised_at_facility, facility_id: counsellor_record.facility_id, organisation_id: counsellor_record.organisation_id, patient_id: counsellor_record.patient_id, appointment_id: counsellor_record.appointment_id, queue_id: queue.id, case_sheet_id: counsellor_record.case_sheet_id }
      end

      if investigation_details.present?
        if !laboratory_investigation.is_removed
          if investigation_details.state == "advised" || investigation_details.state == "counselled"
            options = options.merge({ counselled_by: laboratory_investigation.counselled_by_id, counselled_by_username: laboratory_investigation.counselled_by, counselled_at: laboratory_investigation.counselled_datetime, counselled_at_facility_id: laboratory_investigation.counselled_at_facility_id, counselled_at_facility_name: laboratory_investigation.counselled_at_facility })
            counselled = true if investigation_details.state == "advised"

            if laboratory_investigation.has_agreed && laboratory_investigation.payment_taken
              options = options.merge({ payment_done: true, collected_by: laboratory_investigation.payment_taken_by_id, collected_by_username: laboratory_investigation.payment_taken_by, collected_at: laboratory_investigation.payment_taken_datetime, collected_at_facility_id: laboratory_investigation.payment_taken_at_facility_id, collected_at_facility_name: laboratory_investigation.payment_taken_at_facility, removed_by: "", removed_by_username: "", removed_at: "", removed_at_facility_id: "", removed_at_facility_name: "", removing_reason: "", date_removed_at: "" })
              payment_taken = true
            elsif laboratory_investigation.has_declined
              options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", declined_by: laboratory_investigation.declined_by_id, declined_by_username: laboratory_investigation.declined_by, declined_at: laboratory_investigation.declined_datetime, declined_at_facility_id: laboratory_investigation.declined_at_facility_id, declined_at_facility_name: laboratory_investigation.declined_at_facility, date_declined_at: laboratory_investigation.declined_datetime })
              declined = true
            end
          elsif investigation_details.state == "declined"
            if laboratory_investigation.has_agreed
              options = options.merge({ declined_by: "", declined_by_username: "", declined_at: "", declined_at_facility_id: "", declined_at_facility_name: "", date_declined_at: "" })
              if laboratory_investigation.payment_taken
                options = options.merge({ payment_done: true, collected_by: laboratory_investigation.payment_taken_by_id, collected_by_username: laboratory_investigation.payment_taken_by, collected_at: laboratory_investigation.payment_taken_datetime, collected_at_facility_id: laboratory_investigation.payment_taken_at_facility_id, collected_at_facility_name: laboratory_investigation.payment_taken_at_facility })
                payment_taken = true
              end
              options = options.merge({ state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
            end
          elsif investigation_details.state == "payment_taken"
            if laboratory_investigation.has_declined
              options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", declined_by: laboratory_investigation.declined_by_id, declined_by_username: laboratory_investigation.declined_by, declined_at: laboratory_investigation.declined_datetime, declined_at_facility_id: laboratory_investigation.declined_at_facility_id, declined_at_facility_name: laboratory_investigation.declined_at_facility, date_declined_at: laboratory_investigation.declined_datetime })
              options = options.merge({ state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
              declined = true
            end
          end
        else
          options = options.merge({ removed_by: laboratory_investigation.removed_by_id, removed_by_username: laboratory_investigation.removed_by, removed_at: laboratory_investigation.removed_datetime, removed_at_facility_id: laboratory_investigation.removed_at_facility_id, removed_at_facility_name: laboratory_investigation.removed_at_facility, removing_reason: 'Patient Declined', date_removed_at: laboratory_investigation.removed_datetime })
          if investigation_details.state == "payment_taken"
            options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
          end
          removed = true
        end

        if investigation_details.try(:update, options)
          investigation_details.counselled if counselled == true
          investigation_details.payment_taken if payment_taken == true
          investigation_details.declined if declined == true
          investigation_details.removed if removed == true

          puts "bef #{laboratory_investigation.detail_investigation_id}"
          laboratory_investigation.update!(detail_investigation_id: investigation_details.id)
          puts "aft #{laboratory_investigation.detail_investigation_id}"

          if queue.present?
            queue.update(appointment_date: investigation_details.advised_at, appointment_time: investigation_details.advised_at) if investigation_details.advised_at > queue.appointment_time
          end
        end
      end
    end

    # Radiology
    counsellor_record.radiology_investigations.each do |radiology_investigation|
      investigation_details = Investigation::InvestigationDetail.find_by(id: radiology_investigation.detail_investigation_id)
      if investigation_details.present?
        options = {}
      else
        # NEW INVESTIGATION
        queue = Investigation::Queues::CreateService.call(counsellor_record.appointment_id.to_s, patient, "radiology", user, facility, Time.current)

        investigation_details = Investigation::Radiology.new
        custom = (false if radiology_investigation.investigation_type == "RadiologyInvestigationData") || true

        options = { name: radiology_investigation.investigationname, investigation_id: radiology_investigation.investigation_id, investigation_full_code: radiology_investigation.investigationfullcode, has_laterality: "N", laterality: radiology_investigation.laterality, is_spine: "Y", loinc_code: radiology_investigation.loinccode, radiology_options: radiology_investigation.radiologyoptions, is_custom: custom, investigation_type: radiology_investigation.investigation_type, requested_by: radiology_investigation.entered_by_id, entered_by: radiology_investigation.entered_by_id, entered_by_username: radiology_investigation.entered_by, entered_at: radiology_investigation.entered_datetime, entered_at_facility_id: radiology_investigation.entered_at_facility_id, entered_at_facility_name: radiology_investigation.entered_at_facility, advised_by: radiology_investigation.advised_by_id, advised_by_username: radiology_investigation.advised_by, advised_at: radiology_investigation.advised_datetime, advised_at_facility_id: radiology_investigation.advised_at_facility_id, advised_at_facility_name: radiology_investigation.advised_at_facility, facility_id: counsellor_record.facility_id, organisation_id: counsellor_record.organisation_id, patient_id: counsellor_record.patient_id, appointment_id: counsellor_record.appointment_id, queue_id: queue.id, case_sheet_id: counsellor_record.case_sheet_id }
      end

      if investigation_details.present?
        if !radiology_investigation.is_removed
          if investigation_details.state == "advised" || investigation_details.state == "counselled"
            options = options.merge({ counselled_by: radiology_investigation.counselled_by_id, counselled_by_username: radiology_investigation.counselled_by, counselled_at: radiology_investigation.counselled_datetime, counselled_at_facility_id: radiology_investigation.counselled_at_facility_id, counselled_at_facility_name: radiology_investigation.counselled_at_facility })
            counselled = true  if investigation_details.state == "advised"

            if radiology_investigation.has_agreed && radiology_investigation.payment_taken
              options = options.merge({ payment_done: true, collected_by: radiology_investigation.payment_taken_by_id, collected_by_username: radiology_investigation.payment_taken_by, collected_at: radiology_investigation.payment_taken_datetime, collected_at_facility_id: radiology_investigation.payment_taken_at_facility_id, collected_at_facility_name: radiology_investigation.payment_taken_at_facility, removed_by: "", removed_by_username: "", removed_at: "", removed_at_facility_id: "", removed_at_facility_name: "", removing_reason: "", date_removed_at: "" })
              payment_taken = true
            elsif radiology_investigation.has_declined
              options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", declined_by: radiology_investigation.declined_by_id, declined_by_username: radiology_investigation.declined_by, declined_at: radiology_investigation.declined_datetime, declined_at_facility_id: radiology_investigation.declined_at_facility_id, declined_at_facility_name: radiology_investigation.declined_at_facility, date_declined_at: radiology_investigation.declined_datetime })
              declined = true
            end
          elsif investigation_details.state == "declined"
            if radiology_investigation.has_agreed
              options = options.merge({ declined_by: "", declined_by_username: "", declined_at: "", declined_at_facility_id: "", declined_at_facility_name: "", date_declined_at: "" })
              if radiology_investigation.payment_taken
                options = options.merge({ payment_done: true, collected_by: radiology_investigation.payment_taken_by_id, collected_by_username: radiology_investigation.payment_taken_by, collected_at: radiology_investigation.payment_taken_datetime, collected_at_facility_id: radiology_investigation.payment_taken_at_facility_id, collected_at_facility_name: radiology_investigation.payment_taken_at_facility })
                payment_taken = true
              end
              options = options.merge({ state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
            end
          elsif investigation_details.state == "payment_taken"
            if radiology_investigation.has_declined
              options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", declined_by: radiology_investigation.declined_by_id, declined_by_username: radiology_investigation.declined_by, declined_at: radiology_investigation.declined_datetime, declined_at_facility_id: radiology_investigation.declined_at_facility_id, declined_at_facility_name: radiology_investigation.declined_at_facility, date_declined_at: radiology_investigation.declined_datetime })
              options = options.merge({ state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
              declined = true
            end
          end
        else
          options = options.merge({ removed_by: radiology_investigation.removed_by_id, removed_by_username: radiology_investigation.removed_by, removed_at: radiology_investigation.removed_datetime, removed_at_facility_id: radiology_investigation.removed_at_facility_id, removed_at_facility_name: radiology_investigation.removed_at_facility, removing_reason: 'Patient Declined', date_removed_at: radiology_investigation.removed_datetime })
          if investigation_details.state == "payment_taken"
            options = options.merge({ payment_done: false, collected_by: "", collected_by_username: "", collected_at: "", collected_at_facility_id: "", collected_at_facility_name: "", state: investigation_details.previous_state.pop, previous_state: investigation_details.previous_state })
          end
          removed = true
        end

        if investigation_details.try(:update, options)
          investigation_details.counselled if counselled == true
          investigation_details.payment_taken if payment_taken == true
          investigation_details.declined if declined == true
          investigation_details.removed if removed == true

          radiology_investigation.update(detail_investigation_id: investigation_details.id)

          if queue.present?
            queue.update(appointment_date: investigation_details.advised_at, appointment_time: investigation_details.advised_at) if investigation_details.advised_at > queue.appointment_time
          end
        end
      end
    end
  end
end
