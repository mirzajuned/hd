class OpdRecordWorkerBkp
  attr_accessor :record_id
  def initialize(id)
    @record_id = id
  end

  def call
    opdrecord = OpdRecord.find_by(:id => "#{record_id}")
    # opdrecord.appointmentid
    appointment = Appointment.find_by(:id => opdrecord.appointmentid)

    facility = Facility.find_by(:id => appointment.facility_id)

    org_id = facility.organisation_id
    if facility.clinical_workflow
      workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
      doctor = User.find_by(:id => workflow.doctor_ids.last)
    else
      doctor = User.find_by(:id => appointment.doctor.to_s)
    end

    username = User.find(opdrecord.record_histories[0].user_id).try(:fullname)
    # patient = Patient.find(appointment.patient_id.to_s)
    # opdrecord.update_attributes(:patientname => patient.fullname)

    PatientTimeline.where(record_id: opdrecord.id, patient_id: opdrecord.patientid).try(:destroy_all)
    pharmacy_prescription = PatientPrescription.where(record_id: opdrecord.id).order("created_at DESC")[0]
    PatientManagementFollowup.where(record_id: opdrecord.id, patient_id: opdrecord.patientid).try(:destroy_all)
    PatientOphthalAssessment.where(record_id: opdrecord.id, patient_id: opdrecord.patientid.to_s).try(:destroy)
    PatientRadiologyAssessment.where(record_id: opdrecord.id, patient_id: opdrecord.patientid.to_s).try(:destroy)
    optical_prescriptions = PatientOpticalPrescription.where(record_id: BSON::ObjectId(opdrecord.id), patient_id: opdrecord.patientid)
    optical_prescriptions.try(:each) do |optical_prescription|
      if optical_prescription.try(:dispatched_from_optical) == true
        dispatched_from_optical = optical_prescription.dispatched_from_optical
      end
      # optical_prescription.try(:destroy)
    end

    patient_timeline = PatientTimeline.new()
    patient_timeline['doctor_name'] = doctor.fullname
    patient_timeline['doctor'] = appointment.doctor.to_s
    patient_timeline['user_id'] = opdrecord.record_histories[0].user_id
    patient_timeline['user_name'] = username
    patient_timeline['facility_id'] = appointment.facility_id
    patient_timeline['facility_name'] = facility.name
    patient_timeline['patient_id'] = opdrecord.patientid
    patient_timeline['record_id'] = opdrecord.id
    patient_timeline['encountertype'] = opdrecord.encountertype
    patient_timeline['encountertypeid'] = opdrecord.encountertypeid
    patient_timeline['appointment_id'] = opdrecord.appointmentid
    patient_timeline['templatetype'] = opdrecord.templatetype
    patient_timeline['templateid'] = opdrecord.templateid
    patient_timeline['specalityid'] = opdrecord.specalityid
    patient_timeline['specalityname'] = opdrecord.specalityname
    patient_timeline['encounterdate'] = opdrecord.created_at
    patient_timeline['authorid'] = opdrecord.authorid
    patient_timeline.save()

    if (opdrecord.has_intra_facility_referral?)
      intra_facility_referral_data = opdrecord.intra_facility_referral
      intra_facility_referral_data.each_with_index do |referral, i|
        if referral[:bookreferredappointment] == true
          @referralappointment = Appointment.find_by(:intra_referral_id => referral.id)
          if @referralappointment.present?
            @referralappointment.update(:referral_created_on => Time.current, :appointmentdate => referral[:referraldate], :start_time => referral[:referraltime], :end_time => referral[:referraltime] + 10.minutes, :facility_id => referral[:facility_id], :appointment_type_id => referral[:referral_appointment_type_id], :doctor => referral[:to_user], :appointmentstatus => 416774000)
            Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "RESCHEDULED", appointment_id: @referralappointment.id.to_s, user_id: opdrecord.record_histories[0].user_id.to_s, user_name: User.find_by(id: opdrecord.record_histories[0].user_id).try(:fullname), workflow: Facility.find_by(id: @referralappointment.facility_id).clinical_workflow })
          else
            ref = intra_facility_referral_data.find_by(id: referral.id)
            referring_doctor = User.find_by(id: ref.from_user).fullname
            referee_doctor = User.find_by(id: ref.to_user).fullname
            referral_note = ref.referralnote
            @user = User.find(referral[:to_user])
            new_appointment = Appointment.new(:referral_created_on => Time.current, :appointmentdate => referral[:referraldate], :start_time => referral[:referraltime], :patient_id => opdrecord.patientid, :appointment_type_id => referral[:referral_appointment_type_id], :doctor => referral[:to_user], :user_id => opdrecord.userid, :facility_id => referral[:facility_id], :department_id => @user.department_id.to_s, :departmenttype => opdrecord.encountertypeid, :appointmentstatus => 416774000, :display_id => CommonHelper::get_opd_record_identifier(@user), :intra_referral_id => referral.id, :referral => true, :referral_type => "intra_facility", :referral_opd_record => opdrecord.id, end_time: referral[:referraltime] + 10.minutes, referring_doctor: referring_doctor, referee_doctor: referee_doctor, referral_note: referral_note)
            if new_appointment.save
              # new_appointment.update(end_time: new_appointment.start_time + 10.minutes)
              @referralappointment_id = new_appointment.id
              @temp_appointment = new_appointment
              Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: new_appointment.id.to_s, user_id: opdrecord.record_histories[0].user_id.to_s, user_name: User.find_by(id: opdrecord.record_histories[0].user_id).try(:fullname), workflow: Facility.find_by(id: referral[:facility_id]).clinical_workflow })
            else
              @referralappointment_id = ""
            end
          end
        else
          @referralappointment = Appointment.find_by(:intra_referral_id => referral.id)
          if @referralappointment.present?
            @referralappointment.update(appointmentstatus: 89925002)
          end
        end
      end
    end

    if (opdrecord.has_inter_facility_referral?)
      inter_facility_referral_data = opdrecord.inter_facility_referral
      inter_facility_referral_data.each_with_index do |referral, i|
        @patient = Patient.find(opdrecord.patientid)

        @referral_date_time = referral.referraldate

        @referred_to_facility_id = referral[:to_facility]
        @referred_to_facility_name = Facility.find(referral[:to_facility]).name

        @referred_from_facility_id = referral[:from_facility]
        @referred_from_facility_name = Facility.find(referral[:from_facility]).name

        @referred_to_doctor = referral[:to_user]
        @referred_to_doctor_name = User.find(referral[:to_user]).fullname

        @referred_from_doctor = referral[:from_user]
        @referred_from_doctor_name = User.find(referral[:from_user]).fullname

        @opdreferral = OpdReferral.find_by(:inter_facility_referral_id => referral.id)
        if @opdreferral.present?
          @opdreferral.update(:referral_date => @referral_date_time, :created_on => @referral_date_time, :to_facility => @referred_to_facility_id, :to_facility_name => @referred_to_facility_name, :from_facility => @referred_from_facility_id, :from_facility_name => @referred_from_facility_name, :to_doctor => @referred_to_doctor, :to_doctor_name => @referred_to_doctor_name, :from_doctor => @referred_from_doctor, :from_doctor_name => @referred_from_doctor_name, :referring_note => referral[:referralnote], is_deleted: false)
        else
          new_opd_referral = OpdReferral.new(:referral_date => @referral_date_time, :created_on => Time.current, :patient_id => @patient.id, patient_name: @patient.fullname, :to_facility => @referred_to_facility_id, :to_facility_name => @referred_to_facility_name, :from_facility => @referred_from_facility_id, :from_facility_name => @referred_from_facility_name, :to_doctor => @referred_to_doctor, :to_doctor_name => @referred_to_doctor_name, :from_doctor => @referred_from_doctor, :from_doctor_name => @referred_from_doctor_name, :referring_note => referral[:referralnote], :inter_facility_referral_id => referral.id)
          new_opd_referral.save
        end
      end
    end

    if (opdrecord.has_treatmentmedication?)
      if pharmacy_prescription
        prescription_data = opdrecord.treatmentmedication
        medications = []
        prescription_data.each_with_index do |medication, i|
          medications[i.to_i] = Hash["position" => "#{i.to_i + 1}",
                                     "medicinename" => "#{medication.medicinename}",
                                     "medicinequantity" => "#{medication.medicinequantity}",
                                     "medicinefrequency" => "#{medication.medicinefrequency}",
                                     "medicinetype" => "#{medication.medicinetype}",
                                     "medicinedurationoption" => "#{medication.medicinedurationoption}",
                                     "medicineduration" => "#{medication.medicineduration}",
                                     "eyeside" => "#{medication.eyeside}",
                                     "prescriptiondate" => "#{opdrecord.created_at}",
                                     "medicineinstructions" => "#{medication.medicineinstructions}",
                                     "pharmacy_item_id" => "#{medication.pharmacy_item_id || BSON::ObjectId.new}"]
        end
        pharmacy_prescription.update(medications: medications)
      else
        prescription_data = opdrecord.treatmentmedication
        patient_prescriptions = PatientPrescription.new()
        patient_prescriptions['consultant_name'] = doctor.fullname
        patient_prescriptions['consultant_id'] = appointment.doctor.to_s
        patient_prescriptions['user_id'] = appointment.doctor.to_s
        patient_prescriptions['facility_id'] = appointment.facility_id
        patient_prescriptions['patient_id'] = opdrecord.patientid
        patient_prescriptions['patient_name'] = Patient.find(opdrecord.patientid).fullname
        patient_prescriptions['record_id'] = opdrecord.id
        patient_prescriptions['encountertype'] = opdrecord.encountertype
        patient_prescriptions['encountertypeid'] = opdrecord.encountertypeid
        patient_prescriptions['appointment_id'] = opdrecord.appointmentid
        patient_prescriptions['templatetype'] = opdrecord.templatetype
        patient_prescriptions['templateid'] = opdrecord.templateid
        patient_prescriptions['specalityid'] = opdrecord.specalityid
        patient_prescriptions['specalityname'] = opdrecord.specalityname
        patient_prescriptions['encounterdate'] = opdrecord.created_at
        patient_prescriptions['authorid'] = opdrecord.authorid
        prescription_data.each_with_index do |medication, i|
          patient_prescriptions['medications'][i.to_i] = Hash["position" => "#{i.to_i + 1}",
                                                              "medicinename" => "#{medication.medicinename}",
                                                              "medicinequantity" => "#{medication.medicinequantity}",
                                                              "medicinefrequency" => "#{medication.medicinefrequency}",
                                                              "medicinetype" => "#{medication.medicinetype}",
                                                              "medicinedurationoption" => "#{medication.medicinedurationoption}",
                                                              "medicineduration" => "#{medication.medicineduration}",
                                                              "eyeside" => "#{medication.eyeside}",
                                                              "prescriptiondate" => "#{opdrecord.created_at}",
                                                              "medicineinstructions" => "#{medication.medicineinstructions}",
                                                              "pharmacy_item_id" => "#{medication.pharmacy_item_id || BSON::ObjectId.new}", "taper_id" => "#{medication.taper_id}"]
        end
        patient_prescriptions['prescription_date'] = Date.current
        patient_prescriptions['prescription_datetime'] = Time.current
        patient_prescriptions.save()
        InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', patient_prescriptions.id.to_s)
      end
    end

    # optical glasses prescription for optical purpose
    optical_counter = 0
    unless opdrecord.templatetype == "optometrist"
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
      unless opdrecord.r_acceptance_lensmaterial == "" || opdrecord.r_acceptance_lensmaterial == nil
        optical_counter = optical_counter + 1
      end
      unless opdrecord.r_acceptance_lenstint == "" || opdrecord.r_acceptance_lenstint == nil
        optical_counter = optical_counter + 1
      end
      unless opdrecord.r_acceptance_typeoflens == "" || opdrecord.r_acceptance_typeoflens == nil
        optical_counter = optical_counter + 1
      end

      unless opdrecord.l_acceptance_framematerial == "" || opdrecord.l_acceptance_framematerial == nil
        optical_counter = optical_counter + 1
      end
      unless opdrecord.l_acceptance_ipd == "" || opdrecord.l_acceptance_ipd == nil
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
    end

    if optical_counter > 0
      if optical_prescriptions.count > 0
        eye_optical_prescription = PatientOpticalPrescription.where(record_id: BSON::ObjectId(opdrecord.id), templatetype: "eye", patient_id: opdrecord.patientid).order("created_at DESC")[0]
        quickeye_optical_prescription = PatientOpticalPrescription.where(record_id: BSON::ObjectId(opdrecord.id), templatetype: "quickeye", patient_id: opdrecord.patientid).order("created_at DESC")[0]

        if eye_optical_prescription
          eye_optical_prescription.update(user_id: opdrecord.record_histories[0].user_id, r_glassesprescriptions_distant_sph: opdrecord.r_glassesprescriptions_distant_sph, r_glassesprescriptions_distant_cyl: opdrecord.r_glassesprescriptions_distant_cyl, r_glassesprescriptions_distant_axis: opdrecord.r_glassesprescriptions_distant_axis, r_glassesprescriptions_distant_vision: opdrecord.r_glassesprescriptions_distant_vision, r_glassesprescriptions_near_sph: opdrecord.r_glassesprescriptions_near_sph, r_glassesprescriptions_near_cyl: opdrecord.r_glassesprescriptions_distant_cyl, r_glassesprescriptions_near_vision: opdrecord.r_glassesprescriptions_near_vision, l_glassesprescriptions_distant_sph: opdrecord.l_glassesprescriptions_distant_sph, l_glassesprescriptions_distant_cyl: opdrecord.l_glassesprescriptions_distant_cyl, l_glassesprescriptions_distant_axis: opdrecord.l_glassesprescriptions_distant_axis, l_glassesprescriptions_distant_vision: opdrecord.l_glassesprescriptions_distant_vision, l_glassesprescriptions_near_sph: opdrecord.l_glassesprescriptions_near_sph, l_glassesprescriptions_near_cyl: opdrecord.l_glassesprescriptions_distant_cyl, l_glassesprescriptions_near_vision: opdrecord.l_glassesprescriptions_near_vision, r_acceptance_framematerial: opdrecord.r_acceptance_framematerial, r_acceptance_ipd: opdrecord.r_acceptance_ipd, r_acceptance_lensmaterial: opdrecord.r_acceptance_lensmaterial, r_acceptance_lenstint: opdrecord.r_acceptance_lenstint, r_acceptance_typeoflens: opdrecord.r_acceptance_typeoflens, l_acceptance_framematerial: opdrecord.l_acceptance_framematerial, l_acceptance_ipd: opdrecord.l_acceptance_ipd, l_acceptance_lensmaterial: opdrecord.l_acceptance_lensmaterial, l_acceptance_lenstint: opdrecord.l_acceptance_lenstint, l_acceptance_typeoflens: opdrecord.l_acceptance_typeoflens, advise_glasses: opdrecord.advise_glasses)
        elsif quickeye_optical_prescription
          quickeye_optical_prescription.update(user_id: opdrecord.record_histories[0].user_id, r_glassesprescriptions_distant_sph: opdrecord.r_glassesprescriptions_distant_sph, r_glassesprescriptions_distant_cyl: opdrecord.r_glassesprescriptions_distant_cyl, r_glassesprescriptions_distant_axis: opdrecord.r_glassesprescriptions_distant_axis, r_glassesprescriptions_distant_vision: opdrecord.r_glassesprescriptions_distant_vision, r_glassesprescriptions_near_sph: opdrecord.r_glassesprescriptions_near_sph, r_glassesprescriptions_near_cyl: opdrecord.r_glassesprescriptions_distant_cyl, r_glassesprescriptions_near_vision: opdrecord.r_glassesprescriptions_near_vision, l_glassesprescriptions_distant_sph: opdrecord.l_glassesprescriptions_distant_sph, l_glassesprescriptions_distant_cyl: opdrecord.l_glassesprescriptions_distant_cyl, l_glassesprescriptions_distant_axis: opdrecord.l_glassesprescriptions_distant_axis, l_glassesprescriptions_distant_vision: opdrecord.l_glassesprescriptions_distant_vision, l_glassesprescriptions_near_sph: opdrecord.l_glassesprescriptions_near_sph, l_glassesprescriptions_near_cyl: opdrecord.l_glassesprescriptions_distant_cyl, l_glassesprescriptions_near_vision: opdrecord.l_glassesprescriptions_near_vision, r_acceptance_framematerial: opdrecord.r_acceptance_framematerial, r_acceptance_ipd: opdrecord.r_acceptance_ipd, r_acceptance_lensmaterial: opdrecord.r_acceptance_lensmaterial, r_acceptance_lenstint: opdrecord.r_acceptance_lenstint, r_acceptance_typeoflens: opdrecord.r_acceptance_typeoflens, l_acceptance_framematerial: opdrecord.l_acceptance_framematerial, l_acceptance_ipd: opdrecord.l_acceptance_ipd, l_acceptance_lensmaterial: opdrecord.l_acceptance_lensmaterial, l_acceptance_lenstint: opdrecord.l_acceptance_lenstint, l_acceptance_typeoflens: opdrecord.l_acceptance_typeoflens, advise_glasses: opdrecord.advise_glasses)
        end
      else
        patient_optical_prescriptions = PatientOpticalPrescription.new()
        patient_optical_prescriptions['consultant_name'] = doctor.fullname
        patient_optical_prescriptions['consultant_id'] = appointment.doctor.to_s
        patient_optical_prescriptions['user_id'] = opdrecord.record_histories[0].user_id
        patient_optical_prescriptions['facility_id'] = appointment.facility_id
        patient_optical_prescriptions['patient_id'] = opdrecord.patientid
        patient_optical_prescriptions['patient_name'] = Patient.find(opdrecord.patientid).fullname
        patient_optical_prescriptions['record_id'] = opdrecord.id
        patient_optical_prescriptions['encountertype'] = opdrecord.encountertype
        patient_optical_prescriptions['encountertypeid'] = opdrecord.encountertypeid
        patient_optical_prescriptions['appointment_id'] = opdrecord.appointmentid
        patient_optical_prescriptions['templatetype'] = opdrecord.templatetype
        patient_optical_prescriptions['templateid'] = opdrecord.templateid
        patient_optical_prescriptions['specalityid'] = opdrecord.specalityid
        patient_optical_prescriptions['specalityname'] = opdrecord.specalityname
        patient_optical_prescriptions['encounterdate'] = opdrecord.created_at
        patient_optical_prescriptions['authorid'] = opdrecord.authorid
        
        patient_optical_prescriptions['store_name'] = opdrecord.optical_store_name
        patient_optical_prescriptions['store_id'] = opdrecord.optical_store_id
        patient_optical_prescriptions['store_present'] = opdrecord.optical_store_present

        patient_optical_prescriptions['prescription_date'] = opdrecord.created_at.to_date
        patient_optical_prescriptions['prescription_datetime'] = opdrecord.created_at
        if defined? dispatched_from_optical
          patient_optical_prescriptions['dispatched_from_optical'] = dispatched_from_optical
        end

        patient_optical_prescriptions['r_glassesprescriptions_distant_sph'] = opdrecord.r_glassesprescriptions_distant_sph
        patient_optical_prescriptions['r_glassesprescriptions_distant_cyl'] = opdrecord.r_glassesprescriptions_distant_cyl
        patient_optical_prescriptions['r_glassesprescriptions_distant_axis'] = opdrecord.r_glassesprescriptions_distant_axis
        patient_optical_prescriptions['r_glassesprescriptions_distant_vision'] = opdrecord.r_glassesprescriptions_distant_vision

        patient_optical_prescriptions['r_glassesprescriptions_near_sph'] = opdrecord.r_glassesprescriptions_near_sph
        patient_optical_prescriptions['r_glassesprescriptions_near_cyl'] = opdrecord.r_glassesprescriptions_near_cyl
        patient_optical_prescriptions['r_glassesprescriptions_near_axis'] = opdrecord.r_glassesprescriptions_near_axis
        patient_optical_prescriptions['r_glassesprescriptions_near_vision'] = opdrecord.r_glassesprescriptions_near_vision

        patient_optical_prescriptions['l_glassesprescriptions_distant_sph'] = opdrecord.l_glassesprescriptions_distant_sph
        patient_optical_prescriptions['l_glassesprescriptions_distant_cyl'] = opdrecord.l_glassesprescriptions_distant_cyl
        patient_optical_prescriptions['l_glassesprescriptions_distant_axis'] = opdrecord.l_glassesprescriptions_distant_axis
        patient_optical_prescriptions['l_glassesprescriptions_distant_vision'] = opdrecord.l_glassesprescriptions_distant_vision

        patient_optical_prescriptions['l_glassesprescriptions_near_sph'] = opdrecord.l_glassesprescriptions_near_sph
        patient_optical_prescriptions['l_glassesprescriptions_near_cyl'] = opdrecord.l_glassesprescriptions_near_cyl
        patient_optical_prescriptions['l_glassesprescriptions_near_axis'] = opdrecord.l_glassesprescriptions_near_axis
        patient_optical_prescriptions['l_glassesprescriptions_near_vision'] = opdrecord.l_glassesprescriptions_near_vision

        # Acceptance
        patient_optical_prescriptions['r_acceptance_framematerial'] = opdrecord.r_acceptance_framematerial
        patient_optical_prescriptions['r_acceptance_ipd'] = opdrecord.r_acceptance_ipd
        patient_optical_prescriptions['r_acceptance_lensmaterial'] = opdrecord.r_acceptance_lensmaterial
        patient_optical_prescriptions['r_acceptance_lenstint'] = opdrecord.r_acceptance_lenstint
        patient_optical_prescriptions['r_acceptance_typeoflens'] = opdrecord.r_acceptance_typeoflens

        patient_optical_prescriptions['l_acceptance_framematerial'] = opdrecord.l_acceptance_framematerial
        patient_optical_prescriptions['l_acceptance_ipd'] = opdrecord.l_acceptance_ipd
        patient_optical_prescriptions['l_acceptance_lensmaterial'] = opdrecord.l_acceptance_lensmaterial
        patient_optical_prescriptions['l_acceptance_lenstint'] = opdrecord.l_acceptance_lenstint
        patient_optical_prescriptions['l_acceptance_typeoflens'] = opdrecord.l_acceptance_typeoflens
        patient_optical_prescriptions['advise_glasses'] = opdrecord.advise_glasses

        organisation = doctor.organisation
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
        InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', patient_optical_prescriptions.id.to_s)
      end
    end

    if (opdrecord.has_advice?)
      advice_data = opdrecord.has_advice?
      if !opdrecord.advice.opdfollowuptimeframe.blank?
        patient_advice = PatientManagementFollowup.new()
        patient_advice['doctor_name'] = doctor.fullname
        patient_advice['doctor'] = appointment.doctor.to_s
        patient_advice['user_id'] = appointment.doctor.to_s
        patient_advice['facility_id'] = appointment.facility_id
        patient_advice['patient_id'] = opdrecord.patientid
        patient_advice['record_id'] = opdrecord.id
        patient_advice['specalityid'] = opdrecord.specalityid
        patient_advice['specalityname'] = opdrecord.specalityname
        patient_advice['encounter_type'] = opdrecord.encountertype
        patient_advice['encountertypeid'] = opdrecord.encountertypeid
        patient_advice['encounter_date'] = opdrecord.created_at
        patient_advice['followup_advice'] = OpdRecordsHelper.get_label_for_opd_followup_timeframe(opdrecord.advice.opdfollowuptimeframe)
        followup_timeframe = OpdRecordsHelper.get_label_for_opd_followup_timeframe(opdrecord.advice.opdfollowuptimeframe).split(" ")
        patient_advice['followup_date'] = Date.current + followup_timeframe[0].to_i.send(followup_timeframe[1].downcase)
        patient_advice['organisation_id'] = org_id
        patient_advice.save()
      end
    end

    if (opdrecord.has_ophthalinvestigationlist? || opdrecord.has_addedlaboratoryinvestigationlist? || opdrecord.has_investigationlist?)
      if opdrecord.has_ophthalinvestigationlist?

        patient_ophthal_investigation_data = opdrecord.ophthalinvestigationlist
        patient_investigation_opthal = PatientOphthalAssessment.new
        patient_investigation_opthal['doctor_name'] = doctor.fullname
        patient_investigation_opthal['doctor'] = doctor.id
        patient_investigation_opthal['user_id'] = appointment.doctor.to_s
        patient_investigation_opthal['patient_id'] = opdrecord.patientid
        patient_investigation_opthal['templatetype'] = opdrecord.templatetype
        patient_investigation_opthal['facility_id'] = appointment.facility_id
        patient_investigation_opthal['record_id'] = opdrecord.id
        patient_investigation_opthal['specalityid'] = opdrecord.specalityid
        patient_investigation_opthal['specalityname'] = opdrecord.specalityname
        patient_investigation_opthal['encounter_date'] = opdrecord.created_at
        patient_investigation_opthal['encountertype'] = opdrecord.encountertype
        patient_investigation_opthal['appointment_id'] = appointment.id.to_s

        existing_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)

      end
      if opdrecord.has_investigationlist?
        patient_radiology_investigation_data = opdrecord.investigationlist
        patient_investigation_radio = PatientRadiologyAssessment.new
        patient_investigation_radio['doctor_name'] = doctor.fullname
        patient_investigation_radio['doctor'] = appointment.doctor.to_s
        patient_investigation_radio['user_id'] = appointment.doctor.to_s
        patient_investigation_radio['patient_id'] = opdrecord.patientid
        patient_investigation_radio['templatetype'] = opdrecord.templatetype
        patient_investigation_radio['facility_id'] = appointment.facility_id
        patient_investigation_radio['record_id'] = opdrecord.id
        patient_investigation_radio['specalityid'] = opdrecord.specalityid
        patient_investigation_radio['specalityname'] = opdrecord.specalityname
        patient_investigation_radio['encounter_date'] = opdrecord.created_at
        patient_investigation_radio['encountertype'] = opdrecord.encountertype
        patient_investigation_radio['appointment_id'] = appointment.id.to_s
      end
      if opdrecord.has_addedlaboratoryinvestigationlist?
        patient_laboratory_investigation_data = opdrecord.addedlaboratoryinvestigationlist
      end

      patient_investigation = PatientInvestigation.new
      patient_investigation['doctor_name'] = doctor.fullname
      patient_investigation['doctor'] = appointment.doctor.to_s
      patient_investigation['user_id'] = appointment.doctor.to_s
      patient_investigation['patient_id'] = opdrecord.patientid
      patient_investigation['templatetype'] = opdrecord.templatetype
      patient_investigation['facility_id'] = appointment.facility_id
      patient_investigation['record_id'] = opdrecord.id
      patient_investigation['specalityid'] = opdrecord.specalityid
      patient_investigation['specalityname'] = opdrecord.specalityname
      patient_investigation['encounter_date'] = opdrecord.created_at
      # patient_investigation['investigation_type'] = 'Ophthalmology'
      patient_investigation['encountertype'] = opdrecord.encountertype
      if opdrecord.has_ophthalinvestigationlist?
        patient_ophthal_investigation_data.each_with_index do |ophthal_investigation, i|
          # puts ophthal_investigation.investigationname
          patient_investigation_opthal['ophthal_investigations'][i.to_i] = Hash["position" => "#{i.to_i + 1}",
                                                                                "investigationname" => "#{ophthal_investigation.investigationname}",
                                                                                "investigation_id" => "#{ophthal_investigation.investigation_id}",
                                                                                "investigationside" => "#{ophthal_investigation.investigationside}",
                                                                                "investigationadviseddate" => "#{ophthal_investigation.investigationadviseddate}",
                                                                                "investigationfullcode" => "#{ophthal_investigation.investigationfullcode}",
                                                                                "findings" => "",
                                                                                "record_id" => opdrecord.id,
                                                                                "asset_path" => Array.new,
                                                                                "report_id" => Array.new,
                                                                                "counselling" => false]
        end
      end
      if opdrecord.has_addedlaboratoryinvestigationlist?
        patient_laboratory_investigation_data.each_with_index do |lab_investigation, i|
          patient_investigation['laboratory_investigations'][i.to_i] = Hash["position" => "#{i.to_i + 1}",
                                                                            "investigationname" => "#{lab_investigation.investigationname}",
                                                                            "loinc_code" => "#{lab_investigation.loinc_code}",
                                                                            "investigation_id" => "#{lab_investigation.investigation_id}",
                                                                            "loinc_class" => "#{lab_investigation.loinc_class}",
                                                                            "investigationadviseddate" => "#{lab_investigation.investigationadviseddate}",
                                                                            "investigationfullcode" => "#{lab_investigation.investigationfullcode}",
                                                                            "findings" => "",
                                                                            "record_id" => opdrecord.id,
                                                                            "asset_path" => Array.new,
                                                                            "report_id" => Array.new]
        end
      end
      if opdrecord.has_investigationlist?
        patient_radiology_investigation_data.each_with_index do |radio_investigation, i|
          patient_investigation_radio['radiology_investigations'][i.to_i] = Hash["position" => "#{i.to_i + 1}",
                                                                                 "investigationname" => "#{radio_investigation.investigationname}",
                                                                                 "investigation_id" => "#{radio_investigation.investigation_id}",
                                                                                 "haslaterality" => "#{radio_investigation.haslaterality}",
                                                                                 "loinccode" => "#{radio_investigation.loinccode}",
                                                                                 "laterality" => "#{radio_investigation.laterality}",
                                                                                 "radiologyoptions" => "#{radio_investigation.radiologyoptions}",
                                                                                 "is_spine" => "#{radio_investigation.is_spine}",
                                                                                 "investigationadviseddate" => "#{radio_investigation.investigationadviseddate}",
                                                                                 "investigationfullcode" => "#{radio_investigation.investigationfullcode}",
                                                                                 "findings" => "",
                                                                                 "record_id" => opdrecord.id,
                                                                                 "asset_path" => Array.new,
                                                                                 "report_id" => Array.new]
        end
      end
      assessment_id = []
      patient_investigation.save()
      if patient_investigation_opthal
        patient_investigation_opthal.save()
        assessment_id.push(patient_investigation_opthal.id)
      end
      if patient_investigation_radio
        patient_investigation_radio.save()
        assessment_id.push(patient_investigation_radio.id)
      end

      inv_workflow = InvestigationWorkflow.create(:patient_id => appointment.patient_id, appointment_id: appointment.id.to_s, facility_id: appointment.facility_id, organisation_id: org_id, user_id: appointment.doctor.to_s, appointmentdate: appointment.appointmentdate, assessment_id: assessment_id)
      inv_workflow.advised
      patient_investigation.save()
    end

    # if (opdrecord.has_addedlaboratoryinvestigationlist? || opdrecord.has_investigationlist?)
    #   puts"============================================addedlaboratoryinvestigationlist"
    #   patient_investigation_data = opdrecord.addedlaboratoryinvestigationlist
    #   patient_investigation = PatientInvestigation.new
    #   patient_investigation['doctor_name'] = doctor.fullname
    #   patient_investigation['doctor'] = appointment.doctor.to_s
    #   patient_investigation['user_id'] = appointment.doctor.to_s
    #   patient_investigation['facility_id'] = appointment.facility_id
    #   patient_investigation['record_id'] = opdrecord.id
    #   patient_investigation['specalityid'] = opdrecord.specalityid
    #   patient_investigation['specalityname'] = opdrecord.specalityname
    #   patient_investigation['encounter_date'] = opdrecord.created_at
    #   patient_investigation['investigation_type'] = 'Laboratory'
    #   patient_investigation['encountertype'] = opdrecord.encountertype
    #   patient_laboratory_investigation_data.each_with_index do |lab_investigation, i|
    #     patient_investigation['laboratory_investigations'][i.to_i] = Hash["position" => "#{i.to_i + 1}",
    #                                                                "investigationname" => "#{lab_investigation.investigationname}",
    #                                                                "loinc_code" => "#{lab_investigation.loinc_code}",
    #                                                                "investigation_id" => "#{lab_investigation.investigation_id}",
    #                                                                "loinc_class" => "#{lab_investigation.loinc_class}",
    #                                                                "investigationadviseddate" => "#{lab_investigation.investigationadviseddate}",
    #                                                                "investigationfullcode" => "#{lab_investigation.investigationfullcode}"]
    #   end
    #   patient_investigation.save()
    # end
    #
    # if (opdrecord.has_investigationlist?)
    #   puts"========================================investigationlist"
    #   patient_investigation_data = opdrecord.investigationlist
    #   patient_investigation = PatientInvestigation.new
    #   patient_investigation['doctor_name'] = doctor.fullname
    #   patient_investigation['doctor'] = appointment.doctor.to_s
    #   patient_investigation['user_id'] = appointment.doctor.to_s
    #   patient_investigation['facility_id'] = appointment.facility_id
    #   patient_investigation['record_id'] = opdrecord.id
    #   patient_investigation['specalityid'] = opdrecord.specalityid
    #   patient_investigation['specalityname'] = opdrecord.specalityname
    #   patient_investigation['encounter_date'] = opdrecord.created_at
    #   patient_investigation['investigation_type'] = 'Radiology'
    #   patient_investigation['encountertype'] = opdrecord.encountertype
    #   patient_radiology_investigation_data.each_with_index do |radio_investigation,i|
    #     patient_investigation['radiology_investigations'][i.to_i] = Hash["position" => "#{i.to_i + 1}",
    #                                                                  "investigationname" => "#{radio_investigation.investigationname}",
    #                                                                  "investigation_id" => "#{radio_investigation.investigation_id}",
    #                                                                  "haslaterality" => "#{radio_investigation.haslaterality}",
    #                                                                  "loinccode" => "#{radio_investigation.loinccode}",
    #                                                                  "laterality" => "#{radio_investigation.laterality}",
    #                                                                  "radiologyoptions" => "#{radio_investigation.radiologyoptions}",
    #                                                                  "is_spine" => "#{radio_investigation.is_spine}",
    #                                                                  "investigationadviseddate" => "#{radio_investigation.investigationadviseddate}",
    #                                                                  "investigationfullcode" => "#{radio_investigation.investigationfullcode}"]
    #   end
    #   patient_investigation.save()
    # end
    # Code to transfer opd procedures to ipd procedures
  end

  # def get_daily_reports
  #   appointment_count = Appointment.where(:appointmentdate => @appointment.appointmentdate,facility_id: @appointment.facility_id.to_s).count
  #   cancelled_appointment_count = Appointment.where(:appointmentstatus => 89925002,:appointmentdate => @appointment.appointmentdate,facility_id: current_facility.id.to_s).count
  #   opd_patient_ids = Appointment.where(appointmentdate: Date.current,facility_id: current_facility.id.to_s).pluck(:patient_id)
  #   opd_new_patient_count = 0
  #   opd_old_patient_count = 0
  #   opd_patient_ids.each do |pat_id|
  #     pat=Patient.find_by(id: pat_id)
  #     unless Appointment.where(patient_id: pat_id).count > 1
  #       opd_new_patient_count = opd_new_patient_count+1
  #     else
  #       opd_old_patient_count = opd_old_patient_count+1
  #     end
  #   end
  #   daily_report = DailyReport.find_by(date: Date.current,facility_id: @appointment.facility_id.to_s)
  #   if daily_report.nil?
  #     report = DailyReport.new
  #     report.user_id = @appointment.user_id
  #     report.date = @appointment.appointmentdate
  #     report.appointment_count = appointment_count - cancelled_appointment_count
  #     report.month = @appointment.appointmentdate.month
  #     report.opd_new_patient_count = opd_new_patient_count
  #     report.opd_old_patient_count = opd_old_patient_count
  #     report.year = @appointment.appointmentdate.year
  #     report.organisation_id =  @appointment.user.organisation_id.to_s
  #     report.facility_id =   @appointment.facility_id.to_s
  #     report.save!
  #   else
  #     daily_report.update_attributes(appointment_count: appointment_count - cancelled_appointment_count,facility_id: @appointment.facility_id.to_s,:opd_old_patient_count => opd_old_patient_count,opd_new_patient_count: opd_new_patient_count)
  #   end
  # end
