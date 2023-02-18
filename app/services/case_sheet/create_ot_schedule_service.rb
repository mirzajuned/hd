class CaseSheet::CreateOtScheduleService
  def self.call(patient, ot_schedule, case_sheet_params)
    case_sheets = CaseSheet.where(patient_id: patient.id).update_all(is_active: false)
    case_sheet = CaseSheet.find_by(id: ot_schedule.case_sheet_id) || CaseSheet.new

    if case_sheet.present?

      @analytics_params = {}
      analytics_before_params_ot_schedule(case_sheet)

      ot_schedule_ids = case_sheet.ot_schedule_ids
      ot_schedule_ids << ot_schedule.id.to_s

      case_sheet[:specialty_id] = ot_schedule.specialty_id
      case_sheet[:ot_schedule_ids] = ot_schedule_ids.uniq
      case_sheet[:patient_id] = patient.id
      case_sheet[:organisation_id] = ot_schedule.try(:facility).try(:organisation_id)
      case_sheet[:is_active] = true
      case_sheet[:case_name] = case_sheet.case_name || (case_sheet_params[:case_name] if case_sheet_params.present?) || nil
      case_sheet[:start_date] = case_sheet.start_date || (case_sheet_params[:start_date] if case_sheet_params.present?) || nil

      case_sheet[:free_form_histories] = case_sheet.free_form_histories
      case_sheet[:free_form_examinations] = case_sheet.free_form_examinations
      case_sheet[:free_form_diagnoses] = case_sheet.free_form_diagnoses
      case_sheet[:free_form_procedures] = case_sheet.free_form_procedures
      case_sheet[:free_form_investigations] = case_sheet.free_form_investigations

      if case_sheet_params.present?
        @operating_doctor = User.find_by(id: ot_schedule.surgeonname)
        @ot_facility = Facility.find_by(id: ot_schedule.facility_id)
        ot_schedule_id = ot_schedule.id.to_s

        options = { record_id: ot_schedule_id, record_type: 'ot_schedule', consultant_id: ot_schedule.surgeonname.to_s,
                    consultant_name: @operating_doctor.fullname, date: ot_schedule.updated_at }

        unless case_sheet_params[:free_history_text].blank?
          case_sheet[:free_form_histories][ot_schedule_id] = options.merge(content: case_sheet_params[:free_history_text])
        end
        unless case_sheet_params[:free_examination_text].blank?
          case_sheet[:free_form_examinations][ot_schedule_id] = options.merge(content: case_sheet_params[:free_examination_text])
        end
        unless case_sheet_params[:free_diagnosis_text].blank?
          case_sheet[:free_form_diagnoses][ot_schedule_id] = options.merge(content: case_sheet_params[:free_diagnosis_text])
        end
        unless case_sheet_params[:free_procedure_text].blank?
          case_sheet[:free_form_procedures][ot_schedule_id] = options.merge(content: case_sheet_params[:free_procedure_text])
        end
        unless case_sheet_params[:free_investigation_text].blank?
          case_sheet[:free_form_investigations][ot_schedule_id] = options.merge(content: case_sheet_params[:free_investigation_text])
        end

        # CaseSheet Diagnosis
        if case_sheet_params[:diagnoses].present?
          case_sheet_params[:diagnoses].each do |k, diagnosis|
            case_sheet_diagnosis = (case_sheet.diagnoses.find_by(id: diagnosis[:id]) if diagnosis[:id].present?) || nil
            if case_sheet_diagnosis.present?
              new_diagnosis = case_sheet_diagnosis
            else
              new_diagnosis = case_sheet.diagnoses.new
            end
            if new_diagnosis.present?
              diagnosis_params(new_diagnosis, ot_schedule, diagnosis)

              new_diagnosis.save
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
              procedure_params(new_procedure, ot_schedule, procedure)

              new_procedure.save
            end
          end
        end
      end

      # Case not Switchable if OpdRecord Present in Case
      opd_records = OpdRecord.where(:id.in => case_sheet.opd_record_ids)
      opd_records.each do |opd_record|
        case_sheet[:case_switchable_opd] = case_sheet.case_switchable_opd
        case_sheet[:case_switchable_opd][opd_record.appointmentid.to_s] = Hash[case_switchable: false]
      end

      if case_sheet.save
        unless case_sheet.case_id.present?
          case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', case_sheet.id.to_s, {organisation_id: ot_schedule.organisation_id.to_s, facility_id: ot_schedule.facility_id.to_s, region_id: ot_schedule.facility.try(:region_master_id).to_s})
          case_sheet.update(case_id: case_id)
        end
        ot_schedule.update(case_sheet_id: case_sheet.id)

        analytics_after_params_ot_schedule(case_sheet)
        Analytics::CreateService.call(@analytics_params.to_json, ot_schedule.surgeonname.to_s, ot_schedule.facility_id.to_s, "clinical_data")
      end
    end
  end

  private

  def self.diagnosis_params(new_diagnosis, ot_schedule, diagnosis)
    new_diagnosis[:diagnosisname] = diagnosis[:diagnosisname]
    new_diagnosis[:diagnosisoriginalname] = diagnosis[:diagnosisoriginalname]
    new_diagnosis[:icddiagnosiscode] = diagnosis[:icddiagnosiscode]
    new_diagnosis[:saperatedicddiagnosiscode] = diagnosis[:saperatedicddiagnosiscode]
    new_diagnosis[:icddiagnosiscodelength] = diagnosis[:icddiagnosiscodelength]
    new_diagnosis[:icd_type] = diagnosis[:icd_type]
    new_diagnosis[:diagnosis_comment] = diagnosis[:diagnosis_comment]
    new_diagnosis[:users_comment] = diagnosis[:users_comment]
    new_diagnosis[:user_id] = diagnosis[:user_id]

    if diagnosis[:entered_from].nil? || diagnosis[:entered_from] == "ot_schedule"
      new_diagnosis[:ot_schedule_id] = new_diagnosis.ot_schedule_id || ot_schedule.id.to_s
    end

    new_diagnosis[:consultant_id] = @operating_doctor.id
    new_diagnosis[:consultant_name] = @operating_doctor.fullname

    new_diagnosis[:entered_by] = diagnosis[:entered_by]
    new_diagnosis[:entered_by_id] = diagnosis[:entered_by_id]
    new_diagnosis[:entered_datetime] = diagnosis[:entered_datetime]
    new_diagnosis[:entered_from] = diagnosis[:entered_from] || "ot_schedule"
    new_diagnosis[:entered_at_facility] = diagnosis[:entered_at_facility]
    new_diagnosis[:entered_at_facility_id] = diagnosis[:entered_at_facility_id]

    new_diagnosis[:is_advised] = true
    new_diagnosis[:advised_by] = diagnosis[:advised_by] || @operating_doctor.fullname
    new_diagnosis[:advised_by_id] = diagnosis[:advised_by_id] || @operating_doctor.id
    new_diagnosis[:advised_datetime] = diagnosis[:advised_datetime] || diagnosis[:entered_datetime] || Time.current
    new_diagnosis[:advised_from] = diagnosis[:advised_from] || diagnosis[:entered_from] || "ot_schedule"
    new_diagnosis[:advised_at_facility] = diagnosis[:advised_at_facility] || diagnosis[:entered_at_facility] || @ot_facility.name
    new_diagnosis[:advised_at_facility_id] = diagnosis[:advised_at_facility_id] || diagnosis[:entered_at_facility_id] || @ot_facility.id.to_s
  end

  def self.procedure_params(new_procedure, ot_schedule, procedure)
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

    if procedure[:entered_from].nil? || procedure[:entered_from] == "ot_schedule"
      new_procedure[:ot_schedule_id] = new_procedure.ot_schedule_id || ot_schedule.id.to_s
    end

    new_procedure[:consultant_id] = @operating_doctor.id
    new_procedure[:consultant_name] = @operating_doctor.fullname

    new_procedure[:entered_by] = procedure[:entered_by]
    new_procedure[:entered_by_id] = procedure[:entered_by_id]
    new_procedure[:entered_datetime] = procedure[:entered_datetime]
    new_procedure[:entered_from] = procedure[:entered_from] || "ot_schedule"
    new_procedure[:entered_at_facility] = procedure[:entered_at_facility]
    new_procedure[:entered_at_facility_id] = procedure[:entered_at_facility_id]

    new_procedure[:is_advised] = true
    new_procedure[:advised_by] = procedure[:advised_by] || @operating_doctor.fullname
    new_procedure[:advised_by_id] = procedure[:advised_by_id] || @operating_doctor.id
    new_procedure[:advised_datetime] = procedure[:advised_datetime] || procedure[:entered_datetime] || Time.current
    new_procedure[:advised_from] = procedure[:advised_from] || procedure[:entered_from] || "ot_schedule"
    new_procedure[:advised_at_facility] = procedure[:advised_at_facility] || procedure[:entered_at_facility] || @ot_facility.name
    new_procedure[:advised_at_facility_id] = procedure[:advised_at_facility_id] || procedure[:entered_at_facility_id] || @ot_facility.id.to_s
  end

  def self.analytics_before_params_ot_schedule(case_sheet)
    analytics_case_sheet = CaseSheet.find_by(id: case_sheet.try(:id)) # done intentionally, data was getting updated as of after save method

    if analytics_case_sheet.present?
      @analytics_params["before_save_patient_age"] = analytics_case_sheet.patient_age
      @analytics_params["before_save_patient_gender"] = analytics_case_sheet.patient_gender
      @analytics_params["before_save_diagnosis"] = analytics_case_sheet.diagnoses.to_a
      @analytics_params["before_save_procedure"] = analytics_case_sheet.procedures.to_a
      @analytics_params["before_save_ophthal_investigations"] = analytics_case_sheet.ophthal_investigations.to_a
      @analytics_params["before_save_radiology_investigations"] = analytics_case_sheet.radiology_investigations.to_a
      @analytics_params["before_save_laboratory_investigations"] = analytics_case_sheet.laboratory_investigations.to_a
    else
      @analytics_params["before_save_patient_age"] = nil
      @analytics_params["before_save_patient_gender"] = nil
      @analytics_params["before_save_diagnosis"] = []
      @analytics_params["before_save_procedure"] = []
      @analytics_params["before_save_ophthal_investigations"] = []
      @analytics_params["before_save_radiology_investigations"] = []
      @analytics_params["before_save_laboratory_investigations"] = []
    end
  end

  def self.analytics_after_params_ot_schedule(case_sheet)
    patient = Patient.find_by(id: case_sheet.patient_id)

    options = {}
    options = options.merge(patient_gender: patient.gender) if case_sheet.patient_gender != patient.gender
    options = options.merge(patient_age: "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}") if (case_sheet.patient_age.present? && case_sheet.patient_age.split("/")[2] != patient.dob_year) || case_sheet.patient_age.nil?
    case_sheet.update(options)

    @analytics_params["data_from"] = "ot_schedule"
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
