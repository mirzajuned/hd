module PatientIntermediateOpticalPrescriptions
  module CreateService
    def self.call(opd_record)
      prescriptions = PatientOpticalPrescription.where(record_id: BSON::ObjectId(opd_record.id), patient_id: opd_record.patientid, prescription_type: 'intermediate_glasses_prescription')

      optical_counter = 0
      unless ['optometrist', 'refraction'].include?(opd_record.try(:templatetype))
        optical_hash = {}
        main_values = get_prescription_keys

        ['r', 'l'].each do |side|
          main_values.each_with_index do |key, i|
            final_key = "#{side}_#{key}"
            value = opd_record.read_attribute("#{final_key}")

            optical_hash[final_key] = value

            optical_counter += 1 if value.present? && !final_key.include?('_add_')
          end
        end
        # set extra fields
        optical_hash[:user_id] = opd_record.record_histories[0].user_id
        optical_hash[:advise_glasses] = ""
        optical_hash[:intermediate_advise_glasses] = opd_record.intermediate_advise_glasses
        optical_hash[:intermediate_glasses_prescriptions_show_add] = opd_record.intermediate_glasses_prescriptions_show_add
      end
      if optical_counter > 0
        if prescriptions.count > 0
          prescriptions.update_all(optical_hash) if prescriptions
        else
          record = create_new_prescription(opd_record, optical_hash)
        end
      else
        prescriptions.delete_all if prescriptions.count > 0
      end
    end

    def self.get_prescription_keys
      main_values = ["intermediate_acceptance_comments", "intermediate_glasses_prescriptions_distant_axis", "intermediate_glasses_prescriptions_distant_cyl", "intermediate_glasses_prescriptions_distant_sph", "intermediate_glasses_prescriptions_distant_vision", "intermediate_glasses_prescriptions_near_axis", "intermediate_glasses_prescriptions_near_cyl", "intermediate_glasses_prescriptions_near_sph", "intermediate_glasses_prescriptions_near_vision", "intermediate_glasses_prescriptions_add_axis", "intermediate_glasses_prescriptions_add_cyl", "intermediate_glasses_prescriptions_add_sph", "intermediate_glasses_prescriptions_add_vision"] + ["intermediate_acceptance_framematerial", "intermediate_acceptance_ipd", "intermediate_acceptance_lensmaterial", "intermediate_acceptance_lenstint", "intermediate_acceptance_typeoflens"]

      return main_values
    end

    # def self.get_acceptance_keys
    #   main_values = ["intermediate_acceptance_framematerial", "intermediate_acceptance_ipd", "intermediate_acceptance_lensmaterial", "intermediate_acceptance_lenstint", "intermediate_acceptance_typeoflens"]

    #   titles = ["Frame Material- ", "IPD - ", "Lens Material- ", "Lens Tint- ", "Type of Lens - "]

    #   return main_values, titles
    # end

    def self.create_new_prescription(opd_record, optical_hash)
      patient = Patient.find_by(id: opd_record.patientid)
      patient_name = (patient.firstname.to_s + " " + patient.middlename.to_s + " " + patient.lastname.to_s).split.join(" ")
      patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
      mobile_number = patient.mobilenumber
      mr_no = patient.patient_mrn
      mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
      reg_hosp_ids = patient.reg_hosp_ids
      patient_identifier_id = patient.patient_identifier_id
      patient_identifier_id_search = patient_identifier_id.to_s.split("").map { |x| x[/\d+/] }.join("")
      search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name} #{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search} #{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search} #{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}".downcase
      # doctor = User.find_by(id: opd_record.authorid)
      doctor = User.find_by(id: opd_record.consultant_id)

      optical_hash[:consultant_name] = doctor.fullname
      optical_hash[:consultant_id] = doctor.id.to_s
      optical_hash[:facility_id] = opd_record.facility_id
      optical_hash[:patient_id] = opd_record.patientid

      optical_hash[:search] = search
      optical_hash[:patient_name] = patient_name
      optical_hash[:mobile_number] = mobile_number
      optical_hash[:patient_identifier_id] = patient_identifier_id
      optical_hash[:mr_no] = mr_no
      optical_hash[:patient_identifier_id_search] = patient_identifier_id_search
      optical_hash[:mr_no_search] = mr_no_search
      optical_hash[:patient_name_search] = patient_name_search
      optical_hash[:reg_hosp_ids] = reg_hosp_ids
      
      optical_hash[:store_name] = opd_record.optical_store_name
      optical_hash[:store_id] = opd_record.optical_store_id
      optical_hash[:store_present] = opd_record.optical_store_present

      optical_hash[:record_id] = opd_record.id
      optical_hash[:encountertype] = opd_record.encountertype
      optical_hash[:encountertypeid] = opd_record.encountertypeid
      optical_hash[:appointment_id] = opd_record.appointmentid
      optical_hash[:templatetype] = opd_record.templatetype
      optical_hash[:templateid] = opd_record.templateid
      optical_hash[:specalityid] = opd_record.specalityid
      optical_hash[:specalityname] = opd_record.specalityname
      optical_hash[:encounterdate] = opd_record.created_at
      optical_hash[:authorid] = opd_record.authorid

      optical_hash[:prescription_type] = 'intermediate_glasses_prescription'
      optical_hash[:dispatched_from_optical] = false

      optical_hash[:prescription_date] = opd_record.created_at.to_date
      optical_hash[:prescription_datetime] = opd_record.created_at

      organisation = doctor.organisation
      sequence_id = organisation.optical_prescription_counter.to_i + 1

      display_id = "#{organisation.identifier_prefix}-INV-#{sequence_id}"
      optical_hash[:display_id] = display_id
      organisation.inc(optical_prescription_counter: 1)

      prescription = PatientOpticalPrescription.new(optical_hash)
      prescription.save!

      InventoryJobs::PrescriptionDataJob.perform_later('optical', prescription.id.to_s)

      return prescription
    end
  end
end
