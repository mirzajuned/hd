class CaseSheet::CreateAdmissionService
  def self.call(patient, admission, case_sheet_params, current_user_id, current_facility_id)
    case_sheets = CaseSheet.where(patient_id: patient.id).update_all(is_active: false)
    case_sheet = CaseSheet.find_by(id: admission.case_sheet_id) || CaseSheet.new

    if case_sheet.present?

      @analytics_params = {}
      analytics_before_params_admission(case_sheet)

      admission_ids = case_sheet.admission_ids
      admission_ids << admission.id.to_s

      case_sheet[:admission_ids] = admission_ids.uniq
      case_sheet[:active_admission_id] = admission.id.to_s
      case_sheet[:patient_id] = patient.id
      case_sheet[:organisation_id] = admission.organisation_id
      case_sheet[:is_active] = true
      case_sheet[:case_name] = case_sheet.case_name || (case_sheet_params[:case_name] if case_sheet_params.present?) || nil
      case_sheet[:start_date] = case_sheet.start_date || (case_sheet_params[:start_date] if case_sheet_params.present?) || nil
      case_sheet[:case_switchable_ipd] = case_sheet.case_switchable_ipd
      case_sheet[:case_switchable_ipd][admission.id.to_s] = Hash[case_switchable: true]
      case_sheet[:specialty_id] = admission.specialty_id

      case_sheet[:free_form_histories] = case_sheet.free_form_histories
      case_sheet[:free_form_examinations] = case_sheet.free_form_examinations
      case_sheet[:free_form_diagnoses] = case_sheet.free_form_diagnoses
      case_sheet[:free_form_procedures] = case_sheet.free_form_procedures
      case_sheet[:free_form_investigations] = case_sheet.free_form_investigations

      if case_sheet_params.present?
        @admitting_doctor = User.find_by(id: admission.doctor)
        @admitting_facility = Facility.find_by(id: admission.facility_id)

        options = { record_id: admission.id.to_s, record_type: 'admission', consultant_id: admission.doctor.to_s,
                    consultant_name: @admitting_doctor.fullname, date: admission.updated_at }

        # unless case_sheet_params[:free_history_text].blank?
        case_sheet[:free_form_histories][admission.id.to_s] = options.merge(content: case_sheet_params[:free_history_text])
        # end
        # unless case_sheet_params[:free_examination_text].blank?
        case_sheet[:free_form_examinations][admission.id.to_s] = options.merge(content: case_sheet_params[:free_examination_text])
        # end
        # unless case_sheet_params[:free_diagnosis_text].blank?
        case_sheet[:free_form_diagnoses][admission.id.to_s] = options.merge(content: case_sheet_params[:free_diagnosis_text])
        # end
        # unless case_sheet_params[:free_procedure_text].blank?
        case_sheet[:free_form_procedures][admission.id.to_s] = options.merge(content: case_sheet_params[:free_procedure_text])
        # end
        case_sheet[:free_form_investigations][admission.id.to_s] = options.merge(content: case_sheet_params[:free_investigation_text])

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
              diagnosis_params(new_diagnosis, admission, diagnosis)

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
              procedure_params(new_procedure, admission, procedure)
              if procedure[:flow_in_ipd] == 'true'
                new_procedure[:procedurestage] = "Scheduled"
              end
              new_procedure.save
              # binding.pry
              procedure_order_status_params(new_procedure, admission, case_sheet)
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
          case_id = SequenceManagers::GenerateSequenceService.call('case_sheet', case_sheet.id.to_s, {organisation_id: admission.organisation_id.to_s, facility_id: admission.facility_id.to_s, region_id: admission.facility.try(:region_master_id).to_s})
          case_sheet.update(case_id: case_id)
        end
        admission.update(case_sheet_id: case_sheet.id)
        # OrderJobs::AdvisedJob.perform_later(case_sheet.id.to_s, current_user_id.to_s, current_facility_id.to_s)
        analytics_after_params_admission(case_sheet)
        Analytics::CreateService.call(@analytics_params.to_json, admission.doctor.to_s, admission.facility_id.to_s, "clinical_data")
      end
    end
  end

  private

  def self.procedure_order_status_params(case_sheet_record_procedure, admission, case_sheet)
    # organisation = Organisation.find_by(id: admission.try(:organisation_id))
    # organisations_setting = organisation.try(:organisations_setting)
    # advise_order_rule = organisations_setting.try(:active_advise_order_rule).to_s

    # case_sheet = CaseSheet.find_by(id: admission.try(:case_sheet_id))

    case_sheet_existing_procedures = case_sheet.procedures.where(procedurefullcode: case_sheet_record_procedure.procedurefullcode, procedureside: case_sheet_record_procedure.procedureside, :order_status.ne => "closed")

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
      active_order_advised.assign_attributes(display_id: CommonHelper.get_procedure_order_identifier(admission.organisation_id),
                                             organisation_id: admission.try(:organisation_id), facility_id: admission.try(:facility_id),
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

  def self.diagnosis_params(new_diagnosis, admission, diagnosis)
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

    if diagnosis[:entered_from].nil? || diagnosis[:entered_from] == "admission"
      new_diagnosis[:admission_id] = new_diagnosis.admission_id || admission.id.to_s
      new_diagnosis[:consultant_id] = @admitting_doctor.id
      new_diagnosis[:consultant_name] = @admitting_doctor.fullname
    end

    new_diagnosis[:entered_by] = diagnosis[:entered_by]
    new_diagnosis[:entered_by_id] = diagnosis[:entered_by_id]
    new_diagnosis[:entered_datetime] = diagnosis[:entered_datetime]
    new_diagnosis[:entered_from] = diagnosis[:entered_from] || "admission"
    new_diagnosis[:entered_at_facility] = diagnosis[:entered_at_facility]
    new_diagnosis[:entered_at_facility_id] = diagnosis[:entered_at_facility_id]

    new_diagnosis[:is_advised] = true
    new_diagnosis[:advised_by] = diagnosis[:advised_by] || @admitting_doctor.fullname
    new_diagnosis[:advised_by_id] = diagnosis[:advised_by_id] || @admitting_doctor.id
    new_diagnosis[:advised_datetime] = diagnosis[:advised_datetime] || diagnosis[:entered_datetime] || Time.current
    new_diagnosis[:advised_from] = diagnosis[:advised_from] || diagnosis[:entered_from] || "admission"
    new_diagnosis[:advised_at_facility] = diagnosis[:advised_at_facility] || diagnosis[:entered_at_facility] || @admitting_facility.name
    new_diagnosis[:advised_at_facility_id] = diagnosis[:advised_at_facility_id] || diagnosis[:entered_at_facility_id] || @admitting_facility.id.to_s
  end

  def self.procedure_params(new_procedure, admission, procedure)
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

    if procedure[:entered_from].nil? || procedure[:entered_from] == "admission"
      new_procedure[:admission_id] = new_procedure.admission_id || admission.id.to_s
      new_procedure[:consultant_id] = @admitting_doctor.id
      new_procedure[:consultant_name] = @admitting_doctor.fullname
    end

    new_procedure[:entered_by] = procedure[:entered_by]
    new_procedure[:entered_by_id] = procedure[:entered_by_id]
    new_procedure[:entered_datetime] = procedure[:entered_datetime]
    new_procedure[:entered_from] = procedure[:entered_from] || "admission"
    new_procedure[:entered_at_facility] = procedure[:entered_at_facility]
    new_procedure[:entered_at_facility_id] = procedure[:entered_at_facility_id]

    new_procedure[:is_advised] = true
    new_procedure[:advised_by] = procedure[:advised_by] || @admitting_doctor.fullname
    new_procedure[:advised_by_id] = procedure[:advised_by_id] || @admitting_doctor.id
    new_procedure[:advised_datetime] = procedure[:advised_datetime] || procedure[:entered_datetime] || Time.current
    new_procedure[:advised_from] = procedure[:advised_from] || procedure[:entered_from] || "admission"
    new_procedure[:advised_at_facility] = procedure[:advised_at_facility] || procedure[:entered_at_facility] || @admitting_facility.name
    new_procedure[:advised_at_facility_id] = procedure[:advised_at_facility_id] || procedure[:entered_at_facility_id] || @admitting_facility.id.to_s

    if procedure[:procedurestage] == "Performed"
      new_procedure[:is_performed] = true
      new_procedure[:performed_by] = procedure[:performed_by]
      new_procedure[:performed_by_id] = procedure[:performed_by_id]
      new_procedure[:performed_datetime] = procedure[:performed_datetime]
      new_procedure[:performed_from] = procedure[:performed_from] || "admission"
      new_procedure[:performed_at_facility] = procedure[:performed_at_facility]
      new_procedure[:performed_at_facility_id] = procedure[:performed_at_facility_id]
    end
  end

  def self.analytics_before_params_admission(case_sheet)
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

  def self.analytics_after_params_admission(case_sheet)
    patient = Patient.find_by(id: case_sheet.patient_id)

    options = {}
    options = options.merge(patient_gender: patient.gender) if case_sheet.patient_gender != patient.gender
    options = options.merge(patient_age: "#{patient.dob_day}/#{patient.dob_month}/#{patient.dob_year}") if (case_sheet.patient_age.present? && case_sheet.patient_age.split("/")[2] != patient.dob_year) || case_sheet.patient_age.nil?
    case_sheet.update(options)

    @analytics_params["data_from"] = "admission"
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
