module Mis::ClinicalReports
  class DiagnosisSummaryService
    class << self
      def format_data_before_save(record_id, from_department, created_from_form_name, start_date=nil, end_date=nil, entered_from=nil)
        @from_department = from_department
        @from_department_id = Global.ehrcommon.send(@from_department.downcase.to_s).id
        @created_from_form_name = created_from_form_name
        @created_from_form_id = Global.ehrcommon.send(@created_from_form_name.to_s).id
        if @from_department == 'OPD' && @created_from_form_name == 'opd_record_form'
          primary_model_name = 'OpdRecord'
          opd_record = OpdRecord.find_by(id: record_id)
          return unless opd_record.present?
          case_sheet_id = (opd_record[:case_sheet_id]).to_s
          extract_diagnosis_data(
            record_id, case_sheet_id, primary_model_name, start_date, end_date, entered_from
          )
        elsif @from_department == 'IPD' && @created_from_form_name == 'admission_form'
          primary_model_name = 'Admission'
          admission_record = Admission.find_by(id: record_id)
          return unless admission_record.present?
          case_sheet_id = (admission_record[:case_sheet_id]).to_s
          extract_diagnosis_data(
            record_id, case_sheet_id, primary_model_name, start_date, end_date, entered_from
          )
        elsif @from_department == 'IPD' && @created_from_form_name == 'ipd_record_form'
          primary_model_name = 'Admission'
          admission_record = Admission.find_by(id: record_id)
          return unless admission_record.present?
          case_sheet_id = (admission_record[:case_sheet_id]).to_s
          extract_diagnosis_data(
            record_id, case_sheet_id, primary_model_name, start_date, end_date, entered_from
          )
        end
      end

      def process_and_save(options_array)
        if options_array.present?
          options_array.each do |option|
            if option[:diagnosis_type_id] == 447634004 #diagnosis_icd
              diagnosis_id_find_or_create_by(option, 447634004)
            elsif option[:diagnosis_type_id] == 860573009 #diagnosis_custom
              diagnosis_id_find_or_create_by(option, 860573009)
            elsif option[:diagnosis_type_id] == 80409005 #diagnosis_translated
              diagnosis_id_find_or_create_by(option, 80409005)
            elsif option[:diagnosis_type_id] == 148006 #diagnosis_provisional
              primary_model_id_find_or_create_by(option, 148006)
            elsif option[:diagnosis_type_id] == 288790002 #diagnosis_commentbox
              primary_model_id_find_or_create_by(option, 288790002)
            end
          end
        end
      end

      private

      def diagnosis_id_find_or_create_by(option, diagnosis_type_id)
        m_diag_summary_report = MisClinical::Common::DiagnosisSummaryReport.find_or_create_by(facility_id: option[:facility_id], specialty_id: option[:specialty_id], diagnosis_type_id: diagnosis_type_id, diagnosis_id: option[:diagnosis_id])
        m_diag_summary_report.update_attributes(option)
      end

      def primary_model_id_find_or_create_by(option, diagnosis_type_id)
        m_diag_summary_report = MisClinical::Common::DiagnosisSummaryReport.find_or_create_by(facility_id: option[:facility_id], specialty_id: option[:specialty_id], diagnosis_type_id: diagnosis_type_id, primary_model_id: option[:primary_model_id])
        m_diag_summary_report.update_attributes(option)
      end

      def get_patient_data(patient_id) #, diagnosis_date
        patient = Patient.find_by(id: patient_id)
        patient_name = patient.fullname
        gender_defined = false
        age = patient.exact_age
        age = patient.age if patient.age.present? && patient.age > 0
        # age_at_encounter, current_age, age_present = Patientdata::AgeAtEncounter.call(patient_id.to_s, diagnosis_date)

        gender_defined = true if patient.gender.present?
        
        patient_hash = {
          'patient_id': patient_id, 'patient_name': patient_name, 'age': age, 'gender': patient.gender,
          'patient_identifier_id': patient.patient_identifier_id, 'patient_mrn': patient.patient_mrn,
          'gender_defined': gender_defined
        }
        # , 'age_at_encounter': age_at_encounter, 'current_age': current_age, 'age_present': age_present
      end

      def extract_diagnosis_data(record_id, case_sheet_id, primary_model_name, start_date=nil, end_date=nil, entered_from=nil)
        options_array = []
        case_sheet_obj = CaseSheet.find_by(id: case_sheet_id)
        patient_display_fields = get_patient_data(case_sheet_obj[:patient_id])
        # patient_display_fields = get_patient_data(case_sheet_obj[:patient_id], case_sheet_obj.diagnoses.last.entered_datetime)
        specialty_id = case_sheet_obj[:specialty_id]
        organisation_id = (case_sheet_obj[:organisation_id]).to_s
        specality_name = TemplatesHelper.get_speciality_name(specialty_id)
        # from_department_id = Global.ehrcommon.send(from_department.downcase.to_s).id
        # created_from_form_id = Global.ehrcommon.send(created_from_form_name.to_s).id
        global_data_attr = { from_department: @from_department.to_s, from_department_id: @from_department_id, specialty_id: specialty_id, specialty_name: specality_name.to_s, organisation_id: organisation_id.to_s, case_sheet_id: case_sheet_id.to_s, primary_model_id: record_id.to_s, primary_model_name: primary_model_name.to_s, created_from_form_id: @created_from_form_id, created_from_form_name: @created_from_form_name.to_s }
        case_diagnosis = case_sheet_obj.diagnoses
        case_diagnosis = case_diagnosis.select{|d| d['entered_from'].present? && d['entered_from'] == entered_from && d['entered_datetime'].present? && d['entered_datetime'] >= start_date && d['entered_datetime'] <= end_date} if start_date.present? && end_date.present? && entered_from.present?
        case_diagnosis.each do |diagnosis|
          diagnosis_type, diagnosis_type_label, diagnosis_type_id = get_icd_type_label_id(diagnosis[:icd_type])

          diagnosis_arr = diagnosis_attributes((diagnosis[:icd_type]).to_s, (diagnosis[:icddiagnosiscode]).to_s)
          diagnosis_original_name = diagnosis_arr[7].to_s
          diagnosis_name = diagnosis_arr_name = ''
          diagnosis_name = (diagnosis[:diagnosisname]).to_s if (diagnosis[:diagnosisname])&.to_s.length > 3
          diagnosis_arr_name = (diagnosis_arr[2]).to_s if diagnosis_arr.present? && (diagnosis_arr[2])&.to_s.length > 3

          diagnosis_advised_datetime = (diagnosis[:advised_datetime].present?) ? diagnosis[:advised_datetime] : nil
          diagnosis_laterality_arr = compute_laterality_from_diagnosis_name(diagnosis_name, diagnosis_arr_name)
          laterality_abbr = (diagnosis_laterality_arr[1]).to_s
          laterality_name = (diagnosis_laterality_arr[2]).to_s
          has_laterality = (diagnosis_arr.present? && diagnosis_arr[4].present?) ? diagnosis_arr[4] : nil
          laterality_code = (has_laterality.present? && diagnosis_arr[3].present?) ? diagnosis_arr[3].split('|').last.to_s : ''
          laterality_position = (diagnosis_arr.present? && diagnosis_arr[5].present?) ? (diagnosis_arr[5]).to_s : nil
          final_data_attr = {}
          patient_age_at_encounter, patient_current_age, patient_age_present = [ nil, nil, nil ]
          patient_age_at_encounter, patient_current_age, patient_age_present = Patientdata::AgeAtEncounter.call(case_sheet_obj[:patient_id].to_s, diagnosis_advised_datetime) if diagnosis_advised_datetime.present?
          diagnosis_data_attr = { is_diagnosis_coded: true, diagnosis_id: diagnosis[:id], diagnosis_type: diagnosis_type, diagnosis_type_label: diagnosis_type_label, diagnosis_type_id: diagnosis_type_id, diagnosis_date: diagnosis_advised_datetime.try(:to_date), diagnosis_date_time: diagnosis_advised_datetime, partial_diagnosis_name: '', laterality_name: laterality_name.to_s, laterality_abbr: laterality_abbr.to_s, full_diagnosis_name: (diagnosis[:diagnosisname]).to_s, diagnosis_comment: (diagnosis[:diagnosis_comment]).to_s, users_comment: (diagnosis[:diagnosis_comment]).to_s, partial_diagnosis_code: '', has_laterality: has_laterality, laterality_code: laterality_code.to_s, laterality_position: laterality_position.to_s, full_diagnosis_code: (diagnosis[:icddiagnosiscode]).to_s, full_diagnosis_code_length: diagnosis[:icddiagnosiscodelength], full_diagnosis_code_piped: (diagnosis[:saperatedicddiagnosiscode]).to_s, doctor_id: (diagnosis[:advised_by_id]).to_s, doctor_name: (diagnosis[:advised_by]).to_s, facility_id: (diagnosis[:advised_at_facility_id]).to_s, facility_name: (diagnosis[:advised_at_facility]).to_s,
            patient_age_at_encounter: patient_age_at_encounter, patient_current_age: patient_current_age,
            patient_age_present: patient_age_present, diagnosis_original_name: diagnosis_original_name }
          final_data_attr = global_data_attr.merge(final_data_attr)
          final_data_attr['patient_display_fields'] = patient_display_fields
          final_data_attr = diagnosis_data_attr.merge(final_data_attr)
          options_array.push(final_data_attr)
        end
        options_array
      end

      def get_icd_type_label_id(str)
        if str == 'IcdDiagnosis'
          [Global.ehrcommon.diagnosis_icd.displayname.to_s, Global.ehrcommon.diagnosis_icd.abbr.to_s, Global.ehrcommon.diagnosis_icd.id]
        elsif str == 'CustomIcdDiagnosis'
          [Global.ehrcommon.diagnosis_custom.displayname.to_s, Global.ehrcommon.diagnosis_custom.abbr.to_s, Global.ehrcommon.diagnosis_custom.id]
        elsif str == 'ProvisionalDiagnosis'
          [Global.ehrcommon.diagnosis_provisional.displayname.to_s, Global.ehrcommon.diagnosis_provisional.abbr.to_s, Global.ehrcommon.diagnosis_provisional.id]
        elsif str == 'TranslatedIcdDiagnosis'
          [Global.ehrcommon.diagnosis_translated.displayname.to_s, Global.ehrcommon.diagnosis_translated.abbr.to_s, Global.ehrcommon.diagnosis_translated.id]
        elsif str == 'CommentBox'
          [Global.ehrcommon.diagnosis_commentbox.displayname.to_s, Global.ehrcommon.diagnosis_commentbox.abbr.to_s, Global.ehrcommon.diagnosis_commentbox.id]
        else
          ['Other Diagnosis', 'OTHERS', 0]
        end
      end

      def diagnosis_attributes(str, code)
        diagnosis_arr = []
        if str == 'IcdDiagnosis'
          diagnosis_arr = get_icd_diagnosis_attributes(code)
        elsif str == 'CustomIcdDiagnosis'
          diagnosis_arr = get_custom_diagnosis_attributes(code)
        elsif str == 'TranslatedIcdDiagnosis'
          diagnosis_arr = get_translated_diagnosis_attributes(code)
        end
      end

      def get_icd_diagnosis_attributes(code)
        attributes = find_icd_diagnosis_attr(code)
        [attributes['code'], attributes['codelength'], attributes['fullname'], attributes['separated_code'], attributes['has_laterality'], attributes['laterality_position'], attributes['lateralitylabel'], attributes['originalname']] rescue []
      end

      def get_custom_diagnosis_attributes(code)
        attributes = find_custom_diagnosis_attr(code)
        [attributes['code'], attributes['codelength'], attributes['fullname'], attributes['separatedcode'], attributes['has_laterality'], attributes['laterality_position'], attributes['lateralitylabel'], attributes['originalname']] rescue []
      end

      def get_translated_diagnosis_attributes(code)
        attributes = find_translated_diagnosis_attr(code)
        [attributes['code'], attributes['codelength'], attributes['fullname'], attributes['separatedcode'], attributes['has_laterality'], attributes['laterality_position'], attributes['lateralitylabel'], attributes['originalname']] rescue []
      end

      def find_icd_diagnosis_attr(diagnosis_code)
        diagnosis_attr = IcdDiagnosis.find_by(code: diagnosis_code.to_s)&.attributes
        diagnosis_attr
      end
      # find_icd_diagnosis_attr(["has_laterality", "laterality_position", "lateralitylabel", "separated_code"], "h26001")
      # find_icd_diagnosis_attr("h26001")

      def find_custom_diagnosis_attr(diagnosis_code)
        diagnosis_attr = CustomIcdDiagnosis.find_by(code: diagnosis_code.to_s)&.attributes
        diagnosis_attr
      end
      # find_custom_diagnosis_attr(["has_laterality", "laterality_position", "lateralitylabel", "separatedcode"], "lizicd10001")
      # find_custom_diagnosis_attr("lizicd10001")

      def find_translated_diagnosis_attr(diagnosis_code)
        diagnosis_attr = TranslatedIcdDiagnosis.find_by(code: diagnosis_code.to_s)&.attributes
        diagnosis_attr
      end
      # find_translated_diagnosis_attr(["has_laterality", "laterality_position", "lateralitylabel", "separatedcode"], "lizicd10001")
      # find_translated_diagnosis_attr("lizicd10001")

      def compute_laterality_from_diagnosis_name(diagnosis_entered_by_user, diagnosis_full_name)
        right_side = ['right', 'Right', 'RIGHT', 'Right Eye', 'Right Eyes', 'right eye', 'right eyes', 'R Eye', 'R Eyes']
        left_side = ['left', 'Left', 'LEFT', 'Left Eye', 'Left Eyes', 'left eye', 'left eyes', 'L Eye', 'L Eyes']
        bilateral_side = ['bilateral', 'Bilateral', 'BILATERAL', 'BOTH EYES', 'Both Eyes', 'B/E', 'BE', 'both eye', 'both eyes', 'Both Eye']
        if right_side.any? { |s| diagnosis_entered_by_user.include?(s) } || right_side.any? { |s| diagnosis_full_name.include?(s) }
          ['r', 'R', 'Right', 'Right Eye', 18944008]
        elsif left_side.any? { |s| diagnosis_entered_by_user.include?(s) } || left_side.any? { |s| diagnosis_full_name.include?(s) }
          ['l', 'L', 'Left', 'Left Eye', 8966001]
        elsif bilateral_side.any? { |s| diagnosis_entered_by_user.include?(s) } || bilateral_side.any? { |s| diagnosis_full_name.include?(s) }
          ['b/e', 'B/E', 'Both Eyes', 40638003]
        else
          ['nec', 'NEC', 'Unspecified', 10003008]
        end
      end
    end
  end
end
