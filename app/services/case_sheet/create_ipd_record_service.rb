class CaseSheet::CreateIpdRecordService
  def self.call(patient, record, current_user, case_sheet_params)
    case_sheet = CaseSheet.find_by(id: record.case_sheet_id)

    if case_sheet.present?

      @analytics_params = {}
      analytics_before_params_ipd_record(case_sheet)

      ipd_record_ids = case_sheet.ipd_record_ids
      ipd_record_ids << record.id.to_s

      case_sheet[:ipd_record_ids] = ipd_record_ids.uniq

      case_sheet[:case_switchable_ipd] = case_sheet.case_switchable_ipd
      case_sheet[:case_switchable_ipd][record.admission_id.to_s] = Hash[case_switchable: false]

      case_sheet[:case_name] = (case_sheet_params[:case_name] if case_sheet_params.present?) || case_sheet.case_name || nil

      case_sheet[:free_form_histories] = case_sheet.free_form_histories
      case_sheet[:free_form_examinations] = case_sheet.free_form_examinations
      case_sheet[:free_form_diagnoses] = case_sheet.free_form_diagnoses
      case_sheet[:free_form_procedures] = case_sheet.free_form_procedures
      case_sheet[:free_form_complications] = case_sheet.free_form_complications
      case_sheet[:free_form_investigations] = case_sheet.free_form_investigations

      if case_sheet_params.present?
        @admitting_doctor = User.find_by(id: record.doctor_id)
        @admitting_facility = Facility.find_by(id: record.facility_id)

        options = { record_id: record.id.to_s, record_type: 'ipd_record', consultant_id: record.doctor_id.to_s,
                    consultant_name: @admitting_doctor.fullname, date: record.updated_at }

        # unless case_sheet_params[:free_history_text].blank?
        case_sheet[:free_form_histories][record.id.to_s] = options.merge(content: case_sheet_params[:free_history_text])
        # end
        # unless case_sheet_params[:free_examination_text].blank?
        case_sheet[:free_form_examinations][record.id.to_s] = options.merge(content: case_sheet_params[:free_examination_text])
        # end
        # unless case_sheet_params[:free_diagnosis_text].blank?
        case_sheet[:free_form_diagnoses][record.id.to_s] = options.merge(content: case_sheet_params[:free_diagnosis_text])
        # end
        # unless case_sheet_params[:free_procedure_text].blank?
        case_sheet[:free_form_procedures][record.id.to_s] = options.merge(content: case_sheet_params[:free_procedure_text])
        case_sheet[:free_form_complications][record.id.to_s] = options.merge(content: case_sheet_params[:free_complication_text])
        # end
        unless case_sheet_params[:free_investigation_text].blank?
          case_sheet[:free_form_investigations][record.id.to_s] = options.merge(content: case_sheet_params[:free_investigation_text])
        end

        # CaseSheet Diagnosis

        # Destroy Removed Diagnosis before creating new so new doesnt get destroyed
        if case_sheet_params[:diagnoses].present?
          clinical_diagnosis_ids = case_sheet_params[:diagnoses].to_unsafe_h.map { |k, v| v[:id] }
        else
          clinical_diagnosis_ids = []
        end

        case_sheet.diagnoses.where(ipd_record_id: record.id.to_s).each do |diagnosis|
          if diagnosis.advised_from != "opd_record" && diagnosis.advised_from != "counsellor_record"
            unless clinical_diagnosis_ids.include?(diagnosis.id.to_s)
              diagnosis.destroy
            end
          end
        end

        if case_sheet_params[:diagnoses].present?
          case_sheet_params[:diagnoses].each do |k, diagnosis|
            case_sheet_diagnosis = (case_sheet.diagnoses.find_by(id: diagnosis[:id]) if diagnosis[:id].present?) || nil
            if case_sheet_diagnosis.present?
              new_diagnosis = case_sheet_diagnosis
            else
              new_diagnosis = case_sheet.diagnoses.new
            end
            if new_diagnosis.present?
              diagnosis_params(new_diagnosis, record, diagnosis)

              new_diagnosis.save
            end
          end
        end

        # Destroy Removed Procedure before creating new so new doesnt get destroyed
        if case_sheet_params[:procedures].present?
          clinical_procedure_ids = case_sheet_params[:procedures].to_unsafe_h.map { |k, v| v[:id] }
        else
          clinical_procedure_ids = []
        end

        case_sheet.procedures.where(ipd_record_id: record.id.to_s).each do |procedure|
          if procedure.advised_from != "opd_record" && procedure.advised_from != "counsellor_record"
            unless procedure.is_performed
              unless clinical_procedure_ids.include?(procedure.id.to_s)
                procedure.destroy
              end
            end
          end
        end

        # CaseSheet Procedure
        if case_sheet_params[:procedures].present?
          case_sheet_params[:procedures].each do |k, procedure|
            case_sheet_procedure = (case_sheet.procedures.find_by(id: procedure[:id]) if procedure[:id].present?) || nil
            if case_sheet_procedure.present?
              new_procedure = case_sheet_procedure
            else
              new_procedure = case_sheet.procedures.new
            end
            if new_procedure.present?
              procedure_params(new_procedure, record, procedure)
              new_procedure[:procedurestage] = "Scheduled"
              new_procedure.save
              procedure_order_status_params(new_procedure, record, new_procedure.try(:procedureside))
            end
          end
        end 

        # CaseSheet Investigation
        case_sheet.ophthal_investigations.update_all(ipd_record_id: record.id.to_s, admission_id: record.admission_id)
        case_sheet.radiology_investigations.update_all(ipd_record_id: record.id.to_s, admission_id: record.admission_id)
        case_sheet.laboratory_investigations.update_all(ipd_record_id: record.id.to_s, admission_id: record.admission_id)
      end

      # Case not Switchable if OpdRecord Present in Case
      opd_records = OpdRecord.where(:id.in => case_sheet.opd_record_ids)
      opd_records.each do |opd_record|
        case_sheet[:case_switchable_opd] = case_sheet.case_switchable_opd
        case_sheet[:case_switchable_opd][opd_record.appointmentid.to_s] = Hash[case_switchable: false]
      end

      if case_sheet.save
        # OrderJobs::AdvisedJob.perform_later(case_sheet.id.to_s, current_user.id.to_s, record.facility_id.to_s)
        record.update(case_sheet_id: case_sheet.id)

        analytics_after_params_ipd_record(case_sheet)
        Analytics::CreateService.call(@analytics_params.to_json, record.doctor_id.to_s, record.facility_id.to_s, "clinical_data")
      end
    end
  end

  private

  def self.procedure_order_status_params(case_sheet_record_procedure, record, side)
    # organisation = Organisation.find_by(id: record.try(:organisation_id))
    # organisations_setting = organisation.try(:organisations_setting)
    # advise_order_rule = organisations_setting.try(:active_advise_order_rule).to_s

    case_sheet = CaseSheet.find_by(id: record.try(:case_sheet_id))

    case_sheet_existing_procedures = case_sheet.procedures.where(procedurefullcode: case_sheet_record_procedure.procedurefullcode, procedureside: side, :order_status.ne => "closed")

    case_sheet_remaining_procedures = case_sheet_existing_procedures.where(:id.ne => case_sheet_record_procedure.id)
    case_sheet_remaining_procedures.update_all(order_status: "closed")
    active_case_sheet_procedure = case_sheet_record_procedure
    active_case_sheet_procedure.update(order_status: "processing")


    remaining_order_advised = Order::Advised.where(:display_id.in => case_sheet_remaining_procedures.to_a.pluck(:order_display_id), patient_id: case_sheet.try(:patient_id))
    remaining_order_advised.update_all(active: false, status: 'Cancelled')

    procedure_attributes = active_case_sheet_procedure.attributes.except(:_id)
    active_order_advised = Order::Advised.find_by(order_item_advised_id: active_case_sheet_procedure.order_item_advised_id.to_s, procedureside: active_case_sheet_procedure.procedureside)


    if active_order_advised
      active_order_advised.assign_attributes(procedure_attributes)
      Orders::Trails::CreateService.call('Scheduled', active_order_advised)
      active_order_advised.update(status: "Scheduled")
    else
      active_order_advised = Order::Advised.new(procedure_attributes)
      active_order_advised.assign_attributes(display_id: CommonHelper.get_procedure_order_identifier(record.organisation_id),
                                             organisation_id: record.try(:organisation_id), facility_id: record.try(:facility_id),
                                             patient_id: case_sheet.try(:patient_id), case_sheet_id: case_sheet.id,
                                             status: 'Scheduled', active: true)
    end
    active_order_advised.quantity = 1
    active_order_advised.active = true
    active_order_advised.type = 'procedures'
    active_order_advised.save
    if active_order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', active_order_advised)
      Orders::Trails::CreateService.call('Scheduled', active_order_advised)
    end
    active_case_sheet_procedure.update(order_advised_id: active_order_advised.id.to_s, order_display_id: active_order_advised.display_id)

  end

  def self.diagnosis_params(new_diagnosis, record, diagnosis)
    new_diagnosis[:flow_in_ipd] = diagnosis[:flow_in_ipd]
    new_diagnosis[:diagnosisname] = diagnosis[:diagnosisname]
    new_diagnosis[:diagnosisoriginalname] = diagnosis[:diagnosisoriginalname]
    new_diagnosis[:icddiagnosiscode] = diagnosis[:icddiagnosiscode]
    new_diagnosis[:saperatedicddiagnosiscode] = diagnosis[:saperatedicddiagnosiscode]
    new_diagnosis[:icddiagnosiscodelength] = diagnosis[:icddiagnosiscodelength]
    new_diagnosis[:icd_type] = diagnosis[:icd_type]
    new_diagnosis[:diagnosis_comment] = diagnosis[:diagnosis_comment]
    new_diagnosis[:users_comment] = diagnosis[:users_comment]
    new_diagnosis[:user_id] = diagnosis[:user_id]

    # if diagnosis[:entered_from].nil? || diagnosis[:entered_from] == "ipd_record"
    new_diagnosis[:ipd_record_id] = record.id.to_s
    new_diagnosis[:admission_id] = new_diagnosis.admission_id || record.admission_id
    # end
    if diagnosis[:entered_from].nil? || diagnosis[:entered_from] == "ipd_record"
      new_diagnosis[:consultant_id] = @admitting_doctor.id
      new_diagnosis[:consultant_name] = @admitting_doctor.fullname
    end

    new_diagnosis[:entered_by] = diagnosis[:entered_by]
    new_diagnosis[:entered_by_id] = diagnosis[:entered_by_id]
    new_diagnosis[:entered_datetime] = diagnosis[:entered_datetime]
    new_diagnosis[:entered_from] = diagnosis[:entered_from] || "ipd_record"
    new_diagnosis[:entered_at_facility] = diagnosis[:entered_at_facility]
    new_diagnosis[:entered_at_facility_id] = diagnosis[:entered_at_facility_id]

    new_diagnosis[:is_advised] = true
    new_diagnosis[:advised_by] = diagnosis[:advised_by] || @admitting_doctor.fullname
    new_diagnosis[:advised_by_id] = diagnosis[:advised_by_id] || @admitting_doctor.id
    new_diagnosis[:advised_datetime] = diagnosis[:advised_datetime] || diagnosis[:entered_datetime] || Time.current
    new_diagnosis[:advised_from] = diagnosis[:advised_from] || diagnosis[:entered_from] || "ipd_record"
    new_diagnosis[:advised_at_facility] = diagnosis[:advised_at_facility] || diagnosis[:entered_at_facility] || @admitting_facility.name
    new_diagnosis[:advised_at_facility_id] = diagnosis[:advised_at_facility_id] || diagnosis[:entered_at_facility_id] || @admitting_facility.id.to_s
  end

  def self.procedure_params(new_procedure, record, procedure)
    new_procedure[:flow_in_ipd] = procedure[:flow_in_ipd]
    new_procedure[:iol_present] = procedure[:iol_present]
    new_procedure[:iol1_inventory_item_id] = procedure[:iol1_inventory_item_id]
    new_procedure[:iol2_inventory_item_id] = procedure[:iol2_inventory_item_id]
    new_procedure[:iol3_inventory_item_id] = procedure[:iol3_inventory_item_id]
    new_procedure[:procedurestage] = procedure[:procedurestage]
    new_procedure[:procedurename] = procedure[:procedurename]
    new_procedure[:procedure_id] = procedure[:procedure_id]
    new_procedure[:procedureoriginalside] = procedure[:procedureoriginalside]
    new_procedure[:procedureside] = procedure[:procedureside]
    new_procedure[:procedurefullcode] = procedure[:procedurefullcode]
    new_procedure[:procedure_type] = procedure[:procedure_type]

    new_procedure[:procedure_comment] = procedure[:procedure_comment]
    new_procedure[:users_comment] = procedure[:users_comment]
    new_procedure[:user_id] = procedure[:user_id]

    # if procedure[:entered_from].nil? || procedure[:entered_from] == "ipd_record"
    if procedure[:flow_in_ipd] == "true"
      new_procedure[:ipd_record_id] = record.id.to_s
      new_procedure[:admission_id] = new_procedure.admission_id || record.admission_id
    else
      new_procedure[:ipd_record_id] = nil
      new_procedure[:admission_id] = nil
      new_procedure[:ipd_procedure_ids] = new_procedure.ipd_procedure_ids.except(record.id.to_s)
    end
    # end

    new_procedure[:consultant_id] = @admitting_doctor.id
    new_procedure[:consultant_name] = @admitting_doctor.fullname

    new_procedure[:entered_by] = procedure[:entered_by]
    new_procedure[:entered_by_id] = procedure[:entered_by_id]
    new_procedure[:entered_datetime] = procedure[:entered_datetime]
    new_procedure[:entered_from] = procedure[:entered_from] || "ipd_record"
    new_procedure[:entered_at_facility] = procedure[:entered_at_facility]
    new_procedure[:entered_at_facility_id] = procedure[:entered_at_facility_id]

    new_procedure[:is_advised] = true
    new_procedure[:advised_by] = procedure[:advised_by] || @admitting_doctor.fullname
    new_procedure[:advised_by_id] = procedure[:advised_by_id] || @admitting_doctor.id
    new_procedure[:advised_datetime] = procedure[:advised_datetime] || procedure[:entered_datetime] || Time.current
    new_procedure[:advised_from] = procedure[:advised_from] || procedure[:entered_from] || "ipd_record"
    new_procedure[:advised_at_facility] = procedure[:advised_at_facility] || procedure[:entered_at_facility] || @admitting_facility.name
    new_procedure[:advised_at_facility_id] = procedure[:advised_at_facility_id] || procedure[:entered_at_facility_id] || @admitting_facility.id.to_s

    if procedure[:procedurestage] == "Performed"
      new_procedure[:is_performed] = true
      new_procedure[:performed_by] = procedure[:performed_by]
      new_procedure[:performed_by_id] = procedure[:performed_by_id]
      new_procedure[:performed_datetime] = procedure[:performed_datetime]
      new_procedure[:performed_from] = procedure[:performed_from] || "ipd_record"
      new_procedure[:performed_at_facility] = procedure[:performed_at_facility]
      new_procedure[:performed_at_facility_id] = procedure[:performed_at_facility_id]
    end
  end

  def self.complication_params(new_complication, record, complication)
    new_complication[:complication_name] = complication[:complication_name]
    new_complication[:code] = complication[:code]
    new_complication[:procedure_code] = complication[:procedure_code]
    new_complication[:procedure_id] = complication[:procedure_id]
    new_complication[:entered_by] = complication[:entered_by]
    new_complication[:entered_by_id] = complication[:entered_by_id]
    new_complication[:entered_at_facility] = complication[:entered_at_facility]
    new_complication[:entered_at_facility_id] = complication[:entered_at_facility_id]

    new_complication[:comment] = complication[:comment]
    new_complication[:entered_datetime] = complication[:entered_datetime]
    new_complication[:updated_datetime] = complication[:updated_datetime]

    new_complication[:ipd_record_id] = record.id.to_s
    new_complication[:operative_note_id] = complication[:operative_note_id]

    new_complication[:updated_by] = complication[:updated_by]
    new_complication[:updated_by_id] = complication[:updated_by_id]
    new_complication[:updated_at_facility] = complication[:updated_at_facility]
    new_complication[:updated_at_facility_id] = complication[:updated_at_facility_id]
  end

  def self.analytics_before_params_ipd_record(case_sheet)
    analytics_case_sheet = CaseSheet.find_by(id: case_sheet.id) # done intentionally, data was getting updated as of after save method

    @analytics_params["before_save_patient_age"] = analytics_case_sheet.patient_age
    @analytics_params["before_save_patient_gender"] = analytics_case_sheet.patient_gender
    @analytics_params["before_save_diagnosis"] = analytics_case_sheet.diagnoses.to_a
    @analytics_params["before_save_procedure"] = analytics_case_sheet.procedures.to_a
    @analytics_params["before_save_ophthal_investigations"] = analytics_case_sheet.ophthal_investigations.to_a
    @analytics_params["before_save_radiology_investigations"] = analytics_case_sheet.radiology_investigations.to_a
    @analytics_params["before_save_laboratory_investigations"] = analytics_case_sheet.laboratory_investigations.to_a
  end

  def self.analytics_after_params_ipd_record(case_sheet)
    patient = Patient.find_by(id: case_sheet.patient_id)

    options = {}
    options = options.merge(patient_gender: patient.gender) if case_sheet.patient_gender != patient.gender
    options = options.merge(patient_age: "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}") if (case_sheet.patient_age.present? && case_sheet.patient_age.split("/")[2] != patient.dob_year) || case_sheet.patient_age.nil?
    case_sheet.update(options)

    @analytics_params["data_from"] = "ipd_record"
    @analytics_params["case_sheet_id"] = case_sheet.id
    @analytics_params["after_save_patient_age"] = case_sheet.patient_age
    @analytics_params["after_save_patient_gender"] = case_sheet.patient_gender
    @analytics_params["after_save_diagnosis"] = case_sheet.diagnoses
    @analytics_params["after_save_procedure"] = case_sheet.procedures
    @analytics_params["after_save_ophthal_investigations"] = case_sheet.ophthal_investigations
    @analytics_params["after_save_radiology_investigations"] = case_sheet.radiology_investigations
    @analytics_params["after_save_laboratory_investigations"] = case_sheet.laboratory_investigations
  end
end
