module PatientProcedures
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

      # To delete the procedure which is removed from the opdrecord without affecting the previously made entries for that PatientProcedure record.
      patient_procedures = eval('PatientProcedure.elem_match(' + path + '_data: { record_id: record.id.to_s})')
      patient_procedures.each do |patient_procedure|
        data = eval('patient_procedure.' + path + '_data')
        patient_data = data.select { |set| set["record_id"] != record.id.to_s }
        eval('patient_procedure.update(' + path + '_data: patient_data)')

        if patient_procedure.try(:opd_data).to_a.empty? && patient_procedure.try(:ipd_data).to_a.empty?
          patient_procedure.delete
        end
      end

      patient_id = record.patientid || record.patient_id
      patient = Patient.find_by(id: patient_id)

      procedures_data.each do |procedure|
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

        patient_procedure = PatientProcedure.find_by(code: procedure.try(:procedurefullcode), patient_id: patient_id, side: procedure.try(:procedureside))

        new_procedure_data = Hash["record_id" => record.id.to_s,
                                  "name" => procedure.try(:procedurename),
                                  "code" => procedure.try(:procedurefullcode),
                                  "stage" => procedure.try(:procedurestage),
                                  "side" => procedure.try(:procedureside),
                                  "entered_by" => procedure.try(:entered_by),
                                  "entered_by_id" => procedure.try(:entered_by_id),
                                  "advised_by" => advised_by,
                                  "advised_by_id" => advised_by_id,
                                  "entered_at_facility" => procedure.try(:entered_at_facility),
                                  "entered_at_facility_id" => procedure.try(:entered_at_facility_id),
                                  "entered_datetime" => procedure.try(:entered_datetime),
                                  "updated_by" => procedure.try(:updated_by),
                                  "updated_by_id" => procedure.try(:updated_by_id),
                                  "updated_at_facility" => procedure.try(:updated_at_facility),
                                  "updated_at_facility_id" => procedure.try(:updated_at_facility_id),
                                  "updated_datetime" => procedure.try(:updated_datetime),
                                  "performed_by" => procedure.try(:performed_by),
                                  "performed_by_id" => procedure.try(:performed_by_id),
                                  "performed_at_facility" => procedure.try(:performed_at_facility),
                                  "performed_at_facility_id" => procedure.try(:performed_at_facility_id),
                                  "performed_datetime" => procedure.try(:performed_datetime),
                                  "procedure_comment" => procedure.try(:procedure_comment),
                                  "users_comment" => procedure.try(:users_comment),

                                  "procedures" => procedures_data.pluck(:procedure_id, :procedurename, :procedureside, :procedurestage),
                                  "radiology_investigations" => radiology_investigation_data.pluck(:investigation_id, :investigationname, :investigationfullcode, :laterality, :loinccode),
                                  "laboratory_investigations" => laboratory_investigation_data.pluck(:investigation_id, :investigationname, :investigationfullcode, :loinc_class, :loinc_code),
                                  "ophthalmology_investigations" => ophthalmology_investigation_data.pluck(:investigation_id, :investigationname, :investigationfullcode, :investigationside),
                                  "diagnoses" => diagnosis_data.pluck(:icddiagnosiscode, :diagnosisname),
                                  "systemic_history" => history_array,
                                  "eye_drop_allergies" => eye_drop_allergy_array]

        patient_opd_data = patient_procedure.try(:opd_data).to_a
        patient_ipd_data = patient_procedure.try(:ipd_data).to_a
        eval('patient_' + path + '_data << new_procedure_data')

        if procedure.try(:procedureside).to_s == '18944008'
          procedure_laterality = 'Right'
        elsif procedure.try(:procedureside).to_s == '8966001'
          procedure_laterality = 'Left'
        else
          procedure_laterality = 'Bilateral'
        end

        if patient_procedure.present?
          patient_procedure[:last_updated_on] = procedure.entered_datetime
          patient_procedure[:facility_ids] << record.facility_id.to_s
          patient_procedure[:entered_by_ids] << procedure.entered_by_id
          patient_procedure[:advised_by_ids] << advised_by_id
          patient_procedure[:side] = procedure.try(:procedureside)
          patient_procedure[:laterality] = procedure_laterality
          patient_procedure[:patient_name] = patient.try(:fullname)
          patient_procedure[:patient_dob_year] = patient.try(:dob_year)
          patient_procedure[:patient_dob_month] = patient.try(:dob_month)
          patient_procedure[:patient_dob_day] = patient.try(:dob_day)
          patient_procedure[:patient_dob] = patient.try(:dob)
          patient_procedure[:patient_gender] = patient.try(:gender)
          patient_procedure[:patient_mrn] = patient.try(:patient_mrn)
          patient_procedure[:patient_identifier_id] = patient.try(:patient_identifier_id)
          patient_procedure[:systemic_history_name] = only_names.present? ? only_names.uniq : [nil]
          patient_procedure[:procedure_stage] = procedure.try(:procedurestage)
          patient_procedure[:eye_drop_allergy_name] = eye_drop_allergy_only_names.present? ? eye_drop_allergy_only_names.uniq : [nil]
          patient_procedure.update(opd_data: patient_opd_data, ipd_data: patient_ipd_data)
        else
          patient_procedure = PatientProcedure.new
          patient_procedure[:opd_data] = patient_opd_data
          patient_procedure[:ipd_data] = patient_ipd_data
          patient_procedure[:code] = procedure.try(:procedurefullcode)
          patient_procedure[:side] = procedure.try(:procedureside)
          patient_procedure[:laterality] = procedure_laterality
          patient_procedure[:last_updated_on] = procedure.entered_datetime
          patient_procedure[:procedurename] = procedure.try(:procedurename)
          patient_procedure[:patient_id] = patient_id
          patient_procedure[:patient_name] = patient.try(:fullname)
          patient_procedure[:patient_dob_year] = patient.try(:dob_year)
          patient_procedure[:patient_dob_month] = patient.try(:dob_month)
          patient_procedure[:patient_dob_day] = patient.try(:dob_day)
          patient_procedure[:patient_dob] = patient.try(:dob)
          patient_procedure[:patient_gender] = patient.try(:patient_gender)
          patient_procedure[:patient_mrn] = patient.try(:patient_mrn)
          patient_procedure[:patient_identifier_id] = patient.try(:patient_identifier_id)
          patient_procedure[:organisation_id] = organisation_id
          patient_procedure[:facility_ids] = [record.facility_id.to_s]
          patient_procedure[:entered_by_ids] = [procedure.try(:entered_by_id)]
          patient_procedure[:advised_by_ids] = [advised_by_id]
          patient_procedure[:systemic_history_name] = only_names.present? ? only_names.uniq : [nil]
          patient_procedure[:procedure_stage] = procedure.try(:procedurestage)
          patient_procedure[:eye_drop_allergy_name] = eye_drop_allergy_only_names.present? ? eye_drop_allergy_only_names.uniq : [nil]
          patient_procedure.save!
        end
      end
    end
  end
end
