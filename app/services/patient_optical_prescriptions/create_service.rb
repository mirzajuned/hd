module PatientOpticalPrescriptions
  module CreateService
    def self.call(opdrecord)
      appointment = Appointment.find_by(id: opdrecord.appointmentid)
      facility = Facility.find_by(id: appointment.facility_id)

      # if facility.clinical_workflow
      #   workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
      #   consultant_id = User.find_by(:id => workflow.consultant_ids.last)
      # else
      #   consultant_id = User.find_by(:id => appointment.consultant_id.to_s)
      # end
      consultant_id = User.find_by(id: opdrecord.consultant_id)

      optical_prescriptions = PatientOpticalPrescription.where(record_id: BSON::ObjectId(opdrecord.id), patient_id: opdrecord.patientid, :prescription_type.ne => 'intermediate_glasses_prescription')
      optical_prescriptions.try(:each) do |optical_prescription|
        if optical_prescription.try(:dispatched_from_optical) == true
          dispatched_from_optical = optical_prescription.dispatched_from_optical
        end
        # optical_prescription.try(:destroy)
      end

      optical_counter = 0
      unless ['optometrist', 'refraction'].include?(opdrecord.templatetype)
        unless opdrecord.r_glassesprescriptions_distant_sph == "" || opdrecord.r_glassesprescriptions_distant_sph == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_distant_cyl == "" || opdrecord.r_glassesprescriptions_distant_cyl == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_distant_axis == "" || opdrecord.r_glassesprescriptions_distant_axis == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_distant_vision == "" || opdrecord.r_glassesprescriptions_distant_vision == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_near_sph == "" || opdrecord.r_glassesprescriptions_near_sph == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_near_cyl == "" || opdrecord.r_glassesprescriptions_near_cyl == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_near_axis == "" || opdrecord.r_glassesprescriptions_near_axis == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_glassesprescriptions_near_vision == "" || opdrecord.r_glassesprescriptions_near_vision == nil
          optical_counter = optical_counter + 1
        end

        unless opdrecord.l_glassesprescriptions_distant_sph == "" || opdrecord.l_glassesprescriptions_distant_sph == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_distant_cyl == "" || opdrecord.l_glassesprescriptions_distant_cyl == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_distant_axis == "" || opdrecord.l_glassesprescriptions_distant_axis == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_distant_vision == "" || opdrecord.l_glassesprescriptions_distant_vision == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_near_sph == "" || opdrecord.l_glassesprescriptions_near_sph == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_near_cyl == "" || opdrecord.l_glassesprescriptions_near_cyl == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_near_axis == "" || opdrecord.l_glassesprescriptions_near_axis == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_glassesprescriptions_near_vision == "" || opdrecord.l_glassesprescriptions_near_vision == nil
          optical_counter = optical_counter + 1
        end
        

        # Acceptance
        unless opdrecord.r_acceptance_framematerial == "" || opdrecord.r_acceptance_framematerial == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_ipd == "" || opdrecord.r_acceptance_ipd == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_distance_pd == "" || opdrecord.r_acceptance_distance_pd == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_near_pd == "" || opdrecord.r_acceptance_near_pd == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_lensmaterial == "" || opdrecord.r_acceptance_lensmaterial == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_lenstint == "" || opdrecord.r_acceptance_lenstint == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_typeoflens == "" || opdrecord.r_acceptance_typeoflens == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_acceptance_comments == "" || opdrecord.r_acceptance_comments == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.r_dio == "" || opdrecord.r_dio == nil
          optical_counter = optical_counter + 1
        end

        unless opdrecord.l_acceptance_framematerial == "" || opdrecord.l_acceptance_framematerial == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_ipd == "" || opdrecord.l_acceptance_ipd == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_distance_pd == "" || opdrecord.l_acceptance_distance_pd == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_near_pd == "" || opdrecord.l_acceptance_near_pd == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_lensmaterial == "" || opdrecord.l_acceptance_lensmaterial == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_lenstint == "" || opdrecord.l_acceptance_lenstint == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_typeoflens == "" || opdrecord.l_acceptance_typeoflens == nil
          optical_counter = optical_counter + 1
        end
        unless opdrecord.l_acceptance_comments == "" || opdrecord.l_acceptance_comments == nil
          optical_counter = optical_counter + 1
        end 
      end
      if optical_counter > 0
        if optical_prescriptions.count > 0
          patient_prescriptions = PatientOpticalPrescription.where(record_id: BSON::ObjectId(opdrecord.id), :prescription_type.ne => 'intermediate_glasses_prescription', patient_id: opdrecord.patientid)
          eye_optical_prescription = patient_prescriptions.where(templatetype: "eye").order("created_at DESC")[0]
          quickeye_optical_prescription = patient_prescriptions.where(templatetype: "quickeye").order("created_at DESC")[0]
          pmt_optical_prescription = patient_prescriptions.where(templatetype: "pmt").order("created_at DESC")[0]
          postop_optical_prescription = patient_prescriptions.where(templatetype: "postop").order("created_at DESC")[0]
          lens_optical_prescription = patient_prescriptions.where(templatetype: "lens").order("created_at DESC")[0]
          orthoptics_optical_prescription = patient_prescriptions.where(templatetype: "orthoptics").order("created_at DESC")[0]
          paediatrics_optical_prescription = patient_prescriptions.where(templatetype: "paediatrics").order("created_at DESC")[0]
          trauma_optical_prescription = patient_prescriptions.where(templatetype: "trauma").order("created_at DESC")[0]

          options = { user_id: opdrecord.record_histories[0].user_id,
                      r_glassesprescriptions_distant_sph: opdrecord.r_glassesprescriptions_distant_sph,
                      r_glassesprescriptions_distant_cyl: opdrecord.r_glassesprescriptions_distant_cyl,
                      r_glassesprescriptions_distant_axis: opdrecord.r_glassesprescriptions_distant_axis,
                      r_glassesprescriptions_distant_vision: opdrecord.r_glassesprescriptions_distant_vision,
                      r_glassesprescriptions_add_sph: opdrecord.r_glassesprescriptions_add_sph,
                      r_glassesprescriptions_add_cyl: opdrecord.r_glassesprescriptions_add_cyl,
                      r_glassesprescriptions_add_axis: opdrecord.r_glassesprescriptions_add_axis,
                      r_glassesprescriptions_add_vision: opdrecord.r_glassesprescriptions_add_vision,
                      r_glassesprescriptions_near_sph: opdrecord.r_glassesprescriptions_near_sph,
                      r_glassesprescriptions_near_cyl: opdrecord.r_glassesprescriptions_near_cyl,
                      r_glassesprescriptions_near_axis: opdrecord.r_glassesprescriptions_near_axis,
                      r_glassesprescriptions_near_vision: opdrecord.r_glassesprescriptions_near_vision,
                      l_glassesprescriptions_distant_sph: opdrecord.l_glassesprescriptions_distant_sph,
                      l_glassesprescriptions_distant_cyl: opdrecord.l_glassesprescriptions_distant_cyl,
                      l_glassesprescriptions_distant_axis: opdrecord.l_glassesprescriptions_distant_axis,
                      l_glassesprescriptions_distant_vision: opdrecord.l_glassesprescriptions_distant_vision,
                      l_glassesprescriptions_add_sph: opdrecord.l_glassesprescriptions_add_sph,
                      l_glassesprescriptions_add_cyl: opdrecord.l_glassesprescriptions_add_cyl,
                      l_glassesprescriptions_add_axis: opdrecord.l_glassesprescriptions_add_axis,
                      l_glassesprescriptions_add_vision: opdrecord.l_glassesprescriptions_add_vision,
                      l_glassesprescriptions_near_sph: opdrecord.l_glassesprescriptions_near_sph,
                      l_glassesprescriptions_near_cyl: opdrecord.l_glassesprescriptions_near_cyl,
                      l_glassesprescriptions_near_axis: opdrecord.l_glassesprescriptions_near_axis,
                      l_glassesprescriptions_near_vision: opdrecord.l_glassesprescriptions_near_vision,
                      glassesprescriptions_show_add: opdrecord.glassesprescriptions_show_add,
                      r_acceptance_framematerial: opdrecord.r_acceptance_framematerial,
                      r_acceptance_ipd: opdrecord.r_acceptance_ipd,
                      r_acceptance_distance_pd: opdrecord.r_acceptance_distance_pd,
                      r_acceptance_near_pd: opdrecord.r_acceptance_near_pd,
                      r_acceptance_lensmaterial: opdrecord.r_acceptance_lensmaterial,
                      r_acceptance_lenstint: opdrecord.r_acceptance_lenstint,
                      r_acceptance_typeoflens: opdrecord.r_acceptance_typeoflens,
                      l_acceptance_framematerial: opdrecord.l_acceptance_framematerial,
                      l_acceptance_ipd: opdrecord.l_acceptance_ipd,
                      l_acceptance_distance_pd: opdrecord.l_acceptance_distance_pd,
                      l_acceptance_near_pd: opdrecord.l_acceptance_near_pd,
                      l_acceptance_lensmaterial: opdrecord.l_acceptance_lensmaterial,
                      l_acceptance_lenstint: opdrecord.l_acceptance_lenstint,
                      l_acceptance_typeoflens: opdrecord.l_acceptance_typeoflens,
                      advise_glasses: opdrecord.advise_glasses,
                      intermediate_advise_glasses: "",
                      r_acceptance_comments: opdrecord.r_acceptance_comments,
                      l_acceptance_comments: opdrecord.l_acceptance_comments,
                      r_acceptance_dia: opdrecord.r_acceptance_dia,
                      l_acceptance_dia: opdrecord.l_acceptance_dia,
                      l_acceptance_size: opdrecord.l_acceptance_size, 
                      r_acceptance_size: opdrecord.r_acceptance_size,
                      r_acceptance_fittingheight: opdrecord.r_acceptance_fittingheight,
                      l_acceptance_fittingheight: opdrecord.l_acceptance_fittingheight,
                      r_acceptance_prismbase: opdrecord.r_acceptance_prismbase,
                      l_acceptance_prismbase: opdrecord.l_acceptance_prismbase,}
          if eye_optical_prescription
            eye_optical_prescription.update(options)
            patient_optical_prescriptions = eye_optical_prescription
          elsif quickeye_optical_prescription
            quickeye_optical_prescription.update(options)
            patient_optical_prescriptions = quickeye_optical_prescription
          elsif pmt_optical_prescription
            pmt_optical_prescription.update(options)
            patient_optical_prescriptions = pmt_optical_prescription
          elsif postop_optical_prescription
            postop_optical_prescription.update(options)
            patient_optical_prescriptions = postop_optical_prescription
          elsif lens_optical_prescription
            lens_optical_prescription.update(options)
            patient_optical_prescriptions = lens_optical_prescription
          elsif orthoptics_optical_prescription
            orthoptics_optical_prescription.update(options)
            patient_optical_prescriptions = orthoptics_optical_prescription
          elsif paediatrics_optical_prescription
            paediatrics_optical_prescription.update(options)
            patient_optical_prescriptions = paediatrics_optical_prescription
          elsif trauma_optical_prescription
            trauma_optical_prescription.update(options)
            patient_optical_prescriptions = trauma_optical_prescription
          end
          InventoryJobs::PrescriptionDataJob.perform_later('optical', patient_optical_prescriptions&.id.to_s)
        else
          patient = Patient.find(opdrecord.patientid)
          patient_name = (patient.firstname.to_s + " " + patient.middlename.to_s + " " + patient.lastname.to_s).split.join(" ")
          patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
          mobile_number = patient.mobilenumber
          mr_no = patient.patient_mrn
          mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
          reg_hosp_ids = patient.reg_hosp_ids
          patient_identifier_id = patient.patient_identifier_id
          patient_identifier_id_search = patient_identifier_id.to_s.split("").map { |x| x[/\d+/] }.join("")
          search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name} #{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search} #{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search} #{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}".downcase

          patient_optical_prescriptions = PatientOpticalPrescription.new()
          patient_optical_prescriptions['consultant_name'] = consultant_id.fullname
          patient_optical_prescriptions['consultant_id'] = consultant_id.id.to_s
          patient_optical_prescriptions['user_id'] = opdrecord.record_histories[0].user_id
          patient_optical_prescriptions['facility_id'] = appointment.facility_id
          patient_optical_prescriptions['patient_id'] = opdrecord.patientid
          patient_optical_prescriptions['store_name'] = opdrecord.optical_store_name
          patient_optical_prescriptions['store_id'] = opdrecord.optical_store_id
          patient_optical_prescriptions['store_present'] = opdrecord.optical_store_present

          patient_optical_prescriptions['search'] = search
          patient_optical_prescriptions['patient_name'] = patient_name
          patient_optical_prescriptions['mobile_number'] = mobile_number
          patient_optical_prescriptions['patient_identifier_id'] = patient_identifier_id
          patient_optical_prescriptions['mr_no'] = mr_no
          patient_optical_prescriptions['patient_identifier_id_search'] = patient_identifier_id_search
          patient_optical_prescriptions['mr_no_search'] = mr_no_search
          patient_optical_prescriptions['patient_name_search'] = patient_name_search
          patient_optical_prescriptions['reg_hosp_ids'] = reg_hosp_ids

          patient_optical_prescriptions['record_id'] = opdrecord.id
          patient_optical_prescriptions['encountertype'] = opdrecord.encountertype
          patient_optical_prescriptions['encountertypeid'] = opdrecord.encountertypeid
          patient_optical_prescriptions['appointment_id'] = opdrecord.appointmentid
          patient_optical_prescriptions['templatetype'] = opdrecord.templatetype
          patient_optical_prescriptions['templateid'] = opdrecord.templateid
          patient_optical_prescriptions['specalityid'] = opdrecord.specalityid
          patient_optical_prescriptions['specalityname'] = opdrecord.specalityname
          patient_optical_prescriptions['encounterdate'] = opdrecord.created_at
          patient_optical_prescriptions['prescription_date'] = opdrecord.created_at.to_date
          patient_optical_prescriptions['prescription_datetime'] = opdrecord.created_at
          patient_optical_prescriptions['authorid'] = opdrecord.authorid
          if defined? dispatched_from_optical
            patient_optical_prescriptions['dispatched_from_optical'] = dispatched_from_optical
          end

          patient_optical_prescriptions['r_glassesprescriptions_distant_sph'] = opdrecord.r_glassesprescriptions_distant_sph
          patient_optical_prescriptions['r_glassesprescriptions_distant_cyl'] = opdrecord.r_glassesprescriptions_distant_cyl
          patient_optical_prescriptions['r_glassesprescriptions_distant_axis'] = opdrecord.r_glassesprescriptions_distant_axis
          patient_optical_prescriptions['r_glassesprescriptions_distant_vision'] = opdrecord.r_glassesprescriptions_distant_vision

          patient_optical_prescriptions['r_glassesprescriptions_add_sph'] = opdrecord.r_glassesprescriptions_add_sph
          patient_optical_prescriptions['r_glassesprescriptions_add_cyl'] = opdrecord.r_glassesprescriptions_add_cyl
          patient_optical_prescriptions['r_glassesprescriptions_add_axis'] = opdrecord.r_glassesprescriptions_add_axis
          patient_optical_prescriptions['r_glassesprescriptions_add_vision'] = opdrecord.r_glassesprescriptions_add_vision

          patient_optical_prescriptions['r_glassesprescriptions_near_sph'] = opdrecord.r_glassesprescriptions_near_sph
          patient_optical_prescriptions['r_glassesprescriptions_near_cyl'] = opdrecord.r_glassesprescriptions_near_cyl
          patient_optical_prescriptions['r_glassesprescriptions_near_axis'] = opdrecord.r_glassesprescriptions_near_axis
          patient_optical_prescriptions['r_glassesprescriptions_near_vision'] = opdrecord.r_glassesprescriptions_near_vision

          patient_optical_prescriptions['l_glassesprescriptions_distant_sph'] = opdrecord.l_glassesprescriptions_distant_sph
          patient_optical_prescriptions['l_glassesprescriptions_distant_cyl'] = opdrecord.l_glassesprescriptions_distant_cyl
          patient_optical_prescriptions['l_glassesprescriptions_distant_axis'] = opdrecord.l_glassesprescriptions_distant_axis
          patient_optical_prescriptions['l_glassesprescriptions_distant_vision'] = opdrecord.l_glassesprescriptions_distant_vision

          patient_optical_prescriptions['l_glassesprescriptions_add_sph'] = opdrecord.l_glassesprescriptions_add_sph
          patient_optical_prescriptions['l_glassesprescriptions_add_cyl'] = opdrecord.l_glassesprescriptions_add_cyl
          patient_optical_prescriptions['l_glassesprescriptions_add_axis'] = opdrecord.l_glassesprescriptions_add_axis
          patient_optical_prescriptions['l_glassesprescriptions_add_vision'] = opdrecord.l_glassesprescriptions_add_vision

          patient_optical_prescriptions['l_glassesprescriptions_near_sph'] = opdrecord.l_glassesprescriptions_near_sph
          patient_optical_prescriptions['l_glassesprescriptions_near_cyl'] = opdrecord.l_glassesprescriptions_near_cyl
          patient_optical_prescriptions['l_glassesprescriptions_near_axis'] = opdrecord.l_glassesprescriptions_near_axis
          patient_optical_prescriptions['l_glassesprescriptions_near_vision'] = opdrecord.l_glassesprescriptions_near_vision

          patient_optical_prescriptions['glassesprescriptions_show_add'] = opdrecord.glassesprescriptions_show_add
          # Acceptance
          patient_optical_prescriptions['r_acceptance_framematerial'] = opdrecord.r_acceptance_framematerial
          patient_optical_prescriptions['r_acceptance_ipd'] = opdrecord.r_acceptance_ipd
          patient_optical_prescriptions['r_acceptance_distance_pd'] = opdrecord.r_acceptance_distance_pd
          patient_optical_prescriptions['r_acceptance_near_pd'] = opdrecord.r_acceptance_near_pd
          patient_optical_prescriptions['r_acceptance_lensmaterial'] = opdrecord.r_acceptance_lensmaterial
          patient_optical_prescriptions['r_acceptance_lenstint'] = opdrecord.r_acceptance_lenstint
          patient_optical_prescriptions['r_acceptance_typeoflens'] = opdrecord.r_acceptance_typeoflens
          patient_optical_prescriptions['r_acceptance_comments'] = opdrecord.r_acceptance_comments
          patient_optical_prescriptions['r_acceptance_dia'] = opdrecord.r_acceptance_dia
          patient_optical_prescriptions['r_acceptance_size'] = opdrecord.r_acceptance_size
          patient_optical_prescriptions['r_acceptance_fittingheight'] = opdrecord.r_acceptance_fittingheight
          patient_optical_prescriptions['r_acceptance_prismbase'] = opdrecord.r_acceptance_prismbase

          patient_optical_prescriptions['l_acceptance_framematerial'] = opdrecord.l_acceptance_framematerial
          patient_optical_prescriptions['l_acceptance_ipd'] = opdrecord.l_acceptance_ipd
          patient_optical_prescriptions['l_acceptance_distance_pd'] = opdrecord.l_acceptance_distance_pd
          patient_optical_prescriptions['l_acceptance_near_pd'] = opdrecord.l_acceptance_near_pd
          patient_optical_prescriptions['l_acceptance_lensmaterial'] = opdrecord.l_acceptance_lensmaterial
          patient_optical_prescriptions['l_acceptance_lenstint'] = opdrecord.l_acceptance_lenstint
          patient_optical_prescriptions['l_acceptance_typeoflens'] = opdrecord.l_acceptance_typeoflens
          patient_optical_prescriptions['l_acceptance_comments'] = opdrecord.l_acceptance_comments
          patient_optical_prescriptions['l_acceptance_dia'] = opdrecord.l_acceptance_dia
          patient_optical_prescriptions['l_acceptance_size'] = opdrecord.l_acceptance_size
          patient_optical_prescriptions['l_acceptance_fittingheight'] = opdrecord.l_acceptance_fittingheight
          patient_optical_prescriptions['l_acceptance_prismbase'] = opdrecord.l_acceptance_prismbase
          patient_optical_prescriptions['advise_glasses'] = opdrecord.advise_glasses
          patient_optical_prescriptions['intermediate_advise_glasses'] = ""
          patient_optical_prescriptions['templatetype'] = opdrecord.templatetype
          organisation = consultant_id.organisation
          # puts '0000000000'
          # puts organisation.optical_prescription_counter
          sequence_id = organisation.optical_prescription_counter.to_i + 1
          # puts '1111111'
          # puts sequence_id
          display_id = "#{organisation.identifier_prefix}-INV-#{sequence_id}"
          patient_optical_prescriptions['display_id'] = display_id
          organisation.update_attributes(optical_prescription_counter: sequence_id.to_i)
          # puts '22222222'
          # puts organisation.optical_prescription_counter
          patient_optical_prescriptions.save()
          Analytics::Conversion::OpticalPrescriptionJob.perform_later(patient_optical_prescriptions.id.to_s, consultant_id.id.to_s, "Clinical")
          InventoryJobs::PrescriptionDataJob.perform_later('optical', patient_optical_prescriptions&.id.to_s)
        end
      else
        if optical_prescriptions.count > 0
          Inventory::StoreConversion.where(:prescription_id.in => optical_prescriptions.pluck(:id)).destroy_all
          optical_prescriptions.delete_all
        end
      end
    end
  end
end
