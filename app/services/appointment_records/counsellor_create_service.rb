module AppointmentRecords
  module CounsellorCreateService
    def self.call(record)
      appointment_record = AppointmentRecord.find_by(appointment_id: record.appointment_id)
      if appointment_record.present? # AppointmentRecord Present
        if appointment_record.counsellor_record_ids.map(&:to_s).include?(record.id.to_s) # AppointmentRecord Present and this "record" Linked
          record_procedure_ids = record.procedures.pluck(:id).map(&:to_s)
          appointment_record_diagnosis_ids = appointment_record.diagnoses.pluck(:counsellor_diagnosis_id).map(&:to_s)
          appointment_record_procedure_ids = appointment_record.procedures.pluck(:counsellor_procedure_id).map(&:to_s)
          appointment_record_ophthal_investigation_ids = appointment_record.ophthal_investigations.pluck(:counsellor_ophthal_investigation_id).map(&:to_s)
          appointment_record_laboratory_investigation_ids = appointment_record.laboratory_investigations.pluck(:counsellor_laboratory_investigation_id).map(&:to_s)
          appointment_record_radiology_investigation_ids = appointment_record.radiology_investigations.pluck(:counsellor_radiology_investigation_id).map(&:to_s)

          # Embedded Diagnosis Fields (Update only Diagnosis _id)
          record.diagnoses.each do |diagnosis|
            if diagnosis.opd_diagnosis_id.present?
              new_diagnosis = appointment_record.diagnoses.find_by(opd_diagnosis_id: diagnosis.opd_diagnosis_id.to_s)
            end
            new_diagnosis[:counsellor_diagnosis_id] = diagnosis.id.to_s

            new_diagnosis.save
          end
          # Diagnosis Ends

          # Embedded Procedure Fields
          record.procedures.each do |procedure|
            if appointment_record_procedure_ids.include?(procedure.id.to_s)
              new_procedure = appointment_record.procedures.find_by(counsellor_procedure_id: procedure.id.to_s)
            else
              new_procedure = appointment_record.procedures.new
            end
            procedure_params(new_procedure, record, procedure)

            new_procedure.save
          end

          # Needs Work
          appointment_record.procedures.where(record_id: record.id.to_s).each do |procedure|
            unless record_procedure_ids.include?(procedure.counsellor_procedure_id.to_s)
              procedure.destroy
            end
          end
          # Procedure Ends

          # Embedded Ophthal Investigation Fields
          record.ophthal_investigations.each do |ophthal_investigation|
            if appointment_record_ophthal_investigation_ids.include?(ophthal_investigation.id.to_s)
              new_ophthal_investigation = appointment_record.ophthal_investigations.find_by(counsellor_ophthal_investigation_id: ophthal_investigation.id.to_s)
            else
              new_ophthal_investigation = appointment_record.ophthal_investigations.new
            end
            ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)

            new_ophthal_investigation.save
          end

          # Needs Work
          appointment_record.ophthal_investigations.where(record_id: record.id.to_s).each do |ophthal_investigation|
            unless appointment_record_ophthal_investigation_ids.include?(ophthal_investigation.counsellor_ophthal_investigation_id.to_s)
              ophthal_investigation.destroy
            end
          end
          # Ophthal Investigation Ends

          # Embedded Laboratory Investigation Fields
          record.laboratory_investigations.each do |laboratory_investigation|
            if appointment_record_laboratory_investigation_ids.include?(laboratory_investigation.id.to_s)
              new_laboratory_investigation = appointment_record.laboratory_investigations.find_by(counsellor_laboratory_investigation_id: laboratory_investigation.id.to_s)
            else
              new_laboratory_investigation = appointment_record.laboratory_investigations.new
            end
            laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

            new_laboratory_investigation.save
          end

          # Needs Work
          appointment_record.laboratory_investigations.where(record_id: record.id.to_s).each do |laboratory_investigation|
            unless appointment_record_laboratory_investigation_ids.include?(laboratory_investigation.counsellor_laboratory_investigation_id.to_s)
              laboratory_investigation.destroy
            end
          end
          # Laboratory Investigation Ends

          # Embedded Radiology Investigation Fields
          record.radiology_investigations.each do |radiology_investigation|
            if appointment_record_radiology_investigation_ids.include?(radiology_investigation.id.to_s)
              new_radiology_investigation = appointment_record.radiology_investigations.find_by(counsellor_radiology_investigation_id: radiology_investigation.id.to_s)
            else
              new_radiology_investigation = appointment_record.radiology_investigations.new
            end
            radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

            new_radiology_investigation.save
          end

          # Needs Work
          appointment_record.radiology_investigations.where(record_id: record.id.to_s).each do |radiology_investigation|
            unless appointment_record_radiology_investigation_ids.include?(radiology_investigation.counsellor_radiology_investigation_id.to_s)
              radiology_investigation.destroy
            end
          end
          # Radiology Investigation Ends
        else # AppointmentRecord Present but this "record" not Linked
          appointment_record_diagnosis_ids = appointment_record.diagnoses.pluck(:opd_diagnosis_id).map(&:to_s)
          appointment_record_procedure_ids = appointment_record.procedures.pluck(:opd_procedure_id).map(&:to_s)
          appointment_record_ophthal_investigation_ids = appointment_record.ophthal_investigations.pluck(:opd_investigation_id).map(&:to_s)
          appointment_record_laboratory_investigation_ids = appointment_record.laboratory_investigations.pluck(:opd_investigation_id).map(&:to_s)
          appointment_record_radiology_investigation_ids = appointment_record.radiology_investigations.pluck(:opd_investigation_id).map(&:to_s)

          appointment_record.counsellor_record_ids << record.id
          appointment_record[:counsellor_record_ids] = appointment_record.counsellor_record_ids.uniq

          # Embedded Diagnosis Fields (Update only Diagnosis _id)
          record.diagnoses.each do |diagnosis|
            if appointment_record_diagnosis_ids.include?(diagnosis.opd_diagnosis_id.to_s)
              new_diagnosis = appointment_record.diagnoses.find_by(opd_diagnosis_id: diagnosis.opd_diagnosis_id.to_s)
            end
            new_diagnosis[:counsellor_diagnosis_id] = diagnosis.id.to_s

            new_diagnosis.save
          end
          # Diagnosis Ends

          # Embedded Procedure Fields
          record.procedures.each do |procedure|
            if appointment_record_procedure_ids.include?(procedure.opd_procedure_id.to_s)
              new_procedure = appointment_record.procedures.find_by(opd_procedure_id: procedure.opd_procedure_id.to_s)
            else
              new_procedure = appointment_record.procedures.new
            end
            procedure_params(new_procedure, record, procedure)

            new_procedure.save
          end
          # Procedure Ends

          # Embedded Ophthal Investigation Fields
          record.ophthal_investigations.each do |ophthal_investigation|
            if appointment_record_ophthal_investigation_ids.include?(ophthal_investigation.opd_investigation_id.to_s)
              new_ophthal_investigation = appointment_record.ophthal_investigations.find_by(opd_investigation_id: ophthal_investigation.opd_investigation_id.to_s)
            else
              new_ophthal_investigation = appointment_record.ophthal_investigations.new
            end
            ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)

            new_ophthal_investigation.save
          end
          # Ophthal Investigation Ends

          # Embedded Laboratory Investigation Fields
          record.laboratory_investigations.each do |laboratory_investigation|
            if appointment_record_laboratory_investigation_ids.include?(laboratory_investigation.opd_investigation_id.to_s)
              new_laboratory_investigation = appointment_record.laboratory_investigations.find_by(opd_investigation_id: laboratory_investigation.opd_investigation_id.to_s)
            else
              new_laboratory_investigation = appointment_record.laboratory_investigations.new
            end
            laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)

            new_laboratory_investigation.save
          end
          # Laboratory Investigation Ends

          # Embedded Radiology Investigation Fields
          record.radiology_investigations.each do |radiology_investigation|
            if appointment_record_radiology_investigation_ids.include?(radiology_investigation.opd_investigation_id.to_s)
              new_radiology_investigation = appointment_record.radiology_investigations.find_by(opd_investigation_id: radiology_investigation.opd_investigation_id.to_s)
            else
              new_radiology_investigation = appointment_record.radiology_investigations.new
            end
            radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)

            new_radiology_investigation.save
          end
          # Radiology Investigation Ends

          appointment_record.save!
        end
      else # AppointmentRecord not Present
      end
    end

    private

    def self.procedure_params(new_procedure, record, procedure)
      new_procedure[:counsellor_procedure_id] = procedure.id
      unless procedure.opd_procedure_id.present?
        new_procedure[:id] = procedure.appointment_record_procedure_id
        new_procedure[:record_id] = record.id
        new_procedure[:procedurestage] = "Advised"
        new_procedure[:procedurename] = procedure.procedurename
        new_procedure[:procedure_id] = procedure.procedure_id
        new_procedure[:procedureside] = procedure.procedureside
        new_procedure[:procedurefullcode] = procedure.procedurefullcode
        new_procedure[:procedure_type] = procedure.procedure_type

        new_procedure[:entered_by_id] = procedure.entered_by_id
        new_procedure[:entered_by] = procedure.entered_by
        new_procedure[:entered_datetime] = procedure.entered_datetime
        new_procedure[:entered_from] = 'counsellor_record'
        new_procedure[:entered_at_facility_id] = procedure.entered_at_facility_id
        new_procedure[:entered_at_facility] = procedure.entered_at_facility

        new_procedure[:is_advised] = true
        new_procedure[:advised_by_id] = procedure.advised_by_id
        new_procedure[:advised_by] = procedure.advised_by
        new_procedure[:advised_datetime] = procedure.advised_datetime
        new_procedure[:advised_from] = 'counsellor_record'
        new_procedure[:advised_at_facility_id] = procedure.advised_at_facility_id
        new_procedure[:advised_at_facility] = procedure.advised_at_facility

        if procedure.procedurestage == "P"
          new_procedure[:is_performed] = true
          new_procedure[:performed_by_id] = procedure.performed_by_id
          new_procedure[:performed_by] = procedure.performed_by
          new_procedure[:performed_datetime] = procedure.performed_datetime
          new_procedure[:performed_from] = 'counsellor_record'
          new_procedure[:performed_at_facility_id] = procedure.performed_at_facility_id
          new_procedure[:performed_at_facility] = procedure.performed_at_facility
        elsif procedure.performed_by_id.present?
          new_procedure[:is_performed] = false
          new_procedure[:performed_by_id] = nil
          new_procedure[:performed_by] = nil
          new_procedure[:performed_datetime] = nil
          new_procedure[:performed_from] = nil
          new_procedure[:performed_at_facility_id] = nil
          new_procedure[:performed_at_facility] = nil
        end
      end

      new_procedure[:iol_present] = procedure.iol_present
      if procedure.iol_present
        new_procedure[:iol_agreed] = procedure.iol_agreed
        new_procedure[:iol_power] = procedure.iol_power
      end

      new_procedure[:is_counselled] = procedure.is_counselled
      if procedure.is_counselled
        new_procedure[:procedurestage] = "Counselled"
        new_procedure[:counselled_by_id] = procedure.counselled_by_id
        new_procedure[:counselled_by] = procedure.counselled_by
        new_procedure[:counselled_datetime] = procedure.counselled_datetime
        new_procedure[:counselled_from] = 'counsellor_record'
        new_procedure[:counselled_at_facility_id] = procedure.counselled_at_facility_id
        new_procedure[:counselled_at_facility] = procedure.counselled_at_facility
      end

      new_procedure[:is_converted] = procedure.is_converted
      if procedure.is_converted
        new_procedure[:procedurestage] = "Converted"
        new_procedure[:converted_by_id] = procedure.converted_by_id
        new_procedure[:converted_by] = procedure.converted_by
        new_procedure[:converted_datetime] = procedure.converted_datetime
        new_procedure[:converted_from] = 'counsellor_record'
        new_procedure[:converted_at_facility_id] = procedure.converted_at_facility_id
        new_procedure[:converted_at_facility] = procedure.converted_at_facility
      end

      new_procedure[:is_removed] = procedure.is_removed
      if procedure.is_removed
        new_procedure[:procedurestage] = "Removed"
        new_procedure[:removed_by_id] = procedure.removed_by_id
        new_procedure[:removed_by] = procedure.removed_by
        new_procedure[:removed_datetime] = procedure.removed_datetime
        new_procedure[:removed_from] = 'counsellor_record'
        new_procedure[:removed_at_facility_id] = procedure.removed_at_facility_id
        new_procedure[:removed_at_facility] = procedure.removed_at_facility
      end
    end

    def self.ophthal_investigation_params(new_ophthal_investigation, record, ophthal_investigation)
      new_ophthal_investigation[:counsellor_ophthal_investigation_id] = ophthal_investigation.id
      unless ophthal_investigation.opd_investigation_id.present?
        new_ophthal_investigation[:id] = ophthal_investigation.appointment_record_ophthal_investigation_id
        new_ophthal_investigation[:record_id] = record.id
        new_ophthal_investigation[:investigationstage] = "Advised"
        new_ophthal_investigation[:investigationname] = ophthal_investigation.investigationname
        new_ophthal_investigation[:investigation_id] = ophthal_investigation.investigation_id
        new_ophthal_investigation[:investigationside] = ophthal_investigation.investigationside
        new_ophthal_investigation[:investigationfullcode] = ophthal_investigation.investigationfullcode
        new_ophthal_investigation[:investigation_type] = ophthal_investigation.investigation_type

        new_ophthal_investigation[:entered_by_id] = ophthal_investigation.entered_by_id
        new_ophthal_investigation[:entered_by] = ophthal_investigation.entered_by
        new_ophthal_investigation[:entered_datetime] = ophthal_investigation.entered_datetime
        new_ophthal_investigation[:entered_from] = 'counsellor_record'
        new_ophthal_investigation[:entered_at_facility_id] = ophthal_investigation.entered_at_facility_id
        new_ophthal_investigation[:entered_at_facility] = ophthal_investigation.entered_at_facility

        new_ophthal_investigation[:is_advised] = true
        new_ophthal_investigation[:advised_by_id] = ophthal_investigation.advised_by_id
        new_ophthal_investigation[:advised_by] = ophthal_investigation.advised_by
        new_ophthal_investigation[:advised_datetime] = ophthal_investigation.advised_datetime
        new_ophthal_investigation[:advised_from] = 'counsellor_record'
        new_ophthal_investigation[:advised_at_facility_id] = ophthal_investigation.advised_at_facility_id
        new_ophthal_investigation[:advised_at_facility] = ophthal_investigation.advised_at_facility

        if ophthal_investigation.ophthal_investigationstage == "P"
          new_ophthal_investigation[:is_performed] = true
          new_ophthal_investigation[:performed_by_id] = ophthal_investigation.performed_by_id
          new_ophthal_investigation[:performed_by] = ophthal_investigation.performed_by
          new_ophthal_investigation[:performed_datetime] = ophthal_investigation.performed_datetime
          new_ophthal_investigation[:performed_from] = 'counsellor_record'
          new_ophthal_investigation[:performed_at_facility_id] = ophthal_investigation.performed_at_facility_id
          new_ophthal_investigation[:performed_at_facility] = ophthal_investigation.performed_at_facility
        elsif ophthal_investigation.performed_by_id.present?
          new_ophthal_investigation[:is_performed] = false
          new_ophthal_investigation[:performed_by_id] = nil
          new_ophthal_investigation[:performed_by] = nil
          new_ophthal_investigation[:performed_datetime] = nil
          new_ophthal_investigation[:performed_from] = nil
          new_ophthal_investigation[:performed_at_facility_id] = nil
          new_ophthal_investigation[:performed_at_facility] = nil
        end
      end

      new_ophthal_investigation[:is_counselled] = ophthal_investigation.is_counselled
      if ophthal_investigation.is_counselled
        new_ophthal_investigation[:investigationstage] = "Counselled"
        new_ophthal_investigation[:counselled_by_id] = ophthal_investigation.counselled_by_id
        new_ophthal_investigation[:counselled_by] = ophthal_investigation.counselled_by
        new_ophthal_investigation[:counselled_datetime] = ophthal_investigation.counselled_datetime
        new_ophthal_investigation[:counselled_from] = 'counsellor_record'
        new_ophthal_investigation[:counselled_at_facility_id] = ophthal_investigation.counselled_at_facility_id
        new_ophthal_investigation[:counselled_at_facility] = ophthal_investigation.counselled_at_facility
      end

      new_ophthal_investigation[:is_converted] = ophthal_investigation.is_converted
      if ophthal_investigation.is_converted
        new_ophthal_investigation[:investigationstage] = "Converted"
        new_ophthal_investigation[:converted_by_id] = ophthal_investigation.converted_by_id
        new_ophthal_investigation[:converted_by] = ophthal_investigation.converted_by
        new_ophthal_investigation[:converted_datetime] = ophthal_investigation.converted_datetime
        new_ophthal_investigation[:converted_from] = 'counsellor_record'
        new_ophthal_investigation[:converted_at_facility_id] = ophthal_investigation.converted_at_facility_id
        new_ophthal_investigation[:converted_at_facility] = ophthal_investigation.converted_at_facility
      end

      new_ophthal_investigation[:is_removed] = ophthal_investigation.is_removed
      if ophthal_investigation.is_removed
        new_ophthal_investigation[:investigationstage] = "Removed"
        new_ophthal_investigation[:removed_by_id] = ophthal_investigation.removed_by_id
        new_ophthal_investigation[:removed_by] = ophthal_investigation.removed_by
        new_ophthal_investigation[:removed_datetime] = ophthal_investigation.removed_datetime
        new_ophthal_investigation[:removed_from] = 'counsellor_record'
        new_ophthal_investigation[:removed_at_facility_id] = ophthal_investigation.removed_at_facility_id
        new_ophthal_investigation[:removed_at_facility] = ophthal_investigation.removed_at_facility
      end
    end

    def self.laboratory_investigation_params(new_laboratory_investigation, record, laboratory_investigation)
      new_laboratory_investigation[:counsellor_laboratory_investigation_id] = laboratory_investigation.id
      unless laboratory_investigation.opd_investigation_id.present?
        new_laboratory_investigation[:id] = laboratory_investigation.appointment_record_laboratory_investigation_id
        new_laboratory_investigation[:record_id] = record.id
        new_laboratory_investigation[:investigationstage] = "Advised"
        new_laboratory_investigation[:investigationname] = laboratory_investigation.investigationname
        new_laboratory_investigation[:investigation_id] = laboratory_investigation.investigation_id
        new_laboratory_investigation[:investigationfullcode] = laboratory_investigation.investigationfullcode
        new_laboratory_investigation[:loinc_class] = laboratory_investigation.loinc_class
        new_laboratory_investigation[:loinc_code] = laboratory_investigation.loinc_code
        new_laboratory_investigation[:investigation_type] = laboratory_investigation.investigation_type

        new_laboratory_investigation[:entered_by_id] = laboratory_investigation.entered_by_id
        new_laboratory_investigation[:entered_by] = laboratory_investigation.entered_by
        new_laboratory_investigation[:entered_datetime] = laboratory_investigation.entered_datetime
        new_laboratory_investigation[:entered_from] = 'counsellor_record'
        new_laboratory_investigation[:entered_at_facility_id] = laboratory_investigation.entered_at_facility_id
        new_laboratory_investigation[:entered_at_facility] = laboratory_investigation.entered_at_facility

        new_laboratory_investigation[:is_advised] = true
        new_laboratory_investigation[:advised_by_id] = laboratory_investigation.advised_by_id
        new_laboratory_investigation[:advised_by] = laboratory_investigation.advised_by
        new_laboratory_investigation[:advised_datetime] = laboratory_investigation.advised_datetime
        new_laboratory_investigation[:advised_from] = 'counsellor_record'
        new_laboratory_investigation[:advised_at_facility_id] = laboratory_investigation.advised_at_facility_id
        new_laboratory_investigation[:advised_at_facility] = laboratory_investigation.advised_at_facility

        if laboratory_investigation.laboratory_investigationstage == "P"
          new_laboratory_investigation[:is_performed] = true
          new_laboratory_investigation[:performed_by_id] = laboratory_investigation.performed_by_id
          new_laboratory_investigation[:performed_by] = laboratory_investigation.performed_by
          new_laboratory_investigation[:performed_datetime] = laboratory_investigation.performed_datetime
          new_laboratory_investigation[:performed_from] = 'counsellor_record'
          new_laboratory_investigation[:performed_at_facility_id] = laboratory_investigation.performed_at_facility_id
          new_laboratory_investigation[:performed_at_facility] = laboratory_investigation.performed_at_facility
        elsif laboratory_investigation.performed_by_id.present?
          new_laboratory_investigation[:is_performed] = false
          new_laboratory_investigation[:performed_by_id] = nil
          new_laboratory_investigation[:performed_by] = nil
          new_laboratory_investigation[:performed_datetime] = nil
          new_laboratory_investigation[:performed_from] = nil
          new_laboratory_investigation[:performed_at_facility_id] = nil
          new_laboratory_investigation[:performed_at_facility] = nil
        end
      end

      new_laboratory_investigation[:is_counselled] = laboratory_investigation.is_counselled
      if laboratory_investigation.is_counselled
        new_laboratory_investigation[:investigationstage] = "Counselled"
        new_laboratory_investigation[:counselled_by_id] = laboratory_investigation.counselled_by_id
        new_laboratory_investigation[:counselled_by] = laboratory_investigation.counselled_by
        new_laboratory_investigation[:counselled_datetime] = laboratory_investigation.counselled_datetime
        new_laboratory_investigation[:counselled_from] = 'counsellor_record'
        new_laboratory_investigation[:counselled_at_facility_id] = laboratory_investigation.counselled_at_facility_id
        new_laboratory_investigation[:counselled_at_facility] = laboratory_investigation.counselled_at_facility
      end

      new_laboratory_investigation[:is_converted] = laboratory_investigation.is_converted
      if laboratory_investigation.is_converted
        new_laboratory_investigation[:investigationstage] = "Converted"
        new_laboratory_investigation[:converted_by_id] = laboratory_investigation.converted_by_id
        new_laboratory_investigation[:converted_by] = laboratory_investigation.converted_by
        new_laboratory_investigation[:converted_datetime] = laboratory_investigation.converted_datetime
        new_laboratory_investigation[:converted_from] = 'counsellor_record'
        new_laboratory_investigation[:converted_at_facility_id] = laboratory_investigation.converted_at_facility_id
        new_laboratory_investigation[:converted_at_facility] = laboratory_investigation.converted_at_facility
      end

      new_laboratory_investigation[:is_removed] = laboratory_investigation.is_removed
      if laboratory_investigation.is_removed
        new_laboratory_investigation[:investigationstage] = "Removed"
        new_laboratory_investigation[:removed_by_id] = laboratory_investigation.removed_by_id
        new_laboratory_investigation[:removed_by] = laboratory_investigation.removed_by
        new_laboratory_investigation[:removed_datetime] = laboratory_investigation.removed_datetime
        new_laboratory_investigation[:removed_from] = 'counsellor_record'
        new_laboratory_investigation[:removed_at_facility_id] = laboratory_investigation.removed_at_facility_id
        new_laboratory_investigation[:removed_at_facility] = laboratory_investigation.removed_at_facility
      end
    end

    def self.radiology_investigation_params(new_radiology_investigation, record, radiology_investigation)
      new_radiology_investigation[:counsellor_radiology_investigation_id] = radiology_investigation.id
      unless radiology_investigation.opd_investigation_id.present?
        new_radiology_investigation[:id] = radiology_investigation.appointment_record_radiology_investigation_id
        new_radiology_investigation[:record_id] = record.id
        new_radiology_investigation[:investigationstage] = "Advised"
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
        new_radiology_investigation[:entered_from] = 'counsellor_record'
        new_radiology_investigation[:entered_at_facility_id] = radiology_investigation.entered_at_facility_id
        new_radiology_investigation[:entered_at_facility] = radiology_investigation.entered_at_facility

        new_radiology_investigation[:is_advised] = true
        new_radiology_investigation[:advised_by_id] = radiology_investigation.advised_by_id
        new_radiology_investigation[:advised_by] = radiology_investigation.advised_by
        new_radiology_investigation[:advised_datetime] = radiology_investigation.advised_datetime
        new_radiology_investigation[:advised_from] = 'counsellor_record'
        new_radiology_investigation[:advised_at_facility_id] = radiology_investigation.advised_at_facility_id
        new_radiology_investigation[:advised_at_facility] = radiology_investigation.advised_at_facility

        if radiology_investigation.radiology_investigationstage == "P"
          new_radiology_investigation[:is_performed] = true
          new_radiology_investigation[:performed_by_id] = radiology_investigation.performed_by_id
          new_radiology_investigation[:performed_by] = radiology_investigation.performed_by
          new_radiology_investigation[:performed_datetime] = radiology_investigation.performed_datetime
          new_radiology_investigation[:performed_from] = 'counsellor_record'
          new_radiology_investigation[:performed_at_facility_id] = radiology_investigation.performed_at_facility_id
          new_radiology_investigation[:performed_at_facility] = radiology_investigation.performed_at_facility
        elsif radiology_investigation.performed_by_id.present?
          new_radiology_investigation[:is_performed] = false
          new_radiology_investigation[:performed_by_id] = nil
          new_radiology_investigation[:performed_by] = nil
          new_radiology_investigation[:performed_datetime] = nil
          new_radiology_investigation[:performed_from] = nil
          new_radiology_investigation[:performed_at_facility_id] = nil
          new_radiology_investigation[:performed_at_facility] = nil
        end
      end

      new_radiology_investigation[:is_counselled] = radiology_investigation.is_counselled
      if radiology_investigation.is_counselled
        new_radiology_investigation[:investigationstage] = "Counselled"
        new_radiology_investigation[:counselled_by_id] = radiology_investigation.counselled_by_id
        new_radiology_investigation[:counselled_by] = radiology_investigation.counselled_by
        new_radiology_investigation[:counselled_datetime] = radiology_investigation.counselled_datetime
        new_radiology_investigation[:counselled_from] = 'counsellor_record'
        new_radiology_investigation[:counselled_at_facility_id] = radiology_investigation.counselled_at_facility_id
        new_radiology_investigation[:counselled_at_facility] = radiology_investigation.counselled_at_facility
      end

      new_radiology_investigation[:is_converted] = radiology_investigation.is_converted
      if radiology_investigation.is_converted
        new_radiology_investigation[:investigationstage] = "Converted"
        new_radiology_investigation[:converted_by_id] = radiology_investigation.converted_by_id
        new_radiology_investigation[:converted_by] = radiology_investigation.converted_by
        new_radiology_investigation[:converted_datetime] = radiology_investigation.converted_datetime
        new_radiology_investigation[:converted_from] = 'counsellor_record'
        new_radiology_investigation[:converted_at_facility_id] = radiology_investigation.converted_at_facility_id
        new_radiology_investigation[:converted_at_facility] = radiology_investigation.converted_at_facility
      end

      new_radiology_investigation[:is_removed] = radiology_investigation.is_removed
      if radiology_investigation.is_removed
        new_radiology_investigation[:investigationstage] = "Removed"
        new_radiology_investigation[:removed_by_id] = radiology_investigation.removed_by_id
        new_radiology_investigation[:removed_by] = radiology_investigation.removed_by
        new_radiology_investigation[:removed_datetime] = radiology_investigation.removed_datetime
        new_radiology_investigation[:removed_from] = 'counsellor_record'
        new_radiology_investigation[:removed_at_facility_id] = radiology_investigation.removed_at_facility_id
        new_radiology_investigation[:removed_at_facility] = radiology_investigation.removed_at_facility
      end
    end
  end
end