end

########### EXTRA CODE WHICH CAN BE ADDED TO CALL METHOD LATER.
# patient_prescriptions['medications'][i.to_i]['position'] = i.to_i + 1
# patient_prescriptions['medications'][i.to_i]['medicinename'] = medication.medicinename
# patient_prescriptions['medications'][i.to_i]['medicinequantity'] = medication.medicinequantity
# patient_prescriptions['medications'][i.to_i]['medicinefrequency'] = medication.medicinefrequency
# patient_prescriptions['medications'][i.to_i]['medicinedurationoption'] = medication.medicinedurationoption
# patient_prescriptions['medications'][i.to_i]['medicineduration'] = medication.medicineduration
# patient_prescriptions['medications'][i.to_i]['prescriptiondate'] = opdrecord.created_at
# patient_prescriptions['medications'][i.to_i]['medicineinstructions'] = medication.medicineinstructions

# template_data = opdrecord[:data]
# assessments
# diagnosis_data = opdrecord.diagnosislist
# diagnosis_data.each do |index,each_diagnosis|
#   Patient_assesment = PatientDiagnosis.new
#   if each_diagnosis.icddiagnosiscodehaslaterality
#     #query
#     Patient_assesment[:diagnosis_side] = each_diagnosis.icddiagnosiscodelateralityposition
#   end
#
#   Patient_assesment[:icd_code] = each_diagnosis.icddiagnosisfullcode
#
#   Patient_assesment[:patient_id] = opdrecord.patient_id
#   Patient_assesment[:usel_id] = opdrecord.usel_id
#   Patient_assesment.save
#
# end
# #procedures
# procedures_data = opdrecord.procedure
# procedures_data.each do |index,each_procedure|
#   Patient_procedure = PatientProcedure.new
#
#   Patient_procedure[:side] = each_procedure.procedureside
#   Patient_procedure[:status] = each_procedure.procedurestatus
#   Patient_procedure[:type] = each_procedure.proceduretype
#   Patient_procedure[:subtype] = each_procedure.procedurename
#   Patient_procedure[:qualifier] = each_procedure.procedurequalifier
#   Patient_procedure[:subqualifier] = each_procedure.proceduresubqualifier
#   Patient_procedure[:approach] = each_procedure.procedureapproach
#   Patient_procedure[:patient_id] = opdrecord.patient_id
#   Patient_procedure[:user_id] = opdrecord.user_id
#   Patient_procedure.save
#
# end
# #medication
# medication_data = opdrecord.treatmentmedication
# medication_data.each do |index,each_medication|
#   Patient_medication = PatientMedication.new
#
#   Patient_medication[:medicinename] = each_medication.medicinename
#   Patient_medication[:medicinefrequency] = each_medication.medicinefrequency
#   Patient_medication[:medicineduration] = each_medication.medicineduration
#   Patient_medication[:patient_id] = opdrecord.patient_id
#   Patient_medication[:user_id] = opdrecord.user_id
#   Patient_medication.save
#
# end
# #radiology investigations
# radiology_investigations_data = opdrecord.investigationlist
# radiology_investigations_data.each do |index,each_radiology_investigation|
#   Patient_radiology_investigation = PatientRadiologyInvestigation.new
#
#   Patient_radiology_investigation[:name]=each_radiology_investigation.investigationname
#   Patient_radiology_investigation[:loinc_code]=each_radiology_investigation.loinccode
#   Patient_radiology_investigation[:laterality]=each_radiology_investigation.laterality
#   Patient_radiology_investigation[:is_spine]=each_radiology_investigation.is_spine
#   Patient_radiology_investigation[:advised_date]=each_radiology_investigation.investigationadviseddate
#   Patient_radiology_investigation[:full_code]=each_radiology_investigation.investigationfullcode
#   Patient_radiology_investigation[:radiology_options_collection]=each_radiology_investigation.radiologyoptions_collection
#   investigation_details = RadiologyInvestigationData.find(each_radiology_investigation.investigation_id)
#   Patient_radiology_investigation[:template_id]=investigation_details.template_id
#   Patient_radiology_investigation[:specialty_id]=investigation_details.specialty_id
# end
# #Laboratory Investigations
# laboratory_investigations_data = opdrecord.addedlaboratoryinvestigationlist
# laboratory_investigations_data.each do |index,each_laboratory_investigation|
#   laboratory_investigation = PatientLaboratoryInvestigation.new
#
#   laboratory_investigation[:name] = each_laboratory_investigation.investigationname
#   laboratory_investigation[:loinc_class] = each_laboratory_investigation.loincclass
#   laboratory_investigation[:loinc_code] = each_laboratory_investigation.loinccode
#   laboratory_investigation[:advised_date] = each_laboratory_investigation.investigationadviseddate
# end
# #other investigations
# other_investigations_data = opdrecord.addedotherinvestigationlist
# other_investigations_data.each do |index,each_other_investigation|
#   other_investigation = PatientOtherInvestigation.new
#
#   other_investigation[:name] = each_other_investigation.investigationname
#   other_investigation[:loinc_class] = each_other_investigation.loinc_class
#   other_investigation[:loinc_code] = each_other_investigation.loinc_code
#   other_investigation[:laboratorytest_id] = each_other_investigation.laboratorytestid
#   other_investigation[:advised_date] = each_other_investigation.investigationadviseddate
#   other_investigation[:investigation_fullcode] = each_other_investigation.investigationfullcode
#
# end
