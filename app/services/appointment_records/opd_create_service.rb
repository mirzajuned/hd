module AppointmentRecords
  module OpdCreateService
    def self.call(record)
      appointment_record = AppointmentRecord.find_by(appointment_id: record.appointmentid)
      if appointment_record.present? # AppointmentRecord Present
        if appointment_record.opd_record_ids.include?(record.id) # AppointmentRecord Present and this "record" Linked
          # Embedded Diagnosis Fields
          record_diagnosis_ids = record.try(:diagnosislist).pluck(:id).map(&:to_s)
          appointment_record_diagnosis_ids = appointment_record.diagnoses.pluck(:opd_diagnosis_id).map(&:to_s)

          record.try(:diagnosislist).each do |diagnosis|
            if appointment_record_diagnosis_ids.include?(diagnosis.id.to_s)
              new_diagnosis = appointment_record.diagnoses.find_by(opd_diagnosis_id: diagnosis.id.to_s)
            else
              new_diagnosis = appointment_record.diagnoses.new
            end
            diagnosis_params(new_diagnosis, record, diagnosis)

            new_diagnosis.save
          end

          appointment_record.diagnoses.where(record_id: record.id.to_s).each do |diagnosis|
            unless record_diagnosis_ids.include?(diagnosis.opd_diagnosis_id.to_s)
              diagnosis.destroy
            end
          end
          # Diagnosis Ends

          # Embedded Procedure Fields
          record_procedure_ids = record.try(:procedure).pluck(:id).map(&:to_s)
          appointment_record_procedure_ids = appointment_record.procedures.pluck(:opd_procedure_id).map(&:to_s)

          record.try(:procedure).each do |procedure|
            if appointment_record_procedure_ids.include?(procedure.id.to_s)
              new_procedure = appointment_record.procedures.find_by(opd_procedure_id: procedure.id.to_s)
            else
              new_procedure = appointment_record.procedures.new
            end
            procedure_params(new_procedure, record, procedure)

            new_procedure.save
          end

          appointment_record.procedures.where(record_id: record.id.to_s).each do |procedure|
            unless record_procedure_ids.include?(procedure.opd_procedure_id.to_s)
              procedure.destroy
            end
          end
          # Procedure Ends

          # Embedded Ophthal Investifation Fields
          record_ophthal_investigation_ids = record.try(:ophthalinvestigationlist).pluck(:id).map(&:to_s)
          appointment_record_ophthal_investigation_ids = appointment_record.ophthal_investigations.pluck(:opd_investigation_id).map(&:to_s)

          record.try(:ophthalinvestigationlist).each do |ophthal_investigation|
            if appointment_record_ophthal_investigation_ids.include?(ophthal_investigation.id.to_s)
              new_ophthal_investigation = appointment_record.ophthal_investigations.find_by(opd_investigation_id: ophthal_investigation.id.to_s)
            else
              new_ophthal_investigation = appointment_record.ophthal_investigations.new
            end
            ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)

            new_ophthal_investigation.save
          end

          appointment_record.ophthal_investigations.where(record_id: record.id.to_s).each do |ophthal_investigation|
            unless record_ophthal_investigation_ids.include?(ophthal_investigation.opd_investigation_id.to_s)
              ophthal_investigation.destroy
            end
          end
          # Ophthal Investifation Ends

          # Embedded Laboratory Investifation Fields
          record_laboratory_investigation_ids = record.try(:addedlaboratoryinvestigationlist).pluck(:id).map(&:to_s)
          appointment_record_laboratory_investigation_ids = appointment_record.laboratory_investigations.pluck(:opd_investigation_id).map(&:to_s)

          record.try(:addedlaboratoryinvestigationlist).each do |laboratory_investigation|
            if appointment_record_laboratory_investigation_ids.include?(laboratory_investigation.id.to_s)
              new_laboratory_investigation = appointment_record.laboratory_investigations.find_by(opd_investigation_id: laboratory_investigation.id.to_s)
            else
              new_laboratory_investigation = appointment_record.laboratory_investigations.new
            end
            laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

            new_laboratory_investigation.save
          end

          appointment_record.laboratory_investigations.where(record_id: record.id.to_s).each do |laboratory_investigation|
            unless record_laboratory_investigation_ids.include?(laboratory_investigation.opd_investigation_id.to_s)
              laboratory_investigation.destroy
            end
          end
          # Laboratory Investifation Ends

          # Embedded Radiology Investifation Fields
          record_radiology_investigation_ids = record.try(:investigationlist).pluck(:id).map(&:to_s)
          appointment_record_radiology_investigation_ids = appointment_record.radiology_investigations.pluck(:opd_investigation_id).map(&:to_s)

          record.try(:investigationlist).each do |radiology_investigation|
            if appointment_record_radiology_investigation_ids.include?(radiology_investigation.id.to_s)
              new_radiology_investigation = appointment_record.radiology_investigations.find_by(opd_investigation_id: radiology_investigation.id.to_s)
            else
              new_radiology_investigation = appointment_record.radiology_investigations.new
            end
            radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

            new_radiology_investigation.save
          end

          appointment_record.radiology_investigations.where(record_id: record.id.to_s).each do |radiology_investigation|
            unless record_radiology_investigation_ids.include?(radiology_investigation.opd_investigation_id.to_s)
              radiology_investigation.destroy
            end
          end
          # Radiology Investifation Ends
        else # AppointmentRecord Present but this "record" not Linked
          appointment_record.opd_record_ids << record.id
          appointment_record[:opd_record_ids] = appointment_record.opd_record_ids.uniq

          # Embedded Diagnosis Fields
          record.try(:diagnosislist).each do |diagnosis|
            new_diagnosis = appointment_record.diagnoses.new
            diagnosis_params(new_diagnosis, record, diagnosis)

            new_diagnosis.save
          end
          # Diagnosis Ends

          # Embedded Procedure Fields
          record.try(:procedure).each do |procedure|
            new_procedure = appointment_record.procedures.new
            procedure_params(new_procedure, record, procedure)

            new_procedure.save
          end
          # Procedure Ends

          # Embedded Ophthal Investigation Fields
          record.try(:ophthalinvestigationlist).each do |ophthal_investigation|
            new_ophthal_investigation = appointment_record.ophthal_investigations.new
            ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)

            new_ophthal_investigation.save
          end
          # Ophthal Investigation Ends

          # Embedded Laboratory Investigation Fields
          record.try(:addedlaboratoryinvestigationlist).each do |laboratory_investigation|
            new_laboratory_investigation = appointment_record.laboratory_investigations.new
            laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

            new_laboratory_investigation.save
          end
          # Laboratory Investigation Ends

          # Embedded Radiology Investigation Fields
          record.try(:investigationlist).each do |radiology_investigation|
            new_radiology_investigation = appointment_record.radiology_investigations.new
            radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

            new_radiology_investigation.save
          end
          # Radiology Investigation Ends

          appointment_record.save!
        end
      else # AppointmentRecord not Present
        appointment_record = AppointmentRecord.new
        appointment_record[:appointment_id] = record.appointmentid
        appointment_record.opd_record_ids << record.id
        appointment_record[:opd_record_ids] = appointment_record.opd_record_ids.uniq
        appointment_record[:procedures] = []
        appointment_record[:diagnoses] = []
        appointment_record[:ophthal_investigations] = []
        appointment_record[:laboratory_investigations] = []
        appointment_record[:radiology_investigations] = []

        # Embedded Diagnosis Fields
        record.try(:diagnosislist).each do |diagnosis|
          new_diagnosis = appointment_record.diagnoses.new
          diagnosis_params(new_diagnosis, record, diagnosis)

          appointment_record[:diagnoses] << new_diagnosis
        end
        # Diagnosis Ends

        # Embedded Procedure Fields
        record.try(:procedure).each do |procedure|
          new_procedure = appointment_record.procedures.new
          procedure_params(new_procedure, record, procedure)

          appointment_record[:procedures] << new_procedure
        end
        # Procedure Ends

        # Embedded Ophthal Investigation Fields
        record.try(:ophthalinvestigationlist).each do |ophthal_investigation|
          new_ophthal_investigation = appointment_record.ophthal_investigations.new
          ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)

          appointment_record[:ophthal_investigations] << new_ophthal_investigation
        end
        # Ophthal Investigation Ends

        # Embedded Laboratory Investigation Fields
        record.try(:addedlaboratoryinvestigationlist).each do |laboratory_investigation|
          new_laboratory_investigation = appointment_record.laboratory_investigations.new
          laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

          appointment_record[:laboratory_investigations] << new_laboratory_investigation
        end
        # Laboratory Investigation Ends

        # Embedded Radiology Investigation Fields
        record.try(:investigationlist).each do |radiology_investigation|
          new_radiology_investigation = appointment_record.radiology_investigations.new
          radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

          appointment_record[:radiology_investigations] << new_radiology_investigation
        end
        # Radiology Investigation Ends

        appointment_record.save!
      end
    end

    private

    def self.diagnosis_params(new_diagnosis, record, diagnosis)
      new_diagnosis[:record_id] = record.id
      new_diagnosis[:opd_diagnosis_id] = diagnosis.id
      new_diagnosis[:diagnosisname] = diagnosis.diagnosisname
      new_diagnosis[:diagnosisoriginalname] = diagnosis.diagnosisoriginalname
      new_diagnosis[:icddiagnosiscode] = diagnosis.icddiagnosiscode
      new_diagnosis[:saperatedicddiagnosiscode] = diagnosis.saperatedicddiagnosiscode
      new_diagnosis[:icddiagnosiscodelength] = diagnosis.icddiagnosiscodelength
      new_diagnosis[:icd_type] = diagnosis.icd_type

      new_diagnosis[:entered_by] = diagnosis.entered_by
      new_diagnosis[:entered_by_id] = diagnosis.entered_by_id
      new_diagnosis[:entered_datetime] = diagnosis.entry_datetime
      new_diagnosis[:entered_at_facility] = diagnosis.entered_at_facility
      new_diagnosis[:entered_at_facility_id] = diagnosis.entered_at_facility_id

      new_diagnosis[:is_advised] = true
      new_diagnosis[:advised_by] = diagnosis.advised_by
      new_diagnosis[:advised_by_id] = diagnosis.advised_by_id
      new_diagnosis[:advised_datetime] = diagnosis.entry_datetime
      new_diagnosis[:advised_at_facility] = diagnosis.advised_at_facility
      new_diagnosis[:advised_at_facility_id] = diagnosis.advised_at_facility_id
    end

    def self.procedure_params(new_procedure, record, procedure)
      if procedure.procedurestage == "A"
        stage = "Advised"
      elsif procedure.procedurestage == "P"
        stage = "Performed"
      end

      new_procedure[:record_id] = record.id
      new_procedure[:opd_procedure_id] = procedure.id
      new_procedure[:procedurestage] = stage
      new_procedure[:procedurename] = procedure.procedurename
      new_procedure[:procedure_id] = procedure.procedure_id
      new_procedure[:procedureside] = procedure.procedureside
      new_procedure[:procedurefullcode] = procedure.procedurefullcode
      new_procedure[:procedure_type] = procedure.procedure_type

      new_procedure[:entered_by_id] = procedure.entered_by_id
      new_procedure[:entered_by] = procedure.entered_by
      new_procedure[:entered_datetime] = procedure.entered_datetime
      new_procedure[:entered_from] = 'opd_record'
      new_procedure[:entered_at_facility_id] = procedure.entered_at_facility_id
      new_procedure[:entered_at_facility] = procedure.entered_at_facility

      new_procedure[:is_advised] = true
      new_procedure[:advised_by] = procedure.advised_by
      new_procedure[:advised_by_id] = procedure.advised_by_id
      new_procedure[:advised_datetime] = procedure.advised_datetime
      new_procedure[:advised_at_facility] = procedure.advised_at_facility
      new_procedure[:advised_at_facility_id] = procedure.advised_at_facility_id

      if procedure.procedurestage == "P"
        new_procedure[:is_performed] = true
        new_procedure[:performed_by_id] = procedure.performed_by_id
        new_procedure[:performed_by] = procedure.performed_by
        new_procedure[:performed_datetime] = procedure.performed_datetime
        new_procedure[:performed_from] = 'opd_record'
        new_procedure[:performed_at_facility_id] = procedure.performed_at_facility_id
        new_procedure[:performed_at_facility] = procedure.performed_at_facility
      else
        new_procedure[:is_performed] = false
        new_procedure[:performed_by_id] = nil
        new_procedure[:performed_by] = nil
        new_procedure[:performed_at] = nil
        new_procedure[:performed_from] = nil
        new_procedure[:performed_at_facility_id] = nil
        new_procedure[:performed_at_facility] = nil
      end
    end

    def self.ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)
      if ophthal_investigation.investigationstage == "A"
        stage = "Advised"
      elsif ophthal_investigation.investigationstage == "P"
        stage = "Performed"
      end

      new_ophthal_investigation[:record_id] = record.id
      new_ophthal_investigation[:opd_investigation_id] = ophthal_investigation.id
      new_ophthal_investigation[:investigationstage] = stage
      new_ophthal_investigation[:investigationname] = ophthal_investigation.investigationname
      new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
      new_ophthal_investigation[:investigationside] = ophthal_investigation.investigationside
      new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigationfullcode
      new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type

      new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by_id
      new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by
      new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_datetime
      new_ophthal_investigation[:entered_from] = 'opd_record'
      new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id
      new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility

      new_ophthal_investigation[:is_advised] = true
      new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by
      new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by_id
      new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_datetime
      new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility
      new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id

      if ophthal_investigation.investigationstage == "P"
        new_ophthal_investigation[:is_performed] = true
        new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by_id
        new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by
        new_ophthal_investigation[:performed_datetime] = ophthal_investigation.performed_datetime
        new_ophthal_investigation[:performed_from] = 'opd_record'
        new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id
        new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility
      else
        new_ophthal_investigation[:is_performed] = false
        new_ophthal_investigation[:performed_by_id] = nil
        new_ophthal_investigation[:performed_by] = nil
        new_ophthal_investigation[:performed_at] = nil
        new_ophthal_investigation[:performed_from] = nil
        new_ophthal_investigation[:performed_at_facility_id] = nil
        new_ophthal_investigation[:performed_at_facility] = nil
      end
    end

    def self.laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)
      if laboratory_investigation.investigationstage == "A"
        stage = "Advised"
      elsif laboratory_investigation.investigationstage == "P"
        stage = "Performed"
      end

      new_laboratory_investigation[:record_id] = record.id
      new_laboratory_investigation[:opd_investigation_id] = laboratory_investigation.id
      new_laboratory_investigation[:investigationstage] = stage
      new_laboratory_investigation[:investigationname] = laboratory_investigation.investigationname
      new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
      new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigationfullcode
      new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
      new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
      new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type

      new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by_id
      new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by
      new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_datetime
      new_laboratory_investigation[:entered_from] = 'opd_record'
      new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id
      new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility

      new_laboratory_investigation[:is_advised] = true
      new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by
      new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by_id
      new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_datetime
      new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility
      new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id

      if laboratory_investigation.investigationstage == "P"
        new_laboratory_investigation[:is_performed] = true
        new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by_id
        new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by
        new_laboratory_investigation[:performed_datetime] = laboratory_investigation.performed_datetime
        new_laboratory_investigation[:performed_from] = 'opd_record'
        new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id
        new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility
      else
        new_laboratory_investigation[:is_performed] = false
        new_laboratory_investigation[:performed_by_id] = nil
        new_laboratory_investigation[:performed_by] = nil
        new_laboratory_investigation[:performed_at] = nil
        new_laboratory_investigation[:performed_from] = nil
        new_laboratory_investigation[:performed_at_facility_id] = nil
        new_laboratory_investigation[:performed_at_facility] = nil
      end
    end

    def self.radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)
      if radiology_investigation.investigationstage == "A"
        stage = "Advised"
      elsif radiology_investigation.investigationstage == "P"
        stage = "Performed"
      end

      new_radiology_investigation[:record_id] = record.id
      new_radiology_investigation[:opd_investigation_id] = radiology_investigation.id
      new_radiology_investigation[:investigationstage] = stage
      new_radiology_investigation[:investigationname] = radiology_investigation.investigationname
      new_radiology_investigation[:investigation_id] = radiology_investigation.investigation_id
      new_radiology_investigation[:investigationfullcode] = radiology_investigation.investigationfullcode
      new_radiology_investigation[:is_spine] = radiology_investigation.is_spine
      new_radiology_investigation[:laterality] = radiology_investigation.laterality
      new_radiology_investigation[:haslaterality] = radiology_investigation.haslaterality
      new_radiology_investigation[:radiologyoptions] = radiology_investigation.radiologyoptions
      new_radiology_investigation[:investigation_type] = radiology_investigation.investigation_type

      new_radiology_investigation[:entered_by_id] = radiology_investigation.entered_by_id
      new_radiology_investigation[:entered_by] = radiology_investigation.entered_by
      new_radiology_investigation[:entered_datetime] = radiology_investigation.entered_datetime
      new_radiology_investigation[:entered_from] = 'opd_record'
      new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id
      new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility

      new_radiology_investigation[:is_advised] = true
      new_radiology_investigation[:advised_by] = radiology_investigation.advised_by
      new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by_id
      new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_datetime
      new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility
      new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id

      if radiology_investigation.investigationstage == "P"
        new_radiology_investigation[:is_performed] = true
        new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by_id
        new_radiology_investigation[:performed_by] = radiology_investigation.performed_by
        new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_datetime
        new_radiology_investigation[:performed_from] = 'opd_record'
        new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id
        new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility
      else
        new_radiology_investigation[:is_performed] = false
        new_radiology_investigation[:performed_by_id] = nil
        new_radiology_investigation[:performed_by] = nil
        new_radiology_investigation[:performed_at] = nil
        new_radiology_investigation[:performed_from] = nil
        new_radiology_investigation[:performed_at_facility_id] = nil
        new_radiology_investigation[:performed_at_facility] = nil
      end
    end
  end
end
