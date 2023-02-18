module PatientDiagnoses
  module CreateService
    def self.call(record, path)
      diagnosis_data = record.diagnosislist
      procedures_data = record.procedure

      if path == "opd"
        radiology_investigation_data = record.investigationlist
        laboratory_investigation_data = record.addedlaboratoryinvestigationlist
        ophthalmology_investigation_data = record.ophthalinvestigationlist
        advised_by = record.consultant_name
        advised_by_id = record.consultant_id
        organisation_id = record.organisation_id.to_s
      elsif path == "ipd"
        radiology_investigation_data = record.radiology_investigations_list
        laboratory_investigation_data = record.laboratory_investigations_list
        ophthalmology_investigation_data = record.ophthal_investigations_list
        advised_by_id = record.doctor_id
        user = User.find_by(id: advised_by_id)
        advised_by = user.try(:fullname)
        organisation_id = user.try(:organisation_id)
      end

      # to delete the diagnosis which is removed from the record without affecting the previously made entries for that PatientDiagnosis record.
      # patient_diagnosis = PatientDiagnosis.elem_match(opd_data: { record_id: record.id.to_s})
      patient_diagnosis = eval('PatientDiagnosis.elem_match(' + path + '_data: { record_id: record.id.to_s})')

      patient_diagnosis.each do |pat_diag|
        # data = pat_diag.opd_data
        data = eval('pat_diag.' + path + '_data')

        patient_opd_data = data.select { |set| set["record_id"] != record.id.to_s }
        patient_diagnosis.update(opd_data: patient_opd_data)

        if pat_diag.try(:opd_data).to_a.empty? && pat_diag.try(:ipd_data).to_a.empty?
          pat_diag.delete
        end
      end

      patient_id = record.patientid || record.patient_id
      patient = Patient.find_by(id: patient_id)

      diagnosis_data.each do |each_diagnosis|
        patient_diagnosis = PatientDiagnosis.find_by(code: each_diagnosis.try(:icddiagnosiscode), patient_id: patient_id)

        icd_diagnosis = eval(each_diagnosis.icd_type).find_by(code: each_diagnosis.icddiagnosiscode.downcase)

        if icd_diagnosis.present?
          # adding systemic history
          systemic_history_data = record.personal_history_records
          history_array = []
          only_names = []
          if systemic_history_data.present?
            systemic_history_data.each do |history|
              hash_new = Hash.new
              hash_new["name"] = history.try(:name)
              hash_new["duration"] = history.try(:duration)
              hash_new["duration_unit"] = history.try(:duration_unit)
              hash_new["comment"] = history.try(:comment)
              history_array.push(hash_new)
              only_names.push(history.try(:name))
            end
          end
          # eye drop allergies
          allergy_history = record.allergy_histories
          eye_drop_allergy_array = []
          eye_drop_allergy_only_names = []
          if allergy_history.present?
            allergy_history.each do |allergy|
              if (allergy.allergy_type.present? && allergy.allergy_subtype.present?) && (allergy.allergy_type == "drug_allergies" && allergy.allergy_subtype == "eye_drops")
                hash_new = Hash.new
                hash_new["name"] = allergy.try(:name)
                hash_new["duration"] = allergy.try(:duration)
                hash_new["duration_unit"] = allergy.try(:duration_unit)
                hash_new["comment"] = allergy.try(:comment)
                eye_drop_allergy_array.push(hash_new)
                eye_drop_allergy_only_names.push(allergy.try(:name))
              end
            end
          end
          # puts "=====icd_diagnosis===="
          # puts eval(each_diagnosis.icd_type)
          # puts each_diagnosis.icddiagnosiscode.downcase

          # if icd_diagnosis.blank?
          #   icd_diagnosis = IcdDiagnosis.find_by(code: each_diagnosis.icddiagnosiscode)
          # end
          new_diagnosis_data = Hash["record_id" => record.id.to_s,
                                    "entered_datetime" => each_diagnosis.try(:entry_datetime),
                                    "diagnosisname" => each_diagnosis.try(:diagnosisname),
                                    "originalname" => each_diagnosis.try(:diagnosisoriginalname),
                                    "code" => each_diagnosis.try(:icddiagnosiscode),
                                    "side_present" => icd_diagnosis.try(:has_laterality),
                                    "laterality" => icd_diagnosis.try(:lateralitylabel).try(:capitalize),
                                    "entered_by" => each_diagnosis.try(:entered_by),
                                    "entered_by_id" => each_diagnosis.try(:entered_by_id),
                                    "advised_by" => advised_by,
                                    "advised_by_id" => advised_by_id,
                                    "entered_at_facility" => each_diagnosis.try(:entered_at_facility),
                                    "entered_at_facility_id" => each_diagnosis.try(:entered_at_facility_id),
                                    "updated_by" => each_diagnosis.try(:updated_by),
                                    "updated_by_id" => each_diagnosis.try(:updated_by_id),
                                    "updated_at_facility" => each_diagnosis.try(:updated_at_facility),
                                    "updated_at_facility_id" => each_diagnosis.try(:updated_at_facility_id),
                                    "updated_datetime" => each_diagnosis.try(:updated_datetime),
                                    "diagnosis_comment" => each_diagnosis.try(:diagnosis_comment),
                                    "users_comment" => each_diagnosis.try(:users_comment),
                                    "procedures_data" => procedures_data.pluck(:procedure_id, :procedurename, :procedureside, :procedurestage),
                                    "radiology_investigations" => radiology_investigation_data.pluck(:investigation_id, :investigationname, :investigationfullcode, :laterality, :loinccode),
                                    "laboratory_investigations" => laboratory_investigation_data.pluck(:investigation_id, :investigationname, :investigationfullcode, :loinc_class, :loinc_code),
                                    "ophthalmology_investigations" => ophthalmology_investigation_data.pluck(:investigation_id, :investigationname, :investigationfullcode, :investigationside),
                                    "diagnoses" => diagnosis_data.pluck(:icddiagnosiscode, :diagnosisname),
                                    "systemic_history" => history_array,
                                    "eye_drop_allergies" => eye_drop_allergy_array]

          patient_opd_data = patient_diagnosis.try(:opd_data).to_a
          patient_ipd_data = patient_diagnosis.try(:ipd_data).to_a

          # patient_opd_data << new_diagnosis_data
          eval('patient_' + path + '_data << new_diagnosis_data')

          if patient_diagnosis.present?
            patient_diagnosis[:last_updated_on] = each_diagnosis.entry_datetime
            patient_diagnosis[:facility_ids] << record.facility_id.to_s
            patient_diagnosis[:entered_by_ids] << each_diagnosis.try(:entered_by_id)
            patient_diagnosis[:advised_by_ids] << advised_by_id
            patient_diagnosis[:patient_dob_year] = patient.try(:dob_year)
            patient_diagnosis[:patient_dob_month] = patient.try(:dob_month)
            patient_diagnosis[:patient_dob_day] = patient.try(:dob_day)
            patient_diagnosis[:patient_dob] = patient.try(:dob)
            patient_diagnosis[:patient_gender] = patient.try(:gender)
            patient_diagnosis[:patient_mrn] = patient.try(:patient_mrn)
            patient_diagnosis[:patient_identifier_id] = patient.try(:patient_identifier_id)
            patient_diagnosis[:systemic_history_name] = only_names.present? ? only_names.uniq : [nil]
            patient_diagnosis[:eye_drop_allergy_name] = eye_drop_allergy_only_names.present? ? eye_drop_allergy_only_names.uniq : [nil]
            patient_diagnosis.update(opd_data: patient_opd_data, ipd_data: patient_ipd_data)
          else
            patient_diagnosis = PatientDiagnosis.new
            if icd_diagnosis.try(:has_laterality) == true
              patient_diagnosis[:laterality] = icd_diagnosis.lateralitylabel.try(:capitalize)
            end
            search_code_array = icd_diagnosis.originatingcodes.map { |el| el[1] }
            search_code_array << each_diagnosis.icddiagnosiscode
            patient_diagnosis[:last_updated_on] = each_diagnosis.entry_datetime
            patient_diagnosis[:search_code_array] = search_code_array
            patient_diagnosis[:opd_data] = patient_opd_data
            patient_diagnosis[:ipd_data] = patient_ipd_data
            patient_diagnosis[:code] = each_diagnosis.icddiagnosiscode
            patient_diagnosis[:diagnosisname] = each_diagnosis.diagnosisoriginalname || each_diagnosis.diagnosisname
            patient_diagnosis[:patient_id] = patient_id
            patient_diagnosis[:patient_name] = patient.try(:fullname)
            patient_diagnosis[:patient_dob_year] = patient.try(:dob_year)
            patient_diagnosis[:patient_dob_month] = patient.try(:dob_month)
            patient_diagnosis[:patient_dob_day] = patient.try(:dob_day)
            patient_diagnosis[:patient_dob] = patient.try(:dob)
            patient_diagnosis[:patient_gender] = patient.try(:gender)
            patient_diagnosis[:patient_mrn] = patient.try(:patient_mrn)
            patient_diagnosis[:patient_identifier_id] = patient.try(:patient_identifier_id)
            patient_diagnosis[:organisation_id] = organisation_id
            patient_diagnosis[:facility_ids] = [record.facility_id.to_s]
            patient_diagnosis[:entered_by_ids] = [each_diagnosis.try(:entered_by_id)]
            patient_diagnosis[:advised_by_ids] = [advised_by_id]
            patient_diagnosis[:systemic_history_name] = only_names.present? ? only_names.uniq : [nil]
            patient_diagnosis[:eye_drop_allergy_name] = eye_drop_allergy_only_names.present? ? eye_drop_allergy_only_names.uniq : [nil]
            patient_diagnosis.save!
          end

        end
      end
    end
  end
end
