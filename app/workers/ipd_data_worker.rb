class IpdDataWorker
  attr_accessor :record_id
  def initialize(id)
    @record_id = id
  end

  def call
    opdrecord = OpdRecord.find_by(:id => "#{record_id}")
    # opdrecord.appointmentid
    appointment = Appointment.find_by(:id => opdrecord.try(:appointmentid))
    if appointment
      if appointment.facility
        org_id = Facility.find_by(:id => appointment.facility_id).try(:organisation_id)
        patient = Patient.find_by(id: opdrecord.patientid)
        if Facility.find_by(:id => appointment.facility_id).clinical_workflow
          workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
          doctor = User.find_by(:id => workflow.try(:consultant_ids).try(:last))
        else
          doctor = User.find_by(:id => appointment.consultant_id.to_s)
        end
        if opdrecord.templatetype == "freeform"
          freeform = create_freeform_data(opdrecord)
        else
          freeform = { :diagnosis => "", :investigation => "", :history => "", :procedure => "", :examination => "", :laboratory_investigation => "", :radiology_investigation => "" }
        end
        # examination= []
        # investigation = get_investigation(opdrecord)
        r_visualacuity = get_r_visualacuity(opdrecord)
        l_visualacuity = get_l_visualacuity(opdrecord)
        r_iop = get_r_iop(opdrecord)
        l_iop = get_l_iop(opdrecord)
        r_appendage = get_r_appendage(opdrecord)
        l_appendage = get_l_appendage(opdrecord)
        r_anterior_segment = get_r_anterior_segment(opdrecord)
        l_anterior_segment = get_l_anterior_segment(opdrecord)
        r_posterior_segment = get_r_posterior_segment(opdrecord)
        l_posterior_segment = get_l_posterior_segment(opdrecord)
        r_eom = get_r_eom(opdrecord)
        l_eom = get_l_eom(opdrecord)
        # history
        history = get_history_attributes(opdrecord, patient)
        patient_opd = PatientOpd.find_by(id: opdrecord.patientid)

        if patient_opd
          if patient_opd.records.count > 0
            # create procedure and diagnosis tables
            create_diagnosis(opdrecord, appointment, doctor, patient_opd)
            create_procedure(opdrecord, appointment, doctor, patient_opd)
            update_record = patient_opd.records.find_by(id: opdrecord.id)
            if update_record
              examination = Hash["r_refraction" => r_visualacuity, "l_refraction" => l_visualacuity, "r_iop" => r_iop, "l_iop" => l_iop, "r_appendage" => r_appendage, "l_appendage" => l_appendage, "r_anterior_segment" => r_anterior_segment, "l_anterior_segment" => l_anterior_segment, "r_posterior_segment" => r_posterior_segment, "l_posterior_segment" => l_posterior_segment, "r_eom" => r_eom, "l_eom" => l_eom]
              update_record.update(examination: examination, history: history, freeform: freeform)
              create_or_update_investigations(opdrecord, patient_opd, update_record)
            else
              new_record = patient_opd.records.new
              # create procedure and diagnosis tables
              create_new_record(new_record, opdrecord, appointment, doctor, history, freeform)
              create_or_update_investigations(opdrecord, patient_opd, new_record)
            end
          else
            new_record = patient_opd.records.new
            # create procedure and diagnosis tables
            create_new_record(new_record, opdrecord, appointment, doctor, history, freeform)
            create_or_update_investigations(opdrecord, patient_opd, new_record)
          end
          create_diagnosis(opdrecord, appointment, doctor, patient_opd)
          create_procedure(opdrecord, appointment, doctor, patient_opd)
        else
          new_patient_opd = PatientOpd.new
          new_patient_opd.id = opdrecord.patientid
          new_patient_opd.created_date = opdrecord.created_at
          first_record = new_patient_opd.records.new
          # create procedure and diagnosis tables
          create_new_record(first_record, opdrecord, appointment, doctor, history, freeform)
          new_patient_opd.save
          create_or_update_investigations(opdrecord, new_patient_opd, new_patient_opd.records[0])
          create_diagnosis(opdrecord, appointment, doctor, new_patient_opd)
          create_procedure(opdrecord, appointment, doctor, new_patient_opd)
        end
      end
    end
  end

  def create_freeform_data(opdrecord)
    freeform = {}
    freeform[:diagnosis] = opdrecord.diagnosiscomments
    freeform[:investigation] = opdrecord.plan
    freeform[:history] = opdrecord.clincalevaluation
    freeform[:examination] = opdrecord.examination
    freeform[:laboratory_investigation] = opdrecord.laboratorycomments
    freeform[:radiology_investigation] = opdrecord.radiologycomments
    if opdrecord.free_procedure.present?
      freeform[:procedure] = opdrecord.free_procedure
    else
      freeform[:procedure] = opdrecord.procedurecomments
    end
    freeform
  end

  def create_procedure(opdrecord, appointment, doctor, patient_opd)
    if opdrecord.templatetype == "freeform" and opdrecord.specalityid == "309989009"
      all_free_form_procedures = patient_opd.procedures.where(record_id: opdrecord.id, :templatetype => "freeform")
      if all_free_form_procedures.count > 0
        all_free_form_procedures.destroy
      end
      patient_opd.procedures.create(procedurename: opdrecord.free_procedure, procedureside: "", procedurestatus: "", patient_id: opdrecord.patientid, source: "OPD", facility_id: appointment.facility_id, record_id: opdrecord.id, counselling: opdrecord.counselling, templatetype: opdrecord.templatetype, advising_doctor: doctor.id, advised_time: Time.current, specalityname: opdrecord.specalityname, procedurestage: "")
    elsif opdrecord.specalityid == "309989009"
      if ["knee", "shoulder", "elbow", "footankle", "wristhand", "hip", "trauma", "spine"].include? opdrecord.templatetype
        ortho_proc = patient_opd.procedures.where(record_id: opdrecord.id, :templatetype.in => ["knee", "shoulder", "elbow", "footankle", "wristhand", "hip", "trauma", "spine"])
        if ortho_proc.count > 0
          ortho_proc.destroy
        end
      end
      patient_opd.procedures.create(procedurename: opdrecord.procedurecomments, procedureside: "", procedurestatus: "", patient_id: opdrecord.patientid, source: "OPD", facility_id: appointment.facility_id, record_id: opdrecord.id, counselling: opdrecord.counselling, templatetype: opdrecord.templatetype, advising_doctor: doctor.id, advised_time: Time.current, specalityname: opdrecord.specalityname, procedurestage: "")

    else
      if opdrecord.procedure
        eye_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "eye")
        quickeye_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "quickeye")
        express_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "express")
        lens_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "lens")
        trauma_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "trauma")
        orthoptics_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "orthoptics")
        freeform_procedures = patient_opd.procedures.where(record_id: opdrecord.id, templatetype: "freeform")
        if opdrecord.templatetype == "eye" and eye_procedures.count > 0
          eye_procedures.destroy
        elsif opdrecord.templatetype == "quickeye" and quickeye_procedures.count > 0
          quickeye_procedures.destroy
        elsif opdrecord.templatetype == "express" and express_procedures.count > 0
          express_procedures.destroy
        elsif opdrecord.templatetype == "lens" and lens_procedures.count > 0
          lens_procedures.destroy
        elsif opdrecord.templatetype == "trauma" and trauma_procedures.count > 0
          trauma_procedures.destroy
        elsif opdrecord.templatetype == "orthoptics" and orthoptics_procedures.count > 0
          orthoptics_procedures.destroy
        elsif opdrecord.templatetype == "freeform" and freeform_procedures.count > 0
          freeform_procedures.destroy
        end

        opdrecord.procedure.each_with_index do |procedure, i|
          created_by = opdrecord.record_histories[0].user_id
          user = User.find_by(id: created_by)
          facility = Facility.find_by(id: user.facility_ids[0])
          created_at = opdrecord.record_histories[0].try(:actiontime)
          procedure_performed = (procedure.procedurestage == 'P')
          # Entered Fields
          entered_by = user.try(:fullname)
          entered_by_id = created_by
          entered_at_facility = facility.try(:name)
          entered_at_facility_id = facility.try(:id)
          entered_datetime = created_at
          # Advised Fields
          advised_by = procedure.try(:advised_by)
          advised_by_id = procedure.try(:advised_by_id)
          advised_at_facility = procedure.try(:advised_at_facility)
          advised_at_facility_id = procedure.try(:advised_at_facility_id)
          advised_datetime = procedure.try(:advised_datetime)
          # Updated Fields
          updated_by = ""
          updated_by_id = ""
          updated_at_facility = ""
          updated_at_facility_id = ""
          updated_datetime = ""
          # Performed Fields
          performed_by = (user.try(:fullname) if procedure_performed) || ""
          performed_by_id = (created_by if procedure_performed) || ""
          performed_at_facility = (facility.try(:name) if procedure_performed) || ""
          performed_at_facility_id = (facility.try(:id) if procedure_performed) || ""
          performed_datetime = (created_at if procedure_performed) || ""
          # Comment
          procedure_comment = procedure.procedure_performed.to_s
          user_comment = ""

          if opdrecord.specalityname == "ophthalmology"
            @ipd_procedure = patient_opd.procedures.create(procedurename: procedure.procedurename, procedureside: procedure.procedureside, procedurestatus: "Advised", patient_id: opdrecord.patientid, source: "OPD", facility_id: appointment.facility_id, record_id: opdrecord.id, counselling: opdrecord.counselling, advising_doctor: doctor.try(:id), advised_time: Time.current, templatetype: opdrecord.templatetype, specalityname: opdrecord.specalityname, entered_by: entered_by, entered_by_id: entered_by_id, entered_at_facility: entered_at_facility, entered_at_facility_id: entered_at_facility_id, entered_datetime: entered_datetime, advised_by: advised_by, advised_by_id: advised_by_id, advised_at_facility: advised_at_facility, advised_at_facility_id: advised_at_facility_id, advised_datetime: advised_datetime, updated_by: updated_by, updated_by_id: updated_by_id, updated_at_facility: updated_at_facility, updated_at_facility_id: updated_at_facility_id, updated_datetime: updated_datetime, performed_by: performed_by, performed_by_id: performed_by_id, performed_at_facility: performed_at_facility, performed_at_facility_id: performed_at_facility_id, performed_datetime: performed_datetime, procedure_comment: procedure_comment, user_comment: user_comment, procedurestage: procedure.procedurestage || "A", :procedure_id => procedure.procedure_id, :procedurefullcode => procedure.procedurefullcode, procedure_type: procedure.procedure_type)
          end
        end
      end

    end
  end

  def create_diagnosis(opdrecord, appointment, doctor, patient_opd)
    # if opdrecord.templatetype == "freeform"
    #   all_free_form_diagnosis = patient_opd.diagnosis.where(record_id: opdrecord.id,:templatetype => "freeform")
    #   if all_free_form_diagnosis.count > 0
    #     all_free_form_diagnosis.destroy
    #   end
    #   patient_opd.diagnosis.create(diagnosisname: opdrecord.diagnosiscomments, source: "OPD", facility_id: appointment.facility_id, templatetype: opdrecord.templatetype, patient_id: opdrecord.patientid, record_id: opdrecord.id, advising_doctor: doctor.try(:id), advised_time: Time.current, specalityname: opdrecord.specalityname)
    # else
    if opdrecord.diagnosislist?
      all_diagnosis = patient_opd.diagnosis.where(record_id: opdrecord.id)
      if all_diagnosis.count > 0
        all_diagnosis.destroy
      end
      opdrecord.diagnosislist.each_with_index do |diagnosis, i|
        old_diagnosis = patient_opd.diagnosis.find_by(id: diagnosis.id)
        if old_diagnosis
          old_diagnosis.destroy
        end
        dia = patient_opd.diagnosis.create(diagnosis.attributes)
        dia.update(patient_id: opdrecord.patientid, source: "OPD", facility_id: appointment.facility_id, templatetype: opdrecord.templatetype, record_id: opdrecord.id, specalityname: opdrecord.specalityname, advising_doctor: doctor.try(:id), advised_time: Time.current)
      end
    end
    # end
  end

  def create_or_update_investigations(opdrecord, patient_opd, record)
    if patient_opd.records.count > 0
      patient_opd_record = patient_opd.records.find_by(id: opdrecord.id)

      if patient_opd_record
        if opdrecord.ophthalinvestigationlist.count > 0
          if patient_opd_record.ophthal_investigations_list.count > 0
            patient_opd_record.ophthal_investigations_list.where(record_id: opdrecord.id, created_from_template: true).destroy
          end

          opdrecord.ophthalinvestigationlist.each do |ophthal_investigation|
            patient_opd_record.ophthal_investigations_list.create!(billing: ophthal_investigation.billing, counselling: ophthal_investigation.counselling, investigation_id: ophthal_investigation.investigation_id, investigation_performed: ophthal_investigation.investigation_performed, investigationadviseddate: ophthal_investigation.investigationadviseddate, investigationfullcode: ophthal_investigation.investigationfullcode, investigationname: ophthal_investigation.investigationname, investigationside: ophthal_investigation.investigationside, investigationstage: ophthal_investigation.investigationstage, created_from_template: true, record_id: opdrecord.id, investigation_comment: "", investigation_val: "", doctors_remark: "")
          end

          patient_opd_record.ophthal_investigations_list.where(created_from_template: true).each do |oph_invest|
            investigation_detail = Investigation::InvestigationDetail.where(_type: "Investigation::Ophthal", opd_record_id: oph_invest.record_id.to_s, investigation_id: oph_invest.investigation_id.to_s).order(created_at: :desc)[0]

            if investigation_detail
              if investigation_detail.ehr_investigation_record_id.present?
                ehr_investigation_record = EhrInvestigation::Record.find_by(:id => investigation_detail.ehr_investigation_record_id)
                if ehr_investigation_record
                  oph_invest.update(:investigation_comment => ehr_investigation_record.investigation_comment, :investigation_val => ehr_investigation_record.investigation_val, :doctors_remark => ehr_investigation_record.doctors_remark)
                end
              end
            end
          end
        end

        if opdrecord.investigationlist.count > 0
          patient_opd_record.radiology_investigations_list.where(record_id: opdrecord.id).destroy

          opdrecord.investigationlist.each do |radiology_investigation|
            patient_opd_record.radiology_investigations_list.create!(haslaterality: radiology_investigation.haslaterality, investigation_id: radiology_investigation.investigation_id, investigation_performed: radiology_investigation.investigation_performed, investigationadviseddate: radiology_investigation.investigationadviseddate, investigationfullcode: radiology_investigation.investigationfullcode, investigationname: radiology_investigation.investigationname, investigationstage: radiology_investigation.investigationstage, is_spine: radiology_investigation.is_spine, laterality: radiology_investigation.laterality, loinccode: radiology_investigation.loinccode, radiologyoptions: radiology_investigation.radiologyoptions, created_from_template: true, record_id: opdrecord.id, investigation_comment: "", investigation_val: "", doctors_remark: "")
          end

          patient_opd_record.radiology_investigations_list.where(created_from_template: true).each do |radio_invest|
            investigation_detail = Investigation::InvestigationDetail.where(_type: "Investigation::Radiology", opd_record_id: radio_invest.record_id.to_s, investigation_id: radio_invest.investigation_id.to_s).order(created_at: :desc)[0]

            if investigation_detail
              if investigation_detail.ehr_investigation_record_id.present?
                ehr_investigation_record = EhrInvestigation::Record.find_by(id: investigation_detail.ehr_investigation_record_id)
                if ehr_investigation_record
                  radio_invest.update(investigation_comment: ehr_investigation_record.investigation_comment, investigation_val: ehr_investigation_record.investigation_val, doctors_remark: ehr_investigation_record.doctors_remark)
                end
              end
            end
          end
        end

        if opdrecord.addedlaboratoryinvestigationlist.count > 0
          patient_opd_record.laboratory_investigations_list.where(record_id: opdrecord.id).destroy

          opdrecord.addedlaboratoryinvestigationlist.each do |laboratory_investigation|
            patient_opd_record.laboratory_investigations_list.create!(investigation_id: laboratory_investigation.investigation_id, investigation_performed: laboratory_investigation.investigation_performed, investigationadviseddate: laboratory_investigation.investigationadviseddate, investigationfullcode: laboratory_investigation.investigationfullcode, investigationname: laboratory_investigation.investigationname, investigationstage: laboratory_investigation.investigationstage, loincclass: laboratory_investigation.loinc_class, loinc_code: laboratory_investigation.loinc_code, created_from_template: true, record_id: opdrecord.id, doctors_remark: "", investigation_val: "", specimen_type: "", investigation_comment: "", findings: "", normal_range: "")
          end

          patient_opd_record.laboratory_investigations_list.where(created_from_template: true).each do |lab_invest|
            investigation_detail = Investigation::InvestigationDetail.where(_type: "Investigation::Laboratory", opd_record_id: lab_invest.record_id.to_s, investigation_id: lab_invest.investigation_id.to_s).order(created_at: :desc)[0]

            if investigation_detail
              if investigation_detail.ehr_investigation_record_id.present?
                ehr_investigation_record = EhrInvestigation::Record.find_by(id: investigation_detail.ehr_investigation_record_id)

                if ehr_investigation_record
                  lab_invest.update(investigationname: ehr_investigation_record.investigation_name, investigation_comment: ehr_investigation_record.investigation_comment, doctors_remark: ehr_investigation_record.doctors_remark, investigation_val: ehr_investigation_record.investigation_val, normal_range: ehr_investigation_record.normal_range, specimen_type: ehr_investigation_record.specimen_type)

                  if ehr_investigation_record.panel_records.count > 0
                    lab_invest.laboratory_panel_records.destroy
                    ehr_investigation_record.panel_records.each do |panel_record|
                      lab_invest.laboratory_panel_records.create(panel_record.attributes)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def get_r_eom(opdrecord)
    r_extraocularmovements_counter = 0
    r_extraocularmovements_op = ""
    r_extraocularmovements_comments_op = ""
    r_extraocularmovements_comments = ""
    r_extraocularmovements_uniocular = ""
    r_extraocularmovements_binocular = ""
    r_extraocularmovements_prism = ""
    r_extraocularmovements_squint = ""
    r_extraocularmovements_squint_tropia = ""
    r_extraocularmovements_squint_tropia_horizontal = ""
    r_extraocularmovements_squint_tropia_horizontal_esotropia = ""
    r_extraocularmovements_squint_tropia_horizontal_exotropia = ""
    r_extraocularmovements_squint_tropia_vertical = ""
    r_extraocularmovements_squint_tropia_paralytic = ""
    r_extraocularmovements_squint_phoria = ""

    unless opdrecord.r_extraocularmovements.blank?
      unless opdrecord.r_extraocularmovements == "Normal"
        unless opdrecord.r_extraocularmovements_uniocular == "Full"
          r_extraocularmovements_uniocular = "Uniocular- #{opdrecord.read_attribute(:"r_extraocularmovements_uniocular")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_uniocular}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1
        end
        unless opdrecord.r_extraocularmovements_binocular == "Full"
          r_extraocularmovements_binocular = "Binocular- #{opdrecord.read_attribute(:"r_extraocularmovements_binocular")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_binocular}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        if opdrecord.r_extraocularmovements_prism.try(:length).to_i > 0
          r_extraocularmovements_prism = "Prism- #{opdrecord.read_attribute(:"r_extraocularmovements_prism")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_prism}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint.blank?
          r_extraocularmovements_squint = "Squint- #{opdrecord.read_attribute(:"r_extraocularmovements_squint")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_tropia.blank?
          r_extraocularmovements_squint_tropia = "Tropia- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_tropia")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_tropia}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_tropia_horizontal.blank?
          r_extraocularmovements_squint_tropia_horizontal = "Horizontal- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_tropia_horizontal")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_tropia_horizontal}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_tropia_horizontal_esotropia.blank?
          r_extraocularmovements_squint_tropia_horizontal_esotropia = "Esotropia- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_tropia_horizontal_esotropia")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_tropia_horizontal_esotropia}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_tropia_horizontal_exotropia.blank?
          r_extraocularmovements_squint_tropia_horizontal_exotropia = "Exotropia- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_tropia_horizontal_exotropia")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_tropia_horizontal_exotropia}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_tropia_vertical.blank?
          r_extraocularmovements_squint_tropia_vertical = "Vertical- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_tropia_vertical")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_tropia_vertical}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_tropia_paralytic.blank?
          r_extraocularmovements_squint_tropia_paralytic = "Paralytic- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_tropia_paralytic")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_tropia_paralytic}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless opdrecord.r_extraocularmovements_squint_phoria.blank?
          r_extraocularmovements_squint_phoria = "Phoria- #{opdrecord.read_attribute(:"r_extraocularmovements_squint_phoria")},"
          r_extraocularmovements_op = "#{r_extraocularmovements_op} #{r_extraocularmovements_squint_phoria}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        if opdrecord.r_extraocularmovements_comments.try(:length).to_i > 0
          r_extraocularmovements_comments = "#{opdrecord.read_attribute(:"r_extraocularmovements_comments")}"
          r_extraocularmovements_comments_op = "#{r_extraocularmovements_comments}"
          r_extraocularmovements_counter = r_extraocularmovements_counter + 1

        end
        unless r_extraocularmovements_op.blank?
          r_extraocularmovements_op = r_extraocularmovements_op.split("")
          r_extraocularmovements_op_count = r_extraocularmovements_op.count
          if r_extraocularmovements_op_count > 0
            r_extraocularmovements_op = (r_extraocularmovements_op.first r_extraocularmovements_op_count - 1).join()
          end
        end
      end
    end
    if r_extraocularmovements_counter > 0
      r_extraocularmovements_op = "Extra Ocular Movements: #{r_extraocularmovements_op}"
      if r_extraocularmovements_comments_op.present?
        r_extraocularmovements_op += r_extraocularmovements_comments_op
      end
    end
    r_extraocularmovements_op
  end

  def get_l_eom(opdrecord)
    l_extraocularmovements_counter = 0
    l_extraocularmovements_op = ""
    l_extraocularmovements_comments_op = ""
    l_extraocularmovements_comments = ""
    l_extraocularmovements_uniocular = ""
    l_extraocularmovements_binocular = ""
    l_extraocularmovements_prism = ""
    l_extraocularmovements_squint = ""
    l_extraocularmovements_squint_tropia = ""
    l_extraocularmovements_squint_tropia_horizontal = ""
    l_extraocularmovements_squint_tropia_horizontal_esotropia = ""
    l_extraocularmovements_squint_tropia_horizontal_exotropia = ""
    l_extraocularmovements_squint_tropia_vertical = ""
    l_extraocularmovements_squint_tropia_paralytic = ""
    l_extraocularmovements_squint_phoria = ""
    unless opdrecord.l_extraocularmovements.blank?
      unless opdrecord.l_extraocularmovements == "Normal"
        unless opdrecord.l_extraocularmovements_uniocular == "Full"
          l_extraocularmovements_uniocular = "Uniocular- #{opdrecord.read_attribute(:"l_extraocularmovements_uniocular")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_uniocular}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_binocular == "Full"
          l_extraocularmovements_binocular = "Binocular- #{opdrecord.read_attribute(:"l_extraocularmovements_binocular")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_binocular}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        if opdrecord.l_extraocularmovements_prism.try(:length).to_i > 0
          l_extraocularmovements_prism = "Prism- #{opdrecord.read_attribute(:"l_extraocularmovements_prism")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_prism}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint.blank?
          l_extraocularmovements_squint = "Squint- #{opdrecord.read_attribute(:"l_extraocularmovements_squint")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_tropia.blank?
          l_extraocularmovements_squint_tropia = "Tropia- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_tropia")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_tropia}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_tropia_horizontal.blank?
          l_extraocularmovements_squint_tropia_horizontal = "Horizontal- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_tropia_horizontal")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_tropia_horizontal}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_tropia_horizontal_esotropia.blank?
          l_extraocularmovements_squint_tropia_horizontal_esotropia = "Esotropia- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_tropia_horizontal_esotropia")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_tropia_horizontal_esotropia}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_tropia_horizontal_exotropia.blank?
          l_extraocularmovements_squint_tropia_horizontal_exotropia = "Exotropia- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_tropia_horizontal_exotropia")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_tropia_horizontal_exotropia}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_tropia_vertical.blank?
          l_extraocularmovements_squint_tropia_vertical = "Vertical- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_tropia_vertical")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_tropia_vertical}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_tropia_paralytic.blank?
          l_extraocularmovements_squint_tropia_paralytic = "Paralytic- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_tropia_paralytic")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_tropia_paralytic}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless opdrecord.l_extraocularmovements_squint_phoria.blank?
          l_extraocularmovements_squint_phoria = "Phoria- #{opdrecord.read_attribute(:"l_extraocularmovements_squint_phoria")},"
          l_extraocularmovements_op = "#{l_extraocularmovements_op} #{l_extraocularmovements_squint_phoria}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        if opdrecord.l_extraocularmovements_comments.try(:length).to_i > 0
          l_extraocularmovements_comments = "#{opdrecord.read_attribute(:"l_extraocularmovements_comments")}"
          l_extraocularmovements_comments_op = "#{l_extraocularmovements_comments}"
          l_extraocularmovements_counter = l_extraocularmovements_counter + 1

        end
        unless l_extraocularmovements_op.blank?
          l_extraocularmovements_op = l_extraocularmovements_op.split("")
          l_extraocularmovements_op_count = l_extraocularmovements_op.count
          if l_extraocularmovements_op_count > 0
            l_extraocularmovements_op = (l_extraocularmovements_op.first l_extraocularmovements_op_count - 1).join()
          end
        end
      end
    end
    if l_extraocularmovements_counter > 0
      l_extraocularmovements_op = "Extra Ocular Movements: #{l_extraocularmovements_op}"
      if l_extraocularmovements_comments_op.present?
        l_extraocularmovements_op += l_extraocularmovements_comments_op
      end
    end
    l_extraocularmovements_op
  end

  def get_history_attributes(opdrecord, patient)
    if opdrecord.send("view_history_flag") == "1"
      opd_history_counter = 0
      r_opd_history_counter = 0
      l_opd_history_counter = 0
      be_opd_history_counter = 0
      checkuptypecomments_history_counter = 0
      checkuptype_history_counter = 0
      personel_history_counter = 0
      final_history = {}
      visit_op = ""
      blurringdiminution = ""
      redness = ""
      pain = ""
      injury = ""
      discharge = ""
      dryness = ""
      itichingfbsensation = ""
      squint = ""
      strain = ""
      sizeshape = ""
      othersymptoms = ""
      shadow = ""
      discoloration = ""
      # if patient.patient_history.patientpersonalhistory.opthal_history_comment != "" && patient.patient_history.patientpersonalhistory.opthal_history_comment != nil
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.history_comment != "" && patient.patient_history.patientpersonalhistory.history_comment != nil
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.medical_history_comment != "" && patient.patient_history.patientpersonalhistory.medical_history_comment != nil
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.family_history_comment != "" && patient.patient_history.patientpersonalhistory.family_history_comment != nil
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.glaucoma == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.retinal_detachment == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.retinal_dystrophies == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.glasses == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.ocular_disease == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.ocular_surgery == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.eye_surgery == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.eye_disease == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.consanguinity == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.uveitis == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.retinal_laser == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.diabetes == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.hypertension == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.alcoholism == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.smoking_tobacco == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.steroid_intake == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.drug_abuse == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.hiv_aids == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.cancer_tumor == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.cardiac_disorder == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.tuberculosis == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.asthma == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.cns_disorder_stroke == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.thyroid_disorder == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.hepatitis_cirrhosis == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.renal_disorder == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.acidity == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.on_insulin == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end
      # if patient.patient_history.patientpersonalhistory.on_aspirin_blood_thinners == "true"
      #   personel_history_counter = personel_history_counter + 1
      # end

      # chief commplaints
      if opdrecord.chief_complaints.find_by(name: "blurring_diminution_of_vision").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "redness").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "pain").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "injury").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "watering").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "discharge").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "dryness").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "itching").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "FBsensation").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "deviation_squint").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "headache_strain").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "change_in_size_shape").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "other_visual_symptoms").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "shadow_defect_in_vision").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "discoloration_of_eye").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "swelling").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.chief_complaints.find_by(name: "sensation_burning").present?
        opd_history_counter = opd_history_counter + 1
      end

      if opdrecord.r_chiefcomplaint.present?
        opd_history_counter = opd_history_counter + 1
        r_opd_history_counter = r_opd_history_counter + 1
      end
      if opdrecord.r_subjectivecomments.present?
        opd_history_counter = opd_history_counter + 1
        r_opd_history_counter = r_opd_history_counter + 1
      end
      if opdrecord.l_chiefcomplaint.present?
        opd_history_counter = opd_history_counter + 1
        l_opd_history_counter = l_opd_history_counter + 1
      end
      if opdrecord.l_subjectivecomments.present?
        opd_history_counter = opd_history_counter + 1
        l_opd_history_counter = l_opd_history_counter + 1
      end
      unless opdrecord.chiefcomplaint_comments.blank?
        opd_history_counter = opd_history_counter + 1
        be_opd_history_counter = be_opd_history_counter + 1
      end
      unless opdrecord.checkuptype.blank?
        opd_history_counter = opd_history_counter + 1
        checkuptype_history_counter = checkuptype_history_counter + 1
      end
      unless opdrecord.checkuptypecomments.blank?
        opd_history_counter = opd_history_counter + 1
        checkuptypecomments_history_counter = checkuptypecomments_history_counter + 1
      end
      #  if params[:action] == 'edit_opd_record' || params[:action] == 'new_opd_record'
      #  unless opd_history_counter <= 0 &&  personel_history_counter <= 0 && (@patient.patient_history.patientpersonalhistory.problems == nil || @patient.patient_history.patientpersonalhistory.problems == [] ) && @patient.patient_history.patientallergyhistory.antimicrobialagents == [] && @patient.patient_history.patientallergyhistory.antifungalagents ==[] && @patient.patient_history.patientallergyhistory.antiviralagents ==[] &&  @patient.patient_history.patientallergyhistory.nsaids ==[] && @patient.patient_history.patientallergyhistory.eyedrops ==[] &&  @patient.patient_history.patientallergyhistory.contact ==[] &&  @patient.patient_history.patientallergyhistory.food ==[] &&  @patient.patient_history.patientallergyhistory.others==""
      #  else
      #     "No Patient History"
      #   end
      #  else
      #    unless opd_history_counter <= 0 &&  personel_history_counter <= 0 && (@patient.patient_history.patientpersonalhistory.problems == nil || @patient.patient_history.patientpersonalhistory.problems == [] ) && @patient.patient_history.patientallergyhistory.antimicrobialagents == [] && @patient.patient_history.patientallergyhistory.antifungalagents ==[] && @patient.patient_history.patientallergyhistory.antiviralagents ==[] &&  @patient.patient_history.patientallergyhistory.nsaids ==[] && @patient.patient_history.patientallergyhistory.eyedrops ==[] &&  @patient.patient_history.patientallergyhistory.contact ==[] &&  @patient.patient_history.patientallergyhistory.food ==[] &&  @patient.patient_history.patientallergyhistory.others==""
      #
      #    end
      # end
      if opd_history_counter > 0
        if checkuptypecomments_history_counter > 0 || checkuptype_history_counter > 0
          visit_op = "Visit:"
        end
        if opdrecord.checkuptype.blank?
          unless opdrecord.checkuptypecomments == nil || opdrecord.checkuptypecomments == ""
            visit_op = "#{visit_op}#{opdrecord.checkuptypecomments}"
          end
        else
          visit_op = "#{visit_op}#{opdrecord.checkuptype}"
          unless opdrecord.checkuptypecomments == nil || opdrecord.checkuptypecomments == ""
            visit_op = "#{visit_op},#{opdrecord.checkuptypecomments}"
          end
        end
      end
      final_history["visit"] = visit_op

      if opd_history_counter > 0
        if opdrecord.chief_complaints.present?
          @history_records = opdrecord.chief_complaints
          if @history_records.find_by(name: "blurring_diminution_of_vision").present?
            @blurring = @history_records.find_by(name: "blurring_diminution_of_vision")
            blurringdiminution = "Blurring/Diminution of vision"
            if @blurring.side.present?
              if @blurring.side == "L"
                blurringdiminution = "#{blurringdiminution} Left Eye"
              elsif @blurring.side == "R"
                blurringdiminution = "#{blurringdiminution} Right Eye"
              else
                blurringdiminution = "#{blurringdiminution} Both Eye"
              end
            end
            if @blurring.duration.present? && @blurring.duration_unit.present?
              blurringdiminution = "#{blurringdiminution} since #{@blurring.duration} #{@blurring.duration_unit} "
            end
            if @blurring.comment.present?
              blurringdiminution = "#{blurringdiminution} - #{@blurring.comment}"
            end
            if @blurring.complaint_options.present?
              blurringdiminution = "#{blurringdiminution} - #{@blurring.complaint_options}"
            end
            final_history["blurringdiminution"] = blurringdiminution
          end

          if @history_records.find_by(name: "redness").present?
            @redness = @history_records.find_by(name: "redness")
            redness = "Redness"
            if @redness.side.present?
              if @redness.side == "L"
                redness = "#{redness} Left Eye"
              elsif @redness.side == "R"
                redness = "#{redness} Right Eye"
              else
                redness = "#{redness} Both Eye"
              end
            end
            if @redness.duration.present? && @redness.duration_unit.present?
              redness = "#{redness} Since #{@redness.duration} #{@redness.duration_unit}"
            end
            if @redness.comment.present?
              redness = "#{redness} - #{@redness.comment}"
            end
            final_history["redness"] = redness
          end

          if @history_records.find_by(name: "pain").present?
            @pain = @history_records.find_by(name: "pain")
            pain = "Pain"
            if @pain.side.present?
              if @pain.side == "L"
                pain = "#{pain} Left Eye"
              elsif @pain.side == "R"
                pain = "#{pain} Right Eye"
              else
                pain = "#{pain} Both Eye"
              end
            end
            if @pain.duration.present? && @pain.duration_unit.present?
              pain = "#{pain} Since #{@pain.duration} #{@pain.duration_unit}"
            end
            if @pain.comment.present?
              pain = "#{pain} - #{@pain.comment}"
            end
            final_history["pain"] = pain
          end

          if @history_records.find_by(name: "injury").present?
            @injury = @history_records.find_by(name: "injury")
            injury = "Injury"
            if @injury.side.present?
              if @injury.side == "L"
                injury = "#{injury} Left Eye"
              elsif @injury.side == "R"
                injury = "#{injury} Right Eye"
              else
                injury = "#{injury} Both Eye"
              end
            end
            if @injury.duration.present? && @injury.duration_unit.present?
              injury = "#{injury} Since #{@injury.duration} #{@injury.duration_unit}"
            end
            if @injury.comment.present?
              injury = "#{injury} - #{@injury.comment}"
            end
            final_history["injury"] = injury
          end

          if @history_records.find_by(name: "watering").present?
            @watering = @history_records.find_by(name: "watering")
            watering = "Watering"
            if @watering.side.present?
              if @watering.side == "L"
                watering = "#{watering} Left Eye"
              elsif @watering.side == "R"
                watering = "#{watering} Right Eye"
              else
                watering = "#{watering} Both Eye"
              end
            end
            if @watering.duration.present? && @watering.duration_unit.present?
              watering = "#{watering} Since #{@watering.duration} #{@watering.duration_unit}"
            end
            if @watering.comment.present?
              watering = "#{watering} - #{@watering.comment}"
            end
            final_history["watering"] = watering
          end

          if @history_records.find_by(name: "discharge").present?
            @discharge = @history_records.find_by(name: "discharge")
            discharge = "Discharge"
            if @discharge.side.present?
              if @discharge.side == "L"
                discharge = "#{discharge} Left Eye"
              elsif @discharge.side == "R"
                discharge = "#{discharge} right Eye"
              else
                discharge = "#{discharge} Both Eye"
              end
            end
            if @discharge.duration.present? && @discharge.duration_unit.present?
              discharge = "#{discharge} Since #{@discharge.duration} #{@discharge.duration_unit}"
            end
            if @discharge.comment.present?
              discharge = "#{discharge} - #{@discharge.comment}"
            end
            final_history["watering"] = discharge
          end

          if @history_records.find_by(name: "dryness").present?
            @dryness = @history_records.find_by(name: "dryness")
            dryness = "Dryness"
            if @dryness.side.present?
              if @dryness.side == "L"
                dryness = "#{dryness} Left Eye"
              elsif @dryness.side == "R"
                dryness = "#{dryness} Right Eye"
              else
                dryness = "#{dryness} Both Eye"
              end
            end
            if @dryness.duration.present? && @dryness.duration_unit.present?
              dryness = "#{dryness} Since #{@dryness.duration} #{@dryness.duration_unit}"
            end
            if @dryness.comment.present?
              dryness = "#{dryness} - #{@dryness.comment}"
            end
            final_history["dryness"] = dryness
          end

          if @history_records.find_by(name: "itching").present?
            @itching = @history_records.find_by(name: "itching")
            itching = "Itching"
            if @itching.side.present?
              if @itching.side == "L"
                itching = "#{itching} Left Eye"
              elsif @itching.side == "R"
                itching = "#{itching} Left Eye"
              else @itching.side == "B/E"
                   itching = "#{itching} Left Eye"
              end
            end
            if @itching.duration.present? && @itching.duration_unit.present?
              itching = "#{itching} Since #{@itching.duration} #{@itching.duration_unit}"
            end
            if @itching.comment.present?
              itching = "#{itching} - #{@itching.comment}"
            end
            final_history["itching"] = itching
          end

          if @history_records.find_by(name: "FBsensation").present?
            @fsensation = @history_records.find_by(name: "FBsensation")
            fbsensation = "FBsensation"
            if @fsensation.side.present?
              if @fsensation.side == "L"
                fbsensation = "#{fbsensation} Left Eye"
              elsif @fsensation.side == "R"
                fbsensation = "#{fbsensation} Left Eye"
              else @fsensation.side == "B/E"
                   fbsensation = "#{fbsensation} Left Eye"
              end
            end
            if @fsensation.duration.present? && @fsensation.duration_unit.present?
              fbsensation = "#{fbsensation} Since #{@fsensation.duration} #{@fsensation.duration_unit}"
            end
            if @fsensation.comment.present?
              fbsensation = "#{fbsensation} - #{@fsensation.comment}"
            end
            final_history["fbsensation"] = fbsensation
          end

          if @history_records.find_by(name: "deviation_squint").present?
            @deviation_squint = @history_records.find_by(name: "deviation_squint")
            deviation_squint = "Deviation/Squint"
            if @deviation_squint.side.present?
              if @deviation_squint.side == "L"
                deviation_squint = "#{deviation_squint} Left Eye"
              elsif @deviation_squint.side == "R"
                deviation_squint = "#{deviation_squint} Left Eye"
              else @deviation_squint.side == "B/E"
                   deviation_squint = "#{deviation_squint} Left Eye"
              end
            end
            if @deviation_squint.duration.present? && @deviation_squint.duration_unit.present?
              deviation_squint = "#{deviation_squint} Since #{@deviation_squint.duration} #{@deviation_squint.duration_unit}"
            end
            if @deviation_squint.comment.present?
              deviation_squint = "#{deviation_squint} - #{@deviation_squint.comment}"
            end
            if @deviation_squint.complaint_options.present?
              deviation_squint = "#{deviation_squint}   #{@deviation_squint.complaint_options}"
            end
            final_history["deviation_squint"] = deviation_squint
          end

          if @history_records.find_by(name: "headache_strain").present?
            @headache_strain = @history_records.find_by(name: "headache_strain")
            headache_strain = "Headache/Strain"
            if @headache_strain.side.present?
              if @headache_strain.side == "L"
                headache_strain = "#{headache_strain} Left Eye"
              elsif @headache_strain.side == "R"
                headache_strain = "#{headache_strain} Left Eye"
              else @headache_strain.side == "B/E"
                   headache_strain = "#{headache_strain} Left Eye"
              end
            end
            if @headache_strain.duration.present? && @headache_strain.duration_unit.present?
              headache_strain = "#{headache_strain} Since #{@headache_strain.duration} #{@headache_strain.duration_unit}"
            end
            if @headache_strain.comment.present?
              headache_strain = "#{headache_strain} - #{@headache_strain.comment}"
            end
            final_history["deviation_squint"] = deviation_squint
          end

          if @history_records.find_by(name: "change_in_size_shape").present?
            @change_in_size_shape = @history_records.find_by(name: "change_in_size_shape")
            change_in_size_shape = "Change in size shape"
            if @change_in_size_shape.side.present?
              if @change_in_size_shape.side == "L"
                change_in_size_shape = "#{change_in_size_shape} Left Eye"
              elsif @change_in_size_shape.side == "R"
                change_in_size_shape = "#{change_in_size_shape} Left Eye"
              else @change_in_size_shape.side == "B/E"
                   change_in_size_shape = "#{change_in_size_shape} Left Eye"
              end
            end
            if @change_in_size_shape.duration.present? && @change_in_size_shape.duration_unit.present?
              change_in_size_shape = "#{change_in_size_shape} Since #{@change_in_size_shape.duration} #{@change_in_size_shape.duration_unit}"
            end
            if @change_in_size_shape.comment.present?
              change_in_size_shape = "#{change_in_size_shape} - #{@change_in_size_shape.comment}"
            end
            final_history["change_in_size_shape"] = change_in_size_shape
          end

          if @history_records.find_by(name: "other_visual_symptoms").present?
            @other_visual_symptoms = @history_records.find_by(name: "other_visual_symptoms")
            other_visual_symptoms = "Other visual symptoms"
            if @other_visual_symptoms.side.present?
              if @other_visual_symptoms.side == "L"
                other_visual_symptoms = "#{other_visual_symptoms} Left Eye"
              elsif @other_visual_symptoms.side == "R"
                other_visual_symptoms = "#{other_visual_symptoms} Left Eye"
              else @other_visual_symptoms.side == "B/E"
                   other_visual_symptoms = "#{other_visual_symptoms} Left Eye"
              end
            end
            if @other_visual_symptoms.duration.present? && @other_visual_symptoms.duration_unit.present?
              other_visual_symptoms = "#{other_visual_symptoms} Since #{@other_visual_symptoms.duration} #{@other_visual_symptoms.duration_unit}"
            end
            if @other_visual_symptoms.comment.present?
              other_visual_symptoms = "#{other_visual_symptoms} - #{@other_visual_symptoms.comment}"
            end
            if @other_visual_symptoms.complaint_options.present?
              other_visual_symptoms = "#{other_visual_symptoms}   #{@other_visual_symptoms.complaint_options}"
            end
            final_history["other_visual_symptoms"] = other_visual_symptoms
          end

          if @history_records.find_by(name: "shadow_defect_in_vision").present?
            @shadow_defect_in_vision = @history_records.find_by(name: "shadow_defect_in_vision")
            shadow_defect_in_vision = "Shadow defect in vision"
            if @shadow_defect_in_vision.side.present?
              if @shadow_defect_in_vision.side == "L"
                shadow_defect_in_vision = "#{shadow_defect_in_vision} Left Eye"
              elsif @shadow_defect_in_vision.side == "R"
                shadow_defect_in_vision = "#{shadow_defect_in_vision} Left Eye"
              else @shadow_defect_in_vision.side == "B/E"
                   shadow_defect_in_vision = "#{shadow_defect_in_vision} Left Eye"
              end
            end
            if @shadow_defect_in_vision.duration.present? && @shadow_defect_in_vision.duration_unit.present?
              shadow_defect_in_vision = "#{shadow_defect_in_vision} Since #{@shadow_defect_in_vision.duration} #{@shadow_defect_in_vision.duration_unit}"
            end
            if @shadow_defect_in_vision.comment.present?
              shadow_defect_in_vision = "#{shadow_defect_in_vision} - #{@shadow_defect_in_vision.comment}"
            end
            final_history["shadow_defect_in_vision"] = shadow_defect_in_vision
          end

          if @history_records.find_by(name: "discoloration_of_eye").present?
            @discoloration_of_eye = @history_records.find_by(name: "discoloration_of_eye")
            discoloration_of_eye = "Discoloration Of Eye"
            if @discoloration_of_eye.side.present?
              if @discoloration_of_eye.side == "L"
                discoloration_of_eye = "#{discoloration_of_eye} Left Eye"
              elsif @discoloration_of_eye.side == "R"
                discoloration_of_eye = "#{discoloration_of_eye} Left Eye"
              else @discoloration_of_eye.side == "B/E"
                   discoloration_of_eye = "#{discoloration_of_eye} Left Eye"
              end
            end
            if @discoloration_of_eye.duration.present? && @discoloration_of_eye.duration_unit.present?
              discoloration_of_eye = "#{discoloration_of_eye} Since #{@discoloration_of_eye.duration} #{@discoloration_of_eye.duration_unit}"
            end
            if @discoloration_of_eye.comment.present?
              discoloration_of_eye = "#{discoloration_of_eye} - #{@discoloration_of_eye.comment}"
            end
            final_history["discoloration_of_eye"] = discoloration_of_eye
          end

          if @history_records.find_by(name: "swelling").present?
            @swelling = @history_records.find_by(name: "swelling")
            swelling = "Swelling"
            if @swelling.side.present?
              if @swelling.side == "L"
                swelling = "#{swelling} Left Eye"
              elsif @swelling.side == "R"
                swelling = "#{swelling} Left Eye"
              else @swelling.side == "B/E"
                   swelling = "#{swelling} Left Eye"
              end
            end
            if @swelling.duration.present? && @swelling.duration_unit.present?
              swelling = "#{swelling} Since #{@swelling.duration} #{@swelling.duration_unit}"
            end
            if @swelling.comment.present?
              swelling = "#{swelling} - #{@swelling.comment}"
            end
            final_history["swelling"] = swelling
          end

          if @history_records.find_by(name: "sensation_burning").present?
            @sensation_burning = @history_records.find_by(name: "sensation_burning")
            sensation_burning = "Sensation/Burning"
            if @sensation_burning.side.present?
              if @sensation_burning.side == "L"
                sensation_burning = "#{sensation_burning} Left Eye"
              elsif @sensation_burning.side == "R"
                sensation_burning = "#{sensation_burning} Left Eye"
              else @sensation_burning.side == "B/E"
                   sensation_burning = "#{sensation_burning} Left Eye"
              end
            end
            if @sensation_burning.duration.present? && @sensation_burning.duration_unit.present?
              sensation_burning = "#{sensation_burning} Since #{@sensation_burning.duration} #{@sensation_burning.duration_unit}"
            end
            if @sensation_burning.comment.present?
              sensation_burning = "#{sensation_burning} - #{@sensation_burning.comment}"
            end
            final_history["sensation_burning"] = sensation_burning
          end

        end
      end

      if be_opd_history_counter > 0
        unless opdrecord.chiefcomplaint_comments == nil || opdrecord.chiefcomplaint_comments == ""
          final_history["commnets"] = opdrecord.chiefcomplaint_comments
        end
      end
    end
    # puts final_history
    final_history
  end

  def create_new_record(record, opdrecord, appointment, doctor, history, freeform)
    r_visualacuity = get_r_visualacuity(opdrecord)
    l_visualacuity = get_l_visualacuity(opdrecord)
    r_iop = get_r_iop(opdrecord)
    l_iop = get_l_iop(opdrecord)
    r_appendage = get_r_appendage(opdrecord)
    l_appendage = get_l_appendage(opdrecord)
    r_anterior_segment = get_r_anterior_segment(opdrecord)
    l_anterior_segment = get_l_anterior_segment(opdrecord)
    r_posterior_segment = get_r_posterior_segment(opdrecord)
    l_posterior_segment = get_l_posterior_segment(opdrecord)
    r_eom = get_r_eom(opdrecord)
    l_eom = get_l_eom(opdrecord)
    record.id = opdrecord.id
    record.creationtime = opdrecord.created_at
    record.encounterdate = appointment.appointmentdate
    record.templatetype = opdrecord.templatetype
    record.facility_id = appointment.facility_id
    record.doctor_name = doctor.try(:fullname)
    record['specalityid'] = opdrecord.specalityid
    record['specalityname'] = opdrecord.specalityname
    record['appointment_id'] = appointment.id
    examination = Hash["r_refraction" => r_visualacuity, "l_refraction" => l_visualacuity, "r_iop" => r_iop, "l_iop" => l_iop, "r_appendage" => r_appendage, "l_appendage" => l_appendage, "r_anterior_segment" => r_anterior_segment, "l_anterior_segment" => l_anterior_segment, "r_posterior_segment" => r_posterior_segment, "l_posterior_segment" => l_posterior_segment, "r_eom" => r_eom, "l_eom" => l_eom]
    record.examination = examination
    record.history = history
    record.freeform = freeform
    record.save
  end

  def get_r_posterior_segment(opdrecord)
    r_fundus_counter = 0
    r_fundus_op = ""
    r_fundus_comments_op = ""
    r_fundus_comments = ""

    r_fundus_media_select = ""
    r_fundus_media_comment = ""
    r_fundus_pvd_select = ""
    r_fundus_optdiscsize_select = ""
    r_fundus_cupratio_comment = ""
    r_fundus_opticdisc_comment = ""
    r_fundus_bloodvessel_comment = ""
    r_fundus_macula_comment = ""
    r_fundustext_comment = ""
    unless opdrecord.r_fundus.blank?
      unless opdrecord.r_fundus == "Normal"
        unless opdrecord.r_fundus_media_select == ""
          if opdrecord.r_fundus_media_comment.present?
            r_fundus_media_select = "Media-#{opdrecord.read_attribute(:"r_fundus_media_select")}(#{opdrecord.read_attribute(:"r_fundus_media_comment")}),"
          else
            r_fundus_media_select = "Media-#{opdrecord.read_attribute(:"r_fundus_media_select")},"
          end

          r_fundus_op = "#{r_fundus_op} #{r_fundus_media_select}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundus_pvd_select == ""
          r_fundus_pvd_select = "PVD-#{opdrecord.read_attribute(:"r_fundus_pvd_select")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundus_pvd_select}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundus_optdiscsize_select == ""
          r_fundus_optdiscsize_select = "OptDiscSize-#{opdrecord.read_attribute(:"r_fundus_optdiscsize_select")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundus_optdiscsize_select}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundus_cupratio_comment == ""
          r_fundus_cupratio_comment = "CupRatio-#{opdrecord.read_attribute(:"r_fundus_cupratio_comment")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundus_cupratio_comment}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundus_opticdisc_comment == ""
          r_fundus_opticdisc_comment = "OpticDisc-#{opdrecord.read_attribute(:"r_fundus_opticdisc_comment")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundus_opticdisc_comment}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundus_bloodvessel_comment == ""
          r_fundus_bloodvessel_comment = "Bloodvessel-#{opdrecord.read_attribute(:"r_fundus_bloodvessel_comment")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundus_bloodvessel_comment}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundus_macula_comment == ""
          r_fundus_macula_comment = "Macula-#{opdrecord.read_attribute(:"r_fundus_macula_comment")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundus_macula_comment}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless opdrecord.r_fundustext_comment == ""
          r_fundustext_comment = "Fundus-#{opdrecord.read_attribute(:"r_fundustext_comment")},"
          r_fundus_op = "#{r_fundus_op} #{r_fundustext_comment}"
          r_fundus_counter = r_fundus_counter + 1

        end

        if opdrecord.r_fundus_diagram_present == "Y"
          r_fundus_counter = r_fundus_counter + 1

        end

        if opdrecord.r_fundus_comments.try(:length).to_i > 0
          r_fundus_comments = "#{opdrecord.read_attribute(:"r_fundus_comments")}"
          r_fundus_comments_op = "#{r_fundus_comments}"
          r_fundus_counter = r_fundus_counter + 1

        end
        unless r_fundus_op.blank?
          r_fundus_op = r_fundus_op.split("")
          r_fundus_op_count = r_fundus_op.count
          if r_fundus_op_count > 0
            r_fundus_op = (r_fundus_op.first r_fundus_op_count - 1).join()
          end
        end
      end
    end
    if r_fundus_comments_op.present?
      r_fundus_op += r_fundus_comments_op
    end
    r_fundus_op
  end

  def get_l_posterior_segment(opdrecord)
    l_fundus_counter = 0
    l_fundus_op = ""
    l_fundus_comments_op = ""
    l_fundus_comments = ""

    l_fundus_media_select = ""
    l_fundus_media_comment = ""
    l_fundus_pvd_select = ""
    l_fundus_optdiscsize_select = ""
    l_fundus_cupratio_comment = ""
    l_fundus_opticdisc_comment = ""
    l_fundus_bloodvessel_comment = ""
    l_fundus_macula_comment = ""
    l_fundustext_comment = ""
    unless opdrecord.l_fundus.blank?
      unless opdrecord.l_fundus == "Normal"
        unless opdrecord.l_fundus_media_select == ""
          if opdrecord.l_fundus_media_comment.present?
            l_fundus_media_select = "Media-#{opdrecord.read_attribute(:"l_fundus_media_select")}(#{opdrecord.read_attribute(:"l_fundus_media_comment")}),"
          else
            l_fundus_media_select = "Media-#{opdrecord.read_attribute(:"l_fundus_media_select")},"
          end
          l_fundus_op = "#{l_fundus_op} #{l_fundus_media_select}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundus_pvd_select == ""
          l_fundus_pvd_select = "PVD-#{opdrecord.read_attribute(:"l_fundus_pvd_select")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundus_pvd_select}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundus_optdiscsize_select == ""
          l_fundus_optdiscsize_select = "OptDiscSize-#{opdrecord.read_attribute(:"l_fundus_optdiscsize_select")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundus_optdiscsize_select}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundus_cupratio_comment == ""
          l_fundus_cupratio_comment = "CupRatio-#{opdrecord.read_attribute(:"l_fundus_cupratio_comment")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundus_cupratio_comment}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundus_opticdisc_comment == ""
          l_fundus_opticdisc_comment = "OpticDisc-#{opdrecord.read_attribute(:"l_fundus_opticdisc_comment")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundus_opticdisc_comment}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundus_bloodvessel_comment == ""
          l_fundus_bloodvessel_comment = "Bloodvessel-#{opdrecord.read_attribute(:"l_fundus_bloodvessel_comment")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundus_bloodvessel_comment}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundus_macula_comment == ""
          l_fundus_macula_comment = "Macula-#{opdrecord.read_attribute(:"l_fundus_macula_comment")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundus_macula_comment}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless opdrecord.l_fundustext_comment == ""
          l_fundustext_comment = "Fundus-#{opdrecord.read_attribute(:"l_fundustext_comment")},"
          l_fundus_op = "#{l_fundus_op} #{l_fundustext_comment}"
          l_fundus_counter = l_fundus_counter + 1

        end
        if opdrecord.l_fundus_diagram_present == "Y"
          l_fundus_counter = l_fundus_counter + 1

        end
        if opdrecord.l_fundus_comments.try(:length).to_i > 0
          l_fundus_comments = "#{opdrecord.read_attribute(:"l_fundus_comments")}"
          l_fundus_comments_op = "#{l_fundus_comments}"
          l_fundus_counter = l_fundus_counter + 1

        end
        unless l_fundus_op.blank?
          l_fundus_op = l_fundus_op.split("")
          l_fundus_op_count = l_fundus_op.count
          if l_fundus_op_count > 0
            l_fundus_op = (l_fundus_op.first l_fundus_op_count - 1).join()
          end
        end
      end
    end

    if l_fundus_comments_op.present?
      l_fundus_op += l_fundus_comments_op
    end
    l_fundus_op
  end

  def get_r_anterior_segment(opdrecord)
    r_anterior_segment_op = Hash.new
    r_conjunctiva_counter = 0
    r_conjunctiva_op = ""
    final_conjunctiva_op = ""
    r_conjunctiva_congestion = ""
    r_conjunctiva_conjunctivitis = ""
    r_conjunctiva_episcleritis = ""
    r_conjunctiva_tear = ""
    r_conjunctiva_subconjunctival_haemorrhage = ""
    r_conjunctiva_foreign_body = ""
    r_conjunctiva_follicles = ""
    r_conjunctiva_papillae = ""
    r_conjunctiva_pinguecula = ""
    r_conjunctiva_pterygium = ""
    r_conjunctiva_phlycten = ""
    r_conjunctiva_discharge = ""
    r_conjunctiva_conjuctival_blib = ""
    r_conjunctiva_comments = ""
    r_conjunctiva_comments_op = ""
    unless opdrecord.r_conjunctiva.blank?
      unless opdrecord.r_conjunctiva == "Normal"
        r_conjunctiva_op += "Conjunctiva:"
        unless opdrecord.r_conjunctiva_congestion == "No"
          if opdrecord.r_conjunctiva_congestion_lgc != ""
            r_conjunctiva_congestion_lgc = "-" + opdrecord.r_conjunctiva_congestion_lgc
          else
            r_conjunctiva_congestion_lgc = ""
          end
          r_conjunctiva_congestion = "Congestion#{r_conjunctiva_congestion_lgc},"
          r_conjunctiva_op = "#{r_conjunctiva_op}#{r_conjunctiva_congestion}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if false
          unless opdrecord.r_conjunctiva_conjunctivitis == "No"
            r_conjunctiva_conjunctivitis = "Conjunctivitis,"
            r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_conjunctivitis}"
            r_conjunctiva_counter = r_conjunctiva_counter + 1

          end
          unless opdrecord.r_conjunctiva_episcleritis == "No"
            r_conjunctiva_episcleritis = "Episcleritis,"
            r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_episcleritis}"
            r_conjunctiva_counter = r_conjunctiva_counter + 1
          end
        end
        unless opdrecord.r_conjunctiva_tear == "No"
          r_conjunctiva_tear = "Tear,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_tear}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        unless opdrecord.r_conjunctiva_conjuctival_blib == "No"
          r_conjunctiva_conjuctival_blib = "Conjuctival Bleb,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_conjuctival_blib}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1

        end
        unless opdrecord.r_conjunctiva_subconjunctival_haemorrhage == "No"
          r_conjunctiva_subconjunctival_haemorrhage = "SubConjunctival Haemorrhage,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_subconjunctival_haemorrhage}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_foreign_body == "Yes"
          r_conjunctiva_foreign_body = "Foreign Body,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_foreign_body}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_follicles == "Yes"
          r_conjunctiva_follicles = "Follicles,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_follicles}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_papillae == "Yes"
          r_conjunctiva_papillae = "Papillae,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_papillae}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_pinguecula == "Yes"
          r_conjunctiva_pinguecula = "Pinguecula,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_pinguecula}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_pterygium == "Yes"
          r_conjunctiva_pterygium = "Pterygium,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_pterygium}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_phlycten == "Yes"
          r_conjunctiva_phlycten = "Phlycten,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_phlycten}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_discharge == "Yes"
          r_conjunctiva_discharge = "Discharge,"
          r_conjunctiva_op = "#{r_conjunctiva_op} #{r_conjunctiva_discharge}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        if opdrecord.r_conjunctiva_comments.present?
          r_conjunctiva_comments = "#{opdrecord.read_attribute(:"r_conjunctiva_comments")}"
          r_conjunctiva_comments_op = " #{r_conjunctiva_comments}"
          r_conjunctiva_counter = r_conjunctiva_counter + 1
        end
        unless r_conjunctiva_op.blank?
          r_conjunctiva_op = r_conjunctiva_op.split("")
          r_conjunctiva_op_count = r_conjunctiva_op.count
          if r_conjunctiva_op_count > 0
            r_conjunctiva_op = (r_conjunctiva_op.first r_conjunctiva_op_count - 1).join()
          end
        end
      end
    end
    if r_conjunctiva_counter > 0
      if r_conjunctiva_comments_op.present?
        r_conjunctiva_op += r_conjunctiva_comments_op
      end
    elsif opdrecord.r_local_examination_normal == "normal"
      r_conjunctiva_op = "Conjunctiva: Normal"
    end
    # push to anterior segment array
    r_anterior_segment_op["conjunctiva"] = r_conjunctiva_op

    r_cornea_counter = 0
    r_corneaslit_counter = 0
    r_cornea_op = ""
    r_cornea_size = ""
    r_cornea_shape = ""
    r_cornea_surface = ""
    r_cornea_schirmer_test = ""
    r_cornea_comments_op = ""
    r_cornea_comments = ""
    unless opdrecord.r_cornea.blank?
      unless opdrecord.r_cornea == "Normal" && opdrecord.r_cornea_normal != "normal"
        r_cornea_op = "Cornea: "
        unless opdrecord.r_cornea_size == "Normal" && opdrecord.r_cornea_normal != "normal"
          r_cornea_size = "Size- #{opdrecord.read_attribute(:"r_cornea_size")},"
          r_cornea_op = "#{r_cornea_op}#{r_cornea_size}"
          r_cornea_counter = r_cornea_counter + 1

        end
        unless opdrecord.r_cornea_shape == "Normal" && opdrecord.r_cornea_normal != "normal"
          r_cornea_shape = "Shape- #{opdrecord.read_attribute(:"r_cornea_shape")},"
          r_cornea_op = "#{r_cornea_op} #{r_cornea_shape}"
          r_cornea_counter = r_cornea_counter + 1

        end
        unless opdrecord.r_cornea_surface == "Normal" && opdrecord.r_cornea_normal != "normal"
          r_cornea_surface = "Surface- #{opdrecord.read_attribute(:"r_cornea_surface")},"
          r_cornea_op = "#{r_cornea_op} #{r_cornea_surface}"
          r_cornea_counter = r_cornea_counter + 1

        end
        unless opdrecord.r_cornea_schirmer_test == ""
          r_cornea_schirmer_test = "Schirmer Test-#{opdrecord.read_attribute(:"r_cornea_schirmer_test")}(#{opdrecord.read_attribute(:"r_cornea_schirmer_dimension")}mm in #{opdrecord.read_attribute(:"r_cornea_schirmer_time")} min),"
          r_cornea_op = "#{r_cornea_op} #{r_cornea_schirmer_test}"
          r_cornea_counter = r_cornea_counter + 1

        end
        if opdrecord.r_cornea_diagram_present == "Y"
          r_cornea_counter = r_cornea_counter + 1

        end
        if opdrecord.r_corneaslit_diagram_present == "Y"
          r_corneaslit_counter = r_corneaslit_counter + 1

        end
        if opdrecord.r_cornea_comments.try(:length).to_i > 0
          r_cornea_comments = "#{opdrecord.read_attribute(:"r_cornea_comments")}"
          r_cornea_comments_op = " #{r_cornea_comments}"
          r_cornea_counter = r_cornea_counter + 1

        end
        unless r_cornea_op.blank?
          r_cornea_op = r_cornea_op.split("")
          r_cornea_op_count = r_cornea_op.count
          if r_cornea_op_count > 0
            r_cornea_op = (r_cornea_op.first r_cornea_op_count - 1).join()
          end
        end
      end
    end
    if r_cornea_counter == 0 and r_cornea_comments_op.present?
      r_cornea_op += r_cornea_comments_op
    end
    if opdrecord.r_local_examination_normal == "normal"
      r_cornea_op = "Cornea: Size/Shape/Surface Normal"
    end
    # push to anterior segment array
    r_anterior_segment_op["cornea"] = r_cornea_op

    # code to get anterior chamber
    r_anteriorchamber_counter = 0
    r_anteriorchamber_op = ""
    r_anteriorchamber_comments_op = ""
    r_anteriorchamber_comments = ""
    r_anteriorchamber_depth = ""
    r_anteriorchamber_reaction = ""
    r_anteriorchamber_cells = ""
    r_anteriorchamber_flare = ""
    r_anteriorchamber_hyphema = ""
    r_anteriorchamber_hypopyon = ""
    r_anteriorchamber_foreignbody = ""

    r_anteriorchamber_depth_comment = ""
    r_anteriorchamber_reaction_comment = ""
    r_anteriorchamber_cells_comment = ""
    r_anteriorchamber_flare_comment = ""
    r_anteriorchamber_hyphema_comment = ""
    r_anteriorchamber_hypopyon_comment = ""
    r_anteriorchamber_foreignbody_comment = ""
    unless opdrecord.r_anteriorchamber.blank?
      unless opdrecord.r_anteriorchamber == "Normal"
        unless opdrecord.r_anteriorchamber_depth == "Normal"
          r_anteriorchamber_op = "Anterior Chamber:"
          r_anteriorchamber_depth = "Depth- #{opdrecord.read_attribute(:"r_anteriorchamber_depth")} #{opdrecord.read_attribute(:"r_anteriorchamber_depth_comment")},"
          r_anteriorchamber_op = "#{r_anteriorchamber_op}#{r_anteriorchamber_depth}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        unless opdrecord.r_anteriorchamber_cells == "No"
          r_anteriorchamber_cells = "Cells #{opdrecord.read_attribute(:"r_anteriorchamber_cells_comment")},"
          r_anteriorchamber_op = "#{r_anteriorchamber_op} #{r_anteriorchamber_cells}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        unless opdrecord.r_anteriorchamber_flare == "No"
          r_anteriorchamber_flare = "Flare #{opdrecord.read_attribute(:"r_anteriorchamber_flare_comment")},"
          r_anteriorchamber_op = "#{r_anteriorchamber_op} #{r_anteriorchamber_flare}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        unless opdrecord.r_anteriorchamber_hyphema == "No"
          r_anteriorchamber_hyphema = "Hyphema #{opdrecord.read_attribute(:"r_anteriorchamber_hyphema_comment")},"
          r_anteriorchamber_op = "#{r_anteriorchamber_op} #{r_anteriorchamber_hyphema}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        unless opdrecord.r_anteriorchamber_hypopyon == "No"
          r_anteriorchamber_hypopyon = "Hypopyon #{opdrecord.read_attribute(:"r_anteriorchamber_hypopyon_comment")},"
          r_anteriorchamber_op = "#{r_anteriorchamber_op} #{r_anteriorchamber_hypopyon}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        unless opdrecord.r_anteriorchamber_foreignbody == "No"
          r_anteriorchamber_foreignbody = "Foreign Body #{opdrecord.read_attribute(:"r_anteriorchamber_foreignbody_comment")},"
          r_anteriorchamber_op = "#{r_anteriorchamber_op} #{r_anteriorchamber_foreignbody}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        if opdrecord.r_anteriorchamber_comments.try(:length).to_i > 0
          r_anteriorchamber_comments = "#{opdrecord.read_attribute(:"r_anteriorchamber_comments")}"
          r_anteriorchamber_comments_op = "#{r_anteriorchamber_comments}"
          r_anteriorchamber_counter = r_anteriorchamber_counter + 1

        end
        unless r_anteriorchamber_op.blank?
          r_anteriorchamber_op = r_anteriorchamber_op.split("")
          r_anteriorchamber_op_count = r_anteriorchamber_op.count
          if r_anteriorchamber_op_count > 0
            r_anteriorchamber_op = (r_anteriorchamber_op.first r_anteriorchamber_op_count - 1).join()
          end
        end
      end
    end
    if r_anteriorchamber_comments_op.present?
      r_anteriorchamber_op += r_anteriorchamber_comments_op
    end
    if r_anteriorchamber_counter == 0 and opdrecord.r_local_examination_normal == "normal"
      r_anteriorchamber_op = "Anterior Chamber: Normal depth, No cells/flare"
    end
    # push Anterior chamer to Anterior segment array
    r_anterior_segment_op["anteriorchamber"] = r_anteriorchamber_op
    # code for pupil data
    r_pupil_counter = 0
    r_pupil_op = ""
    r_pupil_comments_op = ""
    r_pupil_comments = ""
    r_pupil_shape = ""
    r_pupil_reaction_to_light_direct = ""
    r_pupil_reaction_to_light_consensual = ""
    r_pupil_rapd = ""
    if opdrecord.r_pupil.present?
      unless opdrecord.r_pupil == "Normal" && opdrecord.r_pupil_normal != "normal"
        r_pupil_op = "Pupil: "
        if opdrecord.r_pupil_shape.try(:length).to_i > 0
          r_pupil_shape = "Shape- #{opdrecord.read_attribute(:"r_pupil_shape")},"
          r_pupil_op = "#{r_pupil_op}#{r_pupil_shape}"
          r_pupil_counter = r_pupil_counter + 1

        end
        unless opdrecord.r_pupil_reaction_to_light_direct == "Normal" && opdrecord.r_pupil_normal != "normal"
          r_pupil_reaction_to_light_direct = "Reaction to light Direct- #{opdrecord.read_attribute(:"r_pupil_reaction_to_light_direct")},"
          r_pupil_op = "#{r_pupil_op} #{r_pupil_reaction_to_light_direct}"
          r_pupil_counter = r_pupil_counter + 1

        end
        unless opdrecord.r_pupil_reaction_to_light_consensual == "Normal" && opdrecord.r_pupil_normal != "normal"
          r_pupil_reaction_to_light_consensual = "Reaction to light Consensual- #{opdrecord.read_attribute(:"r_pupil_reaction_to_light_consensual")},"
          r_pupil_op = "#{r_pupil_op} #{r_pupil_reaction_to_light_consensual}"
          r_pupil_counter = r_pupil_counter + 1

        end
        unless opdrecord.r_pupil_rapd == "No"
          r_pupil_rapd = "RAPD,"
          r_pupil_op = "#{r_pupil_op} #{r_pupil_rapd}"
          r_pupil_counter = r_pupil_counter + 1

        end
        if opdrecord.r_pupil_comments.try(:length).to_i > 0
          r_pupil_comments = "#{opdrecord.read_attribute(:"r_pupil_comments")}"
          r_pupil_comments_op = "#{r_pupil_comments}"
          r_pupil_counter = r_pupil_counter + 1

        end
        unless r_pupil_op.blank?
          r_pupil_op = r_pupil_op.split("")
          r_pupil_op_count = r_pupil_op.count
          if r_pupil_op_count > 0
            r_pupil_op = (r_pupil_op.first r_pupil_op_count - 1).join()
          end
        end
      end
    end
    if r_pupil_comments_op.present?
      r_pupil_op += r_pupil_comments_op
    end
    if r_pupil_counter == 0 and opdrecord.r_local_examination_normal == "normal"
      r_pupil_op = "Pupil: Round shape, Normal direct & Consensual reflex"
    end
    # push pupil to anterior
    r_anterior_segment_op["pupil"] = r_pupil_op
    # CODE FOR IRIS
    r_iris_counter = 0
    r_iris_op = ""
    r_iris_comments_op = ""
    r_iris_comments = ""
    r_iris_shape = ""
    r_iris_neovascularisation = ""
    r_iris_synechiae = ""
    unless opdrecord.r_iris.blank?
      unless opdrecord.r_iris == "Normal"
        r_iris_op = "Iris: "
        unless opdrecord.r_iris_shape == "Normal"
          r_iris_shape = "Shape- #{opdrecord.read_attribute(:"r_iris_shape")},"
          r_iris_op = "#{r_iris_op}#{r_iris_shape}"
          r_iris_counter = r_iris_counter + 1

        end
        unless opdrecord.r_iris_neovascularisation == "No"
          r_iris_neovascularisation = "Neovascularisation"
          r_iris_op = "#{r_iris_op} #{r_iris_neovascularisation}"
          r_iris_counter = r_iris_counter + 1

        end
        unless opdrecord.r_iris_synechiae == "No"
          r_iris_synechiae = "Synechiae- #{opdrecord.read_attribute(:"r_iris_synechiae")},"
          r_iris_op = "#{r_iris_op} #{r_iris_synechiae}"
          r_iris_counter = r_iris_counter + 1

        end
        if opdrecord.r_iris_comments.try(:length).to_i > 0
          r_iris_comments = "#{opdrecord.read_attribute(:"r_iris_comments")}"
          r_iris_comments_op = "#{r_iris_comments}"
          r_iris_counter = r_iris_counter + 1

        end
        unless r_iris_op.blank?
          r_iris_op = r_iris_op.split("")
          r_iris_op_count = r_iris_op.count
          if r_iris_op_count > 0
            r_iris_op = (r_iris_op.first r_iris_op_count - 1).join()
          end
        end
      end
    end
    if r_iris_comments_op.present?
      r_iris_op += ",Comment: " + r_iris_comments_op
    end
    # push iris to anterior
    r_anterior_segment_op["iris"] = r_iris_op
    # code for lens
    r_lens_counter = 0
    r_lens_op = ""
    r_lens_comments_op = ""
    r_lens_comments = ""
    r_lens_nature = ""
    r_lens_position = ""
    r_lens_size = ""
    r_lens_grading_no = ""
    r_lens_grading_nc = ""
    r_lens_grading_c = ""
    r_lens_grading_p = ""
    unless opdrecord.r_lens.blank?
      unless opdrecord.r_lens == "Normal"
        r_lens_op = "Lens: "
        unless opdrecord.r_lens_nature == "Clear"
          r_lens_nature = "Nature- #{opdrecord.read_attribute(:"r_lens_nature")},"
          r_lens_op = "#{r_lens_op}#{r_lens_nature}"
          r_lens_counter = r_lens_counter + 1
        end
        unless opdrecord.r_lens_position == "Central"
          r_lens_position = "Position- #{opdrecord.read_attribute(:"r_lens_position")},"
          r_lens_op = "#{r_lens_op} #{r_lens_position}"
          r_lens_counter = r_lens_counter + 1
        end
        unless opdrecord.r_lens_size == "Normal"
          r_lens_size = "Lens Size- #{opdrecord.read_attribute(:"r_lens_size")},"
          r_lens_op = "#{r_lens_op} #{r_lens_size}"
          r_lens_counter = r_lens_counter + 1
        end

        if opdrecord.r_lens_grading_no.present?
          r_lens_grading_no = "NO:#{opdrecord.read_attribute(:"r_lens_grading_no")}"
        end
        if opdrecord.r_lens_grading_nc.present?
          r_lens_grading_nc = "NC:#{opdrecord.read_attribute(:"r_lens_grading_nc")}"
        end
        if opdrecord.r_lens_grading_c.present?
          r_lens_grading_c = "C:#{opdrecord.read_attribute(:"r_lens_grading_c")}"
        end
        if opdrecord.r_lens_grading_p.present?
          r_lens_grading_p = "P:#{opdrecord.read_attribute(:"r_lens_grading_p")}"
        end

        if opdrecord.r_lens_grading_no.present? || opdrecord.r_lens_grading_nc.present? || opdrecord.r_lens_grading_c.present? || opdrecord.r_lens_grading_p.present?
          r_lens_grading = "Lens Grading- #{r_lens_grading_no} #{r_lens_grading_nc} #{r_lens_grading_c} #{r_lens_grading_p},"
          r_lens_op = "#{r_lens_op} #{r_lens_grading}"
          r_lens_counter = r_lens_counter + 1
        end

        if opdrecord.r_lens_comments.try(:length).to_i > 0
          r_lens_comments = "#{opdrecord.read_attribute(:"r_lens_comments")}"
          r_lens_comments_op = "#{r_lens_comments}"
          r_lens_counter = r_lens_counter + 1
        end
        unless r_lens_op.blank?
          r_lens_op = r_lens_op.split("")
          r_lens_op_count = r_lens_op.count
          if r_lens_op_count > 0
            r_lens_op = (r_lens_op.first r_lens_op_count - 1).join()
          end
        end
      end
    end
    if r_lens_comments_op.present?
      r_lens_op += r_lens_comments_op
    end
    if r_lens_counter == 0 and opdrecord.r_local_examination_normal == "normal"
      r_lens_op = "Lens:Clear, Crystalline, Central"
    end
    # push lens to anterior
    r_anterior_segment_op["lens"] = r_lens_op
    r_anterior_segment_op
  end

  def get_l_anterior_segment(opdrecord)
    l_anterior_segment_op = {}
    l_conjunctiva_counter = 0
    l_conjunctiva_op = ""
    l_conjunctiva_congestion = ""
    l_conjunctiva_conjunctivitis = ""
    l_conjunctiva_episcleritis = ""
    l_conjunctiva_tear = ""
    l_conjunctiva_subconjunctival_haemorrhage = ""
    l_conjunctiva_foreign_body = ""
    l_conjunctiva_follicles = ""
    l_conjunctiva_papillae = ""
    l_conjunctiva_pinguecula = ""
    l_conjunctiva_pterygium = ""
    l_conjunctiva_phlycten = ""
    l_conjunctiva_discharge = ""
    l_conjunctiva_conjuctival_blib = ""
    l_conjunctiva_comments = ""
    unless opdrecord.l_conjunctiva.blank?
      unless opdrecord.l_conjunctiva == "Normal"
        l_conjunctiva_op += "Conjunctiva: "
        unless opdrecord.l_conjunctiva_congestion == "No"
          if opdrecord.l_conjunctiva_congestion_lgc != ""
            l_conjunctiva_congestion_lgc = "-" + opdrecord.l_conjunctiva_congestion_lgc.to_s
          else
            l_conjunctiva_congestion_lgc = ""
          end
          l_conjunctiva_congestion = "Congestion#{l_conjunctiva_congestion_lgc},"
          l_conjunctiva_op = "#{l_conjunctiva_op}#{l_conjunctiva_congestion}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1

          l_conjunctiva_congestion_lgc = opdrecord.l_conjunctiva_congestion_lgc
        end
        if false
          unless opdrecord.l_conjunctiva_conjunctivitis == "No"
            l_conjunctiva_conjunctivitis = "Conjunctivitis,"
            l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_conjunctivitis}"
            l_conjunctiva_counter = l_conjunctiva_counter + 1

          end
          unless opdrecord.l_conjunctiva_episcleritis == "No"
            l_conjunctiva_episcleritis = "Episcleritis,"
            l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_episcleritis}"
            l_conjunctiva_counter = l_conjunctiva_counter + 1

          end
        end
        unless opdrecord.l_conjunctiva_tear == "No"
          l_conjunctiva_tear = "Tear,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_tear}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1

        end
        unless opdrecord.l_conjunctiva_conjuctival_blib == "No"
          l_conjunctiva_conjuctival_blib = "Conjuctival Bleb,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_conjuctival_blib}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1

        end
        unless opdrecord.l_conjunctiva_subconjunctival_haemorrhage == "No"
          l_conjunctiva_subconjunctival_haemorrhage = "SubConjunctival Haemorrhage,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_subconjunctival_haemorrhage}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1

        end
        if opdrecord.l_conjunctiva_foreign_body == "Yes"
          l_conjunctiva_foreign_body = "Foreign Body,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_foreign_body}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1

        end

        if opdrecord.l_conjunctiva_follicles == "Yes"
          l_conjunctiva_follicles = "Follicles,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_follicles}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1
        end
        if opdrecord.l_conjunctiva_papillae == "Yes"
          l_conjunctiva_papillae = "Papillae,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_papillae}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1
        end
        if opdrecord.l_conjunctiva_pinguecula == "Yes"
          l_conjunctiva_pinguecula = "Pinguecula,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_pinguecula}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1
        end
        if opdrecord.l_conjunctiva_pterygium == "Yes"
          l_conjunctiva_pterygium = "Pterygium,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_pterygium}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1
        end
        if opdrecord.l_conjunctiva_phlycten == "Yes"
          l_conjunctiva_phlycten = "Phlycten,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_phlycten}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1
        end
        if opdrecord.l_conjunctiva_discharge == "Yes"
          l_conjunctiva_discharge = "Discharge,"
          l_conjunctiva_op = "#{l_conjunctiva_op} #{l_conjunctiva_discharge}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1
        end

        if opdrecord.l_conjunctiva_comments.present?
          l_conjunctiva_comments = "#{opdrecord.read_attribute(:"l_conjunctiva_comments")}"
          l_conjunctiva_comments_op = " #{l_conjunctiva_comments}"
          l_conjunctiva_counter = l_conjunctiva_counter + 1

        end
        unless l_conjunctiva_op.blank?
          l_conjunctiva_op = l_conjunctiva_op.split("")
          l_conjunctiva_op_count = l_conjunctiva_op.count
          if l_conjunctiva_op_count > 0
            l_conjunctiva_op = (l_conjunctiva_op.first l_conjunctiva_op_count - 1).join()
          end
        end
      end
    end
    if l_conjunctiva_counter > 0
      if l_conjunctiva_comments_op.present?
        l_conjunctiva_op += l_conjunctiva_comments_op
      end
    elsif opdrecord.l_local_examination_normal == "normal"
      l_conjunctiva_op = "Conjunctiva: Normal"
    end
    # push to anterior segment array
    l_anterior_segment_op["conjunctiva"] = l_conjunctiva_op

    l_cornea_counter = 0
    l_corneaslit_counter = 0
    l_cornea_op = ""
    l_cornea_size = ""
    l_cornea_shape = ""
    l_cornea_schirmer_test = ""

    l_cornea_surface = ""
    l_cornea_comments_op = ""
    l_cornea_comments = ""
    unless opdrecord.l_cornea.blank?
      unless opdrecord.l_cornea == "Normal" && opdrecord.l_cornea_normal != "normal"
        l_cornea_op = "Cornea: "
        unless opdrecord.l_cornea_size == "Normal" && opdrecord.l_cornea_normal != "normal"
          l_cornea_size = "Size- #{opdrecord.read_attribute(:"l_cornea_size")},"
          l_cornea_op = "#{l_cornea_op}#{l_cornea_size}"
          l_cornea_counter = l_cornea_counter + 1

        end
        unless opdrecord.l_cornea_shape == "Normal" && opdrecord.l_cornea_normal != "normal"
          l_cornea_shape = "Shape- #{opdrecord.read_attribute(:"l_cornea_shape")},"
          l_cornea_op = "#{l_cornea_op} #{l_cornea_shape}"
          l_cornea_counter = l_cornea_counter + 1

        end
        unless opdrecord.l_cornea_surface == "Normal" && opdrecord.l_cornea_normal != "normal"
          l_cornea_surface = "Surface- #{opdrecord.read_attribute(:"l_cornea_surface")},"
          l_cornea_op = "#{l_cornea_op} #{l_cornea_surface}"
          l_cornea_counter = l_cornea_counter + 1

        end
        unless opdrecord.l_cornea_schirmer_test == ""
          l_cornea_schirmer_test = "Schirmer Test-#{opdrecord.read_attribute(:"l_cornea_schirmer_test")}(#{opdrecord.read_attribute(:"l_cornea_schirmer_dimension")}mm in #{opdrecord.read_attribute(:"l_cornea_schirmer_time")} min),"
          l_cornea_op = "#{l_cornea_op} #{l_cornea_schirmer_test}"
          l_cornea_counter = l_cornea_counter + 1

        end
        if opdrecord.l_cornea_diagram_present == "Y"
          l_cornea_counter = l_cornea_counter + 1

        end
        if opdrecord.l_corneaslit_diagram_present == "Y"
          l_corneaslit_counter = l_corneaslit_counter + 1

        end
        if opdrecord.l_cornea_comments.try(:length).to_i > 0
          l_cornea_comments = "#{opdrecord.read_attribute(:"l_cornea_comments")}"
          l_cornea_comments_op = "#{l_cornea_comments}"
          l_cornea_counter = l_cornea_counter + 1

        end
        unless l_cornea_op.blank?
          l_cornea_op = l_cornea_op.split("")
          l_cornea_op_count = l_cornea_op.count
          if l_cornea_op_count > 0
            l_cornea_op = (l_cornea_op.first l_cornea_op_count - 1).join()
          end
        end
      end
    end
    if l_cornea_comments_op.present?
      l_cornea_op += l_cornea_comments_op
    end
    if l_cornea_counter == 0 and opdrecord.l_local_examination_normal == "normal"
      l_cornea_op = "Cornea: Size/Shape/Surface Normal"
    end
    # push to anterior segment array
    l_anterior_segment_op["cornea"] = l_cornea_op

    # code for anterior chamber
    l_anteriorchamber_counter = 0
    l_anteriorchamber_op = ""
    l_anteriorchamber_comments_op = ""
    l_anteriorchamber_comments = ""
    l_anteriorchamber_depth = ""
    l_anteriorchamber_reaction = ""
    l_anteriorchamber_cells = ""
    l_anteriorchamber_flare = ""
    l_anteriorchamber_hyphema = ""
    l_anteriorchamber_hypopyon = ""
    l_anteriorchamber_foreignbody = ""

    l_anteriorchamber_depth_comment = ""
    l_anteriorchamber_reaction_comment = ""
    l_anteriorchamber_cells_comment = ""
    l_anteriorchamber_flare_comment = ""
    l_anteriorchamber_hyphema_comment = ""
    l_anteriorchamber_hypopyon_comment = ""
    l_anteriorchamber_foreignbody_comment = ""
    unless opdrecord.l_anteriorchamber.blank?
      unless opdrecord.l_anteriorchamber == "Normal"
        l_anteriorchamber_op = "Anterior Chamber: "
        unless opdrecord.l_anteriorchamber_depth == "Normal"
          l_anteriorchamber_depth = "Depth- #{opdrecord.read_attribute(:"l_anteriorchamber_depth")} #{opdrecord.read_attribute(:"l_anteriorchamber_depth_comment")},"
          l_anteriorchamber_op = "#{l_anteriorchamber_op}#{l_anteriorchamber_depth}"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end

        unless opdrecord.l_anteriorchamber_cells == "No"
          l_anteriorchamber_cells = "Cells #{opdrecord.read_attribute(:"l_anteriorchamber_cells_comment")}"
          l_anteriorchamber_op = "#{l_anteriorchamber_op} #{l_anteriorchamber_cells},"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end
        unless opdrecord.l_anteriorchamber_flare == "No"
          l_anteriorchamber_flare = "Flare #{opdrecord.read_attribute(:"l_anteriorchamber_flare_comment")}"
          l_anteriorchamber_op = "#{l_anteriorchamber_op} #{l_anteriorchamber_flare},"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end
        unless opdrecord.l_anteriorchamber_hyphema == "No"
          l_anteriorchamber_hyphema = "Hyphema #{opdrecord.read_attribute(:"l_anteriorchamber_hyphema_comment")}"
          l_anteriorchamber_op = "#{l_anteriorchamber_op} #{l_anteriorchamber_hyphema},"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end
        unless opdrecord.l_anteriorchamber_hypopyon == "No"
          l_anteriorchamber_hypopyon = "Hypopyon #{opdrecord.read_attribute(:"l_anteriorchamber_hypopyon_comment")}"
          l_anteriorchamber_op = "#{l_anteriorchamber_op} #{l_anteriorchamber_hypopyon},"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end
        unless opdrecord.l_anteriorchamber_foreignbody == "No"
          l_anteriorchamber_foreignbody = "Foreign Body #{opdrecord.read_attribute(:"l_anteriorchamber_foreignbody_comment")}"
          l_anteriorchamber_op = "#{l_anteriorchamber_op} #{l_anteriorchamber_foreignbody},"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end
        if opdrecord.l_anteriorchamber_comments.try(:length).to_i > 0
          l_anteriorchamber_comments = "#{opdrecord.read_attribute(:"l_anteriorchamber_comments")}"
          l_anteriorchamber_comments_op = "#{l_anteriorchamber_comments}"
          l_anteriorchamber_counter = l_anteriorchamber_counter + 1

        end
        unless l_anteriorchamber_op.blank?
          l_anteriorchamber_op = l_anteriorchamber_op.split("")
          l_anteriorchamber_op_count = l_anteriorchamber_op.count
          if l_anteriorchamber_op_count > 0
            l_anteriorchamber_op = (l_anteriorchamber_op.first l_anteriorchamber_op_count - 1).join()
          end
        end
      end
    end
    if l_anteriorchamber_comments_op.present?
      l_anteriorchamber_op += l_anteriorchamber_comments_op
    end
    if l_anteriorchamber_counter == 0 and opdrecord.l_local_examination_normal == "normal"
      l_anteriorchamber_op = "Anterior Chamber: Normal depth, No cells/flare"
    end
    # push Anterior chamer to Anterior segment array
    l_anterior_segment_op["anteriorchamber"] = l_anteriorchamber_op
    # code for pupil

    l_pupil_counter = 0
    l_pupil_op = ""
    l_pupil_comments_op = ""
    l_pupil_comments = ""
    l_pupil_shape = ""
    l_pupil_reaction_to_light_direct = ""
    l_pupil_reaction_to_light_consensual = ""
    l_pupil_rapd = ""
    unless opdrecord.l_pupil.blank?
      unless opdrecord.l_pupil == "Normal" && opdrecord.l_pupil_normal != "normal"
        l_pupil_op = "Pupil: "
        if opdrecord.l_pupil_shape.try(:length).to_i > 0
          l_pupil_shape = "Shape- #{opdrecord.read_attribute(:"l_pupil_shape")},"
          l_pupil_op = "#{l_pupil_op}#{l_pupil_shape}"
          l_pupil_counter = l_pupil_counter + 1

        end
        unless opdrecord.l_pupil_reaction_to_light_direct == "Normal" && opdrecord.l_pupil_normal != "normal"
          l_pupil_reaction_to_light_direct = "Reaction to light Direct- #{opdrecord.read_attribute(:"l_pupil_reaction_to_light_direct")},"
          l_pupil_op = "#{l_pupil_op} #{l_pupil_reaction_to_light_direct}"
          l_pupil_counter = l_pupil_counter + 1

        end
        unless opdrecord.l_pupil_reaction_to_light_consensual == "Normal" && opdrecord.l_pupil_normal != "normal"
          l_pupil_reaction_to_light_consensual = "Reaction to light consensual- #{opdrecord.read_attribute(:"l_pupil_reaction_to_light_consensual")},"
          l_pupil_op = "#{l_pupil_op} #{l_pupil_reaction_to_light_consensual}"
          l_pupil_counter = l_pupil_counter + 1

        end
        unless opdrecord.l_pupil_rapd == "No"
          l_pupil_rapd = "RAPD,"
          l_pupil_op = "#{l_pupil_op} #{l_pupil_rapd}"
          l_pupil_counter = l_pupil_counter + 1

        end
        if opdrecord.l_pupil_comments.try(:length).to_i > 0
          l_pupil_comments = "#{opdrecord.read_attribute(:"l_pupil_comments")}"
          l_pupil_comments_op = "#{l_pupil_comments}"
          l_pupil_counter = l_pupil_counter + 1

        end
        unless l_pupil_op.blank?
          l_pupil_op = l_pupil_op.split("")
          l_pupil_op_count = l_pupil_op.count
          if l_pupil_op_count > 0
            l_pupil_op = (l_pupil_op.first l_pupil_op_count - 1).join()
          end
        end
      end
    end
    if l_pupil_comments_op.present?
      l_pupil_op += l_pupil_comments_op
    end
    if l_pupil_counter == 0 and opdrecord.l_local_examination_normal == "normal"
      l_pupil_op = "Pupil: Round shape, Normal direct & Consensual reflex"
    end
    # push to anterior segment array
    l_anterior_segment_op["pupil"] = l_pupil_op
    # code for iris
    l_iris_counter = 0
    l_iris_op = ""
    l_iris_comments_op = ""
    l_iris_comments = ""
    l_iris_shape = ""
    l_iris_neovascularisation = ""
    l_iris_synechiae = ""
    unless opdrecord.l_iris.blank?
      unless opdrecord.l_iris == "Normal"
        l_iris_op = "Iris: "
        unless opdrecord.l_iris_shape == "Normal"
          l_iris_shape = "Shape- #{opdrecord.read_attribute(:"l_iris_shape")},"
          l_iris_op = "#{l_iris_op}#{l_iris_shape}"
          l_iris_counter = l_iris_counter + 1

        end
        unless opdrecord.l_iris_neovascularisation == "No"
          l_iris_neovascularisation = "Neovascularisation,"
          l_iris_op = "#{l_iris_op}, #{l_iris_neovascularisation}"
          l_iris_counter = l_iris_counter + 1

        end
        unless opdrecord.l_iris_synechiae == "No"
          l_iris_synechiae = "Synechiae- #{opdrecord.read_attribute(:"l_iris_synechiae")},"
          l_iris_op = "#{l_iris_op}, #{l_iris_synechiae}"
          l_iris_counter = l_iris_counter + 1

        end
        if opdrecord.l_iris_comments.try(:length).to_i > 0
          l_iris_comments = "#{opdrecord.read_attribute(:"l_iris_comments")}"
          l_iris_comments_op = "#{l_iris_comments}"
          l_iris_counter = l_iris_counter + 1

        end
        unless l_iris_op.blank?
          l_iris_op = l_iris_op.split("")
          l_iris_op_count = l_iris_op.count
          if l_iris_op_count > 0
            l_iris_op = (l_iris_op.first l_iris_op_count - 1).join()
          end
        end
      end
    end
    if l_iris_comments_op.present?
      l_iris_op += l_iris_comments_op
    end
    # push iris to anterior
    l_anterior_segment_op["iris"] = l_iris_op
    # code for lens
    l_lens_counter = 0
    l_lens_op = ""
    l_lens_comments_op = ""
    l_lens_comments = ""
    l_lens_nature = ""
    l_lens_position = ""
    l_lens_size = ""
    l_lens_grading_no = ""
    l_lens_grading_nc = ""
    l_lens_grading_c = ""
    l_lens_grading_p = ""
    unless opdrecord.l_lens.blank?
      unless opdrecord.l_lens == "Normal"
        l_lens_op = "Lens: "
        unless opdrecord.l_lens_nature == "Clear"
          l_lens_nature = "Nature- #{opdrecord.read_attribute(:"l_lens_nature")},"
          l_lens_op = "#{l_lens_op}#{l_lens_nature}"
          l_lens_counter = l_lens_counter + 1
        end
        unless opdrecord.l_lens_position == "Central"
          l_lens_position = "Position- #{opdrecord.read_attribute(:"l_lens_position")},"
          l_lens_op = "#{l_lens_op} #{l_lens_position}"
          l_lens_counter = l_lens_counter + 1
        end
        unless opdrecord.l_lens_size == "Normal"
          l_lens_size = "Lens Size- #{opdrecord.read_attribute(:"l_lens_size")},"
          l_lens_op = "#{l_lens_op} #{l_lens_size}"
          l_lens_counter = l_lens_counter + 1
        end
        if opdrecord.l_lens_grading_no.present?
          l_lens_grading_no = "NO:#{opdrecord.read_attribute(:"l_lens_grading_no")}"
        end
        if opdrecord.l_lens_grading_nc.present?
          l_lens_grading_nc = "NC:#{opdrecord.read_attribute(:"l_lens_grading_nc")}"
        end
        if opdrecord.l_lens_grading_c.present?
          l_lens_grading_c = "C:#{opdrecord.read_attribute(:"l_lens_grading_c")}"
        end
        if opdrecord.l_lens_grading_p.present?
          l_lens_grading_p = "P:#{opdrecord.read_attribute(:"l_lens_grading_p")}"
        end

        if opdrecord.l_lens_grading_no.present? || opdrecord.l_lens_grading_nc.present? || opdrecord.l_lens_grading_c.present? || opdrecord.l_lens_grading_p.present?
          l_lens_grading = "Lens Grading- #{l_lens_grading_no} #{l_lens_grading_nc} #{l_lens_grading_c} #{l_lens_grading_p},"
          l_lens_op = "#{l_lens_op} #{l_lens_grading}"
          l_lens_counter = l_lens_counter + 1
        end
        if opdrecord.l_lens_comments.try(:length).to_i > 0
          l_lens_comments = "#{opdrecord.read_attribute(:"l_lens_comments")}"
          l_lens_comments_op = "#{l_lens_comments}"
          l_lens_counter = l_lens_counter + 1
        end
        unless l_lens_op.blank?
          l_lens_op = l_lens_op.split("")
          l_lens_op_count = l_lens_op.count
          if l_lens_op_count > 0
            l_lens_op = (l_lens_op.first l_lens_op_count - 1).join()
          end
        end
      end
    end
    if l_lens_comments_op.present?
      l_lens_op += l_lens_comments_op
    end
    if l_lens_counter == 0 and opdrecord.l_local_examination_normal == "normal"
      l_lens_op = "Lens:Clear, Crystalline, Central"
    end
    # push lens to anterior
    l_anterior_segment_op["lens"] = l_lens_op
    # return
    l_anterior_segment_op
  end

  def get_r_appendage(opdrecord)
    r_appendages_counter = 0
    r_appendages_op = ""
    r_appendages_comments = 0
    r_eyelsahes_counter = 0
    r_eyelid_counter = 0
    r_lacrimar_counter = 0
    r_syringing_counter = 0
    unless opdrecord.r_appendages_tests.blank?
      if opdrecord.r_appendages_tests.include? "eyelids"
        unless opdrecord.r_appendages_eyelids_chalazion == "No"
          r_eyelid_counter = r_eyelid_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
        unless opdrecord.r_appendages_eyelids_ptosis == "No"
          r_eyelid_counter = r_eyelid_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
        unless opdrecord.r_appendages_eyelids_swelling == "No"
          r_eyelid_counter = r_eyelid_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
        unless opdrecord.r_appendages_eyelids_entropion == "No"
          r_eyelid_counter = r_eyelid_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
        unless opdrecord.r_appendages_eyelids_ectropion == "No"
          r_eyelid_counter = r_eyelid_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
        unless opdrecord.r_appendages_eyelids_mass == "No"
          r_eyelid_counter = r_eyelid_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
      end
      if opdrecord.r_appendages_tests.include? "eyelashes"
        unless opdrecord.r_appendages_eyelashes_trichiasis == "No"
          r_eyelsahes_counter = r_eyelsahes_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
        unless opdrecord.r_appendages_eyelashes_dystrichiasis == "No"
          r_eyelsahes_counter = r_eyelsahes_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
      end
      if opdrecord.r_appendages_tests.include? "lacrimalsac"
        unless opdrecord.r_appendages_lacrimalsac_swelling == "No"
          r_lacrimar_counter = r_lacrimar_counter + 1
          r_appendages_counter = r_appendages_counter + 1

        end
        unless opdrecord.r_appendages_lacrimalsac_regurgitation == "No"
          r_lacrimar_counter = r_lacrimar_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
      end
      if opdrecord.r_appendages_tests.include? "syringing"
        unless opdrecord.r_appendages_syringing == "Patent"
          r_syringing_counter = r_syringing_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        else
          r_syringing_counter = r_syringing_counter + 1
          r_appendages_counter = r_appendages_counter + 1
        end
      end
    end

    if opdrecord.r_appendages_comments.present?
      r_appendages_comments = "#{opdrecord.read_attribute(:"r_appendages_comments")}"
      r_appendages_comments_op = " #{r_appendages_comments}"
      r_appendages_counter = r_appendages_counter + 1
    end
    if r_appendages_counter > 0
      if r_eyelid_counter > 0
        if opdrecord.r_appendages_tests.include? "eyelids"
          r_appendages_op += " Eyelids:"
          unless opdrecord.r_appendages_eyelids_chalazion == "No"
            r_appendages_op += "Chalazion,"
          end
          unless opdrecord.r_appendages_eyelids_ptosis == "No"
            r_appendages_op += "Ptosis,"
          end
          unless opdrecord.r_appendages_eyelids_swelling == "No"
            r_appendages_op += "Swelling,"
          end
          unless opdrecord.r_appendages_eyelids_entropion == "No"
            r_appendages_op += "Entropion,"
          end
          unless opdrecord.r_appendages_eyelids_ectropion == "No"
            r_appendages_op += "Ectropion,"
          end
          unless opdrecord.r_appendages_eyelids_mass == "No"
            r_appendages_op += "Eyelids mass,"
          end
        end
      end
      if r_eyelsahes_counter > 0
        if opdrecord.r_appendages_tests.include? "eyelashes"
          r_appendages_op += "Eyelashes:"
          unless opdrecord.r_appendages_eyelashes_trichiasis == "No"
            r_appendages_op += "Trichiasis,"
          end
          unless opdrecord.r_appendages_eyelashes_dystrichiasis == "No"
            r_appendages_op += "Dystrichiasis,"
          end
        end
      end
      if r_lacrimar_counter > 0
        if opdrecord.r_appendages_tests.include? "lacrimalsac"
          r_appendages_op += "Lacrimal sac:"
          unless opdrecord.r_appendages_lacrimalsac_swelling == "No"
            r_appendages_op += "Swelling"
          end
          unless opdrecord.r_appendages_lacrimalsac_regurgitation == "No"
            r_appendages_op += "Regurgitation"
          end
        end
      end
      if r_syringing_counter > 0
        if opdrecord.r_appendages_tests.include? "syringing"
          r_appendages_op += "Syringing:"
          unless opdrecord.r_appendages_syringing == "Patent"
            r_appendages_op += "Blocked"
          else
            r_appendages_op += "Patent"
          end
        end
      end

      if r_appendages_comments_op.present?
        r_appendages_op += r_appendages_comments_op
      end
    end
    r_appendages_op
  end

  def get_l_appendage(opdrecord)
    l_appendages_counter = 0
    l_appendages_op = ""
    l_appendages_comments = 0
    l_eyelsahes_counter = 0
    l_eyelid_counter = 0
    l_lacrimal_counter = 0
    l_syringing_counter = 0

    if opdrecord.l_appendages == "Abnormal"
      unless opdrecord.l_appendages_tests.blank?
        if opdrecord.l_appendages_tests.include? "eyelids"
          unless opdrecord.l_appendages_eyelids_chalazion == "No"
            l_eyelid_counter = l_eyelid_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end
          unless opdrecord.l_appendages_eyelids_ptosis == "No"
            l_eyelid_counter = l_eyelid_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end
          unless opdrecord.l_appendages_eyelids_swelling == "No"
            l_eyelid_counter = l_eyelid_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end
          unless opdrecord.l_appendages_eyelids_entropion == "No"
            l_eyelid_counter = l_eyelid_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end
          unless opdrecord.l_appendages_eyelids_ectropion == "No"
            l_eyelid_counter = l_eyelid_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end
          unless opdrecord.l_appendages_eyelids_mass == "No"
            l_eyelid_counter = l_eyelid_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end

        end
        if opdrecord.l_appendages_tests.include? "eyelashes"
          unless opdrecord.l_appendages_eyelashes_trichiasis == "No"
            l_eyelsahes_counter = l_eyelsahes_counter + 1
            l_appendages_counter = l_appendages_counter + 1
          end
          unless opdrecord.l_appendages_eyelashes_dystrichiasis == "No"
            l_eyelsahes_counter = l_eyelsahes_counter + 1
            l_appendages_counter = l_appendages_counter + 1
          end
        end
        if opdrecord.l_appendages_tests.include? "lacrimalsac"

          unless opdrecord.l_appendages_lacrimalsac_swelling == "No"
            l_lacrimal_counter = l_lacrimal_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end
          unless opdrecord.l_appendages_lacrimalsac_regurgitation == "No"
            l_lacrimal_counter = l_lacrimal_counter + 1
            l_appendages_counter = l_appendages_counter + 1
          end
        end
        if opdrecord.l_appendages_tests.include? "syringing"

          unless opdrecord.l_appendages_syringing == "Patent"
            l_syringing_counter = l_syringing_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          else
            l_syringing_counter = l_syringing_counter + 1
            l_appendages_counter = l_appendages_counter + 1

          end

        end
      end
      if opdrecord.l_appendages_comments.present?
        l_appendages_comments = "#{opdrecord.read_attribute(:"l_appendages_comments")}"
        l_appendages_comments_op = " #{l_appendages_comments}"
        l_appendages_counter = l_appendages_counter + 1
      end
    end
    if l_appendages_counter > 0
      if l_eyelid_counter > 0
        if opdrecord.l_appendages_tests.include? "eyelids"
          l_appendages_op += "Eyelids:"
          unless opdrecord.l_appendages_eyelids_chalazion == "No"
            l_appendages_op += "Chalazion,"
          end
          unless opdrecord.l_appendages_eyelids_ptosis == "No"
            l_appendages_op += "Ptosis,"
          end
          unless opdrecord.l_appendages_eyelids_swelling == "No"
            l_appendages_op += "Swelling,"
          end
          unless opdrecord.l_appendages_eyelids_entropion == "No"
            l_appendages_op = l_appendages_op + "Entropion,"
          end
          unless opdrecord.l_appendages_eyelids_ectropion == "No"
            l_appendages_op += "Ectropion,"
          end
          unless opdrecord.l_appendages_eyelids_mass == "No"
            l_appendages_op += "Eyelids mass,"
          end
        end
      end
      if l_eyelsahes_counter > 0
        if opdrecord.l_appendages_tests.include? "eyelashes"
          l_appendages_op += " Eyelashes:"
          unless opdrecord.l_appendages_eyelashes_trichiasis == "No"
            l_appendages_op += "Trichiasis,"
          end
          unless opdrecord.l_appendages_eyelashes_dystrichiasis == "No"
            l_appendages_op += "Dystrichiasis,"
          end
        end
      end
      if l_lacrimal_counter > 0
        if opdrecord.l_appendages_tests.include? "lacrimalsac"
          l_appendages_op += " Lacrimal sac:"
          unless opdrecord.l_appendages_lacrimalsac_swelling == "No"
            l_appendages_op += "Swelling,"
          end
          unless opdrecord.l_appendages_lacrimalsac_regurgitation == "No"
            l_appendages_op += "Regurgitation,"
          end
        end
      end
      if l_syringing_counter > 0
        if opdrecord.l_appendages_tests.include? "syringing"
          "Syringing:"
          unless opdrecord.l_appendages_syringing == "Patent"
            l_appendages_op += " Blocked,"
          else
            l_appendages_op += "Patent"
          end
        end
      end
    end
    if l_appendages_comments_op.present?
      l_appendages_op += l_appendages_comments_op
    end
    l_appendages_op
  end

  def get_r_iop(opdrecord)
    r_intraocularpressure_counter = 0
    r_intraocularpressure_op = ""
    r_intraocularpressure = ""
    r_intraocularpressure_time = ""
    r_iop_method = ""
    r_iop_comment = ""
    r_intraocularpressure_comments = ""
    final_op = ""

    if opdrecord.r_intraocularpressure.present?
      r_intraocularpressure = "#{opdrecord.read_attribute(:"r_intraocularpressure")}"
      r_intraocularpressure_op = "#{r_intraocularpressure_op}#{r_intraocularpressure}"
      r_intraocularpressure_counter = r_intraocularpressure_counter + 1

    end

    if opdrecord.r_intraocularpressure_time.present?
      r_intraocularpressure_time = "#{opdrecord.read_attribute(:"r_intraocularpressure_time")}"
      r_intraocularpressure_op = "#{r_intraocularpressure_op} at #{r_intraocularpressure_time}"
      r_intraocularpressure_counter = r_intraocularpressure_counter + 1
    end

    if opdrecord.r_iop_method.present?
      r_iop_method = "#{opdrecord.read_attribute(:"r_iop_method")}"
      r_intraocularpressure_op = "#{r_intraocularpressure_op} with #{r_iop_method}"
      r_intraocularpressure_counter = r_intraocularpressure_counter + 1
    end

    if opdrecord.r_intraocularpressure_comments.present?
      r_intraocularpressure_comments = "#{opdrecord.read_attribute(:"r_intraocularpressure_comments")}"
      r_intraocularpressure_counter = r_intraocularpressure_counter + 1
    end
    if opdrecord.r_iop_comments.present?
      r_iop_comments = "#{opdrecord.read_attribute(:"r_iop_comments")}"
      if r_intraocularpressure_comments.present?
        r_intraocularpressure_comments = "#{r_intraocularpressure_comments}, "
      end
      r_intraocularpressure_comments = "#{r_intraocularpressure_comments}#{r_iop_comments}"
      r_intraocularpressure_counter = r_intraocularpressure_counter + 1
    end

    if r_intraocularpressure_counter > 0
      final_op = "IOP:"
      if r_intraocularpressure_op.to_i >= 0
        final_op += r_intraocularpressure_op
      end
      if r_intraocularpressure_comments.present?
        final_op += r_intraocularpressure_comments
      end

    end
    final_op
  end

  def get_l_iop(opdrecord)
    l_intraocularpressure_counter = 0
    l_intraocularpressure_op = ""
    l_intraocularpressure = ""
    l_intraocularpressure_time = ""
    l_iop_method = ""
    l_iop_comment = ""
    l_intraocularpressure_comments = ""
    final_op = ""
    if opdrecord.l_intraocularpressure.present?
      l_intraocularpressure = "#{opdrecord.read_attribute(:"l_intraocularpressure")}"
      l_intraocularpressure_op = "#{l_intraocularpressure_op}#{l_intraocularpressure}"
      l_intraocularpressure_counter = l_intraocularpressure_counter + 1

    end
    if opdrecord.l_intraocularpressure_time.present?
      l_intraocularpressure_time = "#{opdrecord.read_attribute(:"l_intraocularpressure_time")}"
      l_intraocularpressure_op = "#{l_intraocularpressure_op} at #{l_intraocularpressure_time}"
      l_intraocularpressure_counter = l_intraocularpressure_counter + 1
    end
    if opdrecord.l_iop_method.present?
      l_iop_method = "#{opdrecord.read_attribute(:"l_iop_method")}"
      l_intraocularpressure_op = "#{l_intraocularpressure_op} with #{l_iop_method}"
      l_intraocularpressure_counter = l_intraocularpressure_counter + 1
    end
    if opdrecord.l_intraocularpressure_comments.present?
      l_intraocularpressure_comments = "#{opdrecord.read_attribute(:"l_intraocularpressure_comments")}"
      l_intraocularpressure_counter = l_intraocularpressure_counter + 1
    end

    if opdrecord.l_iop_comments.present?
      l_iop_comments = "#{opdrecord.read_attribute(:"l_iop_comments")}"
      if l_intraocularpressure_comments.present?
        l_intraocularpressure_comments = "#{l_intraocularpressure_comments}, "
      end
      l_intraocularpressure_comments = "#{l_intraocularpressure_comments}#{l_iop_comments}"
      l_intraocularpressure_counter = l_intraocularpressure_counter + 1
    end
    if l_intraocularpressure_counter > 0
      final_op = "IOP:"
      if l_intraocularpressure_op.to_i >= 0
        final_op += l_intraocularpressure_op
      end
      if l_intraocularpressure_comments.present?
        final_op += l_intraocularpressure_comments
      end
    end
    final_op
  end

  def get_r_visualacuity(opdrecord)
    r_visualacuity_op = ""
    r_visualacuity_unaided = ""
    r_visualacuity_unaided_p = ""
    r_visualacuity_pinhole = ""
    r_visualacuity_pinhole_p = ""
    r_visualacuity_pinhole_ni = ""
    r_visualacuity_glasses = ""
    r_visualacuity_glasses_p = ""
    r_visualacuity_near = ""
    r_visualacuity_near_p = ""
    r_visualacuity_ua_near = ""
    r_visualacuity_ua_s = ""
    r_visualacuity_ua_n = ""
    r_visualacuity_ua_i = ""
    r_visualacuity_ua_t = ""
    r_visualacuity_ua_near_p = ""
    r_visualacuity_counter = 0
    if opdrecord.read_attribute(:r_visualacuity_unaided_p).present?
      r_visualacuity_unaided_p = "(#{opdrecord.read_attribute(:r_visualacuity_unaided_p)})"
    end
    unless opdrecord.r_visualacuity_unaided.blank?
      r_visualacuity_unaided = "UA - #{opdrecord.read_attribute(:"r_visualacuity_unaided")}#{r_visualacuity_unaided_p}"
      r_visualacuity_op = "#{r_visualacuity_unaided}"
    end

    if opdrecord.read_attribute(:r_visualacuity_pinhole_p).present?
      r_visualacuity_pinhole_p = "(#{opdrecord.read_attribute(:r_visualacuity_pinhole_p)})"
    end
    if opdrecord.read_attribute(:r_visualacuity_pinhole_ni).present?
      r_visualacuity_pinhole_ni = "(#{opdrecord.read_attribute(:r_visualacuity_pinhole_ni)})"
    end
    if opdrecord.read_attribute(:r_visualacuity_ua_near_p).present?
      r_visualacuity_ua_near_p = "(#{opdrecord.read_attribute(:r_visualacuity_ua_near_p)})"
    end
    unless opdrecord.r_visualacuity_ua_near.blank?
      r_visualacuity_ua_near = "UA Near- #{opdrecord.read_attribute(:"r_visualacuity_ua_near")}#{r_visualacuity_ua_near_p}"
      r_visualacuity_op = "#{r_visualacuity_op} #{r_visualacuity_ua_near}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end

    if opdrecord.r_visualacuity_ua_s.present?
      r_visualacuity_ua_s = "S#{opdrecord.read_attribute(:"r_visualacuity_ua_s")}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end
    if opdrecord.r_visualacuity_ua_i.present?
      r_visualacuity_ua_i = "I#{opdrecord.read_attribute(:"r_visualacuity_ua_i")}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end
    if opdrecord.r_visualacuity_ua_n.present?
      r_visualacuity_ua_n = "N#{opdrecord.read_attribute(:"r_visualacuity_ua_n")}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end
    if opdrecord.r_visualacuity_ua_t.present?
      r_visualacuity_ua_t = "T#{opdrecord.read_attribute(:"r_visualacuity_ua_t")}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end

    unless opdrecord.r_visualacuity_pinhole.blank?
      r_visualacuity_pinhole = "PH- #{opdrecord.read_attribute(:"r_visualacuity_pinhole")}#{r_visualacuity_pinhole_p}#{r_visualacuity_pinhole_ni}"
      r_visualacuity_op = "#{r_visualacuity_op} #{r_visualacuity_pinhole}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end
    if opdrecord.read_attribute(:r_visualacuity_glasses_p).present?
      r_visualacuity_glasses_p = "(#{opdrecord.read_attribute(:r_visualacuity_glasses_p)})"
    end
    unless opdrecord.r_visualacuity_glasses.blank?
      r_visualacuity_glasses = "Glasses- #{opdrecord.read_attribute(:"r_visualacuity_glasses")}#{r_visualacuity_glasses_p}"
      r_visualacuity_op = "#{r_visualacuity_op} #{r_visualacuity_glasses}"
      r_visualacuity_counter = r_visualacuity_counter + 1

    end
    if opdrecord.read_attribute(:r_visualacuity_near_p).present?
      r_visualacuity_near_p = "(#{opdrecord.read_attribute(:r_visualacuity_near_p)})"
    end
    unless opdrecord.r_visualacuity_near.blank?
      r_visualacuity_near = "Glasses Near- #{opdrecord.read_attribute(:"r_visualacuity_near")}#{r_visualacuity_near_p}"
      r_visualacuity_op = "#{r_visualacuity_op} #{r_visualacuity_near}"
    end
    r_visualacuity_op
  end

  def get_l_visualacuity(opdrecord)
    l_visualacuity_counter = 0
    l_visualacuity_op = ""
    l_visualacuity_unaided = ""
    l_visualacuity_unaided_p = ""
    l_visualacuity_pinhole = ""
    l_visualacuity_pinhole_p = ""
    l_visualacuity_pinhole_ni = ""
    l_visualacuity_glasses = ""
    l_visualacuity_glasses_p = ""
    l_visualacuity_near = ""
    l_visualacuity_ua_s = ""
    l_visualacuity_ua_n = ""
    l_visualacuity_ua_i = ""
    l_visualacuity_ua_t = ""
    l_visualacuity_near_p = ""
    l_visualacuity_ua_near = ""
    l_visualacuity_ua_near_p = ""
    final_op = ""
    if opdrecord.read_attribute(:l_visualacuity_unaided_p).present?
      l_visualacuity_unaided_p = "(#{opdrecord.read_attribute(:l_visualacuity_unaided_p)})"
    end
    unless opdrecord.l_visualacuity_unaided.blank?
      l_visualacuity_unaided = "UA - #{opdrecord.read_attribute(:"l_visualacuity_unaided")}#{l_visualacuity_unaided_p}"
      l_visualacuity_op = "#{l_visualacuity_unaided}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end

    if opdrecord.read_attribute(:l_visualacuity_ua_near_p).present?
      l_visualacuity_ua_near_p = "(#{opdrecord.read_attribute(:l_visualacuity_ua_near_p)})"
    end
    unless opdrecord.l_visualacuity_ua_near.blank?
      l_visualacuity_ua_near = "UA Near- #{opdrecord.read_attribute(:"l_visualacuity_ua_near")}#{l_visualacuity_ua_near_p}"
      l_visualacuity_op = "#{l_visualacuity_op} #{l_visualacuity_ua_near}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end

    if opdrecord.l_visualacuity_ua_s.present?
      l_visualacuity_ua_s = "S#{opdrecord.read_attribute(:"l_visualacuity_ua_s")}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end
    if opdrecord.l_visualacuity_ua_i.present?
      l_visualacuity_ua_i = "I#{opdrecord.read_attribute(:"l_visualacuity_ua_i")}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end
    if opdrecord.l_visualacuity_ua_n.present?
      l_visualacuity_ua_n = "N#{opdrecord.read_attribute(:"l_visualacuity_ua_n")}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end
    if opdrecord.l_visualacuity_ua_t.present?
      l_visualacuity_ua_t = "T#{opdrecord.read_attribute(:"l_visualacuity_ua_t")}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end

    if opdrecord.read_attribute(:l_visualacuity_pinhole_p).present?
      l_visualacuity_pinhole_p = "(#{opdrecord.read_attribute(:l_visualacuity_pinhole_p)})"
    end
    if opdrecord.read_attribute(:l_visualacuity_pinhole_ni).present?
      l_visualacuity_pinhole_ni = "(#{opdrecord.read_attribute(:l_visualacuity_pinhole_ni)})"
    end
    unless opdrecord.l_visualacuity_pinhole.blank?
      l_visualacuity_pinhole = "PH- #{opdrecord.read_attribute(:"l_visualacuity_pinhole")}#{l_visualacuity_pinhole_p}#{l_visualacuity_pinhole_ni}"
      l_visualacuity_op = "#{l_visualacuity_op} #{l_visualacuity_pinhole}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end
    if opdrecord.read_attribute(:l_visualacuity_glasses_p).present?
      l_visualacuity_glasses_p = "(#{opdrecord.read_attribute(:l_visualacuity_glasses_p)})"
    end
    unless opdrecord.l_visualacuity_glasses.blank?
      l_visualacuity_glasses = "Glasses- #{opdrecord.read_attribute(:"l_visualacuity_glasses")}#{l_visualacuity_glasses_p}"
      l_visualacuity_op = "#{l_visualacuity_op} #{l_visualacuity_glasses}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end
    if opdrecord.read_attribute(:l_visualacuity_near_p).present?
      l_visualacuity_near_p = "(#{opdrecord.read_attribute(:l_visualacuity_near_p)})"
    end
    unless opdrecord.l_visualacuity_near.blank?
      l_visualacuity_near = "Glasses Near- #{opdrecord.read_attribute(:"l_visualacuity_near")}#{l_visualacuity_near_p}"
      l_visualacuity_op = "#{l_visualacuity_op} #{l_visualacuity_near}"
      l_visualacuity_counter = l_visualacuity_counter + 1

    end

    if l_visualacuity_counter > 0
      final_op = "VA:" + l_visualacuity_op
      if l_visualacuity_ua_s || l_visualacuity_ua_i.present? || l_visualacuity_ua_n.present? || l_visualacuity_ua_t.present?
        final_op = final_op + "PR(UA):" + l_visualacuity_ua_s + l_visualacuity_ua_i + l_visualacuity_ua_n + l_visualacuity_ua_t
      end
    end
    final_op
  end
end
