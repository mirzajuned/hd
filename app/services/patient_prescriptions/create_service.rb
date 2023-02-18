module PatientPrescriptions
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

      @pharmacy_prescription = PatientPrescription.find_by(record_id: opdrecord.id, patient_id: opdrecord.patientid)
      prescription_data = opdrecord.treatmentmedication
      if (@pharmacy_prescription.present?)
        if (opdrecord.has_treatmentmedication?)
          patient_prescriptions = {}
          patient_prescriptions['is_deleted'] = false
          patient_prescriptions['medications'] = []
          patient_prescriptions['store_name'] = opdrecord.pharmacy_store_name
          patient_prescriptions['store_id'] = opdrecord.pharmacy_store_id
          patient_prescriptions['store_present'] = opdrecord.pharmacy_store_present
          prescription_data.each_with_index do |medication, i|
            patient_prescriptions['medications'][i.to_i] = Hash[
                                                            "position" => "#{i.to_i + 1}",
                                                            "medicinename" => "#{medication.medicinename}",
                                                            "medicinequantity" => "#{medication.medicinequantity}",
                                                            "medicinefrequency" => "#{medication.medicinefrequency}",
                                                            "medicinetype" => "#{medication.medicinetype}",
                                                            "medicinedurationoption" => "#{medication.medicinedurationoption}",
                                                            "medicineduration" => "#{medication.medicineduration}",
                                                            "eyeside" => "#{medication.eyeside}",
                                                            "prescriptiondate" => "#{opdrecord.created_at}",
                                                            "medicineinstructions" => "#{medication.medicineinstructions}",
                                                            "instruction" => "#{medication.instruction}",
                                                            "pharmacy_item_id" => "#{medication.pharmacy_item_id || BSON::ObjectId.new}",
                                                            "generic_display_name" => "#{medication.generic_display_name}",
                                                            "generic_display_ids" => "#{medication.generic_display_ids}",
                                                            "medicine_from" => "#{medication.medicine_from}",
                                                            "taper_id" => "#{medication.taper_id}",
                                                            "status" => "#{medication.status}"
                                                              ]
          end
          patient_prescriptions['prescription_date'] = Date.current
          patient_prescriptions['prescription_datetime'] = Time.current
          @pharmacy_prescription.update(patient_prescriptions)
        else
          @pharmacy_prescription.update(is_deleted: true)
        end
        InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @pharmacy_prescription.id.to_s)
      else
        if (opdrecord.has_treatmentmedication?)
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

          prescription_data = opdrecord.treatmentmedication
          patient_prescriptions = PatientPrescription.new()
          patient_prescriptions['consultant_name'] = consultant_id.fullname
          patient_prescriptions['consultant_id'] = consultant_id.id.to_s
          patient_prescriptions['user_id'] = opdrecord.record_histories[0].user_id
          patient_prescriptions['facility_id'] = appointment.facility_id
          patient_prescriptions['patient_id'] = opdrecord.patientid
          patient_prescriptions['store_name'] = opdrecord.pharmacy_store_name
          patient_prescriptions['store_id'] = opdrecord.pharmacy_store_id
          patient_prescriptions['store_present'] = opdrecord.pharmacy_store_present

          patient_prescriptions['search'] = search
          patient_prescriptions['patient_name'] = patient_name
          patient_prescriptions['mobile_number'] = mobile_number
          patient_prescriptions['patient_identifier_id'] = patient_identifier_id
          patient_prescriptions['mr_no'] = mr_no
          patient_prescriptions['patient_identifier_id_search'] = patient_identifier_id_search
          patient_prescriptions['mr_no_search'] = mr_no_search
          patient_prescriptions['patient_name_search'] = patient_name_search
          patient_prescriptions['reg_hosp_ids'] = reg_hosp_ids

          patient_prescriptions['record_id'] = opdrecord.id
          patient_prescriptions['encountertype'] = opdrecord.encountertype
          patient_prescriptions['encountertypeid'] = opdrecord.encountertypeid
          patient_prescriptions['appointment_id'] = opdrecord.appointmentid
          patient_prescriptions['templatetype'] = opdrecord.templatetype
          patient_prescriptions['templateid'] = opdrecord.templateid
          patient_prescriptions['specalityid'] = opdrecord.specalityid
          patient_prescriptions['specalityname'] = opdrecord.specalityname
          patient_prescriptions['encounterdate'] = opdrecord.created_at
          patient_prescriptions['prescription_date'] = opdrecord.created_at
          patient_prescriptions['prescription_datetime'] = opdrecord.created_at
          patient_prescriptions['authorid'] = opdrecord.authorid
          patient_prescriptions['medication_comment'] = opdrecord.medicationcomments
          prescription_data.each_with_index do |medication, i|
            patient_prescriptions['medications'][i.to_i] = Hash[
                                                          "position" => "#{i.to_i + 1}",
                                                          "medicinename" => "#{medication.medicinename}",
                                                          "medicinequantity" => "#{medication.medicinequantity}",
                                                          "medicinefrequency" => "#{medication.medicinefrequency}",
                                                          "medicinetype" => "#{medication.medicinetype}",
                                                          "medicinedurationoption" => "#{medication.medicinedurationoption}",
                                                          "medicineduration" => "#{medication.medicineduration}",
                                                          "eyeside" => "#{medication.eyeside}",
                                                          "prescriptiondate" => "#{opdrecord.created_at}",
                                                          "medicineinstructions" => "#{medication.medicineinstructions}",
                                                          "instruction" => "#{medication.instruction}",
                                                          "pharmacy_item_id" => "#{medication.pharmacy_item_id || BSON::ObjectId.new}",
                                                          "generic_display_name" => "#{medication.generic_display_name}",
                                                          "medicine_from" => "#{medication.medicine_from}",
                                                          "generic_display_ids" => "#{medication.generic_display_ids}",
                                                          "taper_id" => "#{medication.taper_id}",
                                                          "status" => "#{medication.status}"
                                                        ]
          end
          patient_prescriptions.save()
          Analytics::Conversion::PharmacyPrescriptionJob.perform_later(patient_prescriptions.id.to_s, consultant_id.id.to_s, "Clinical")
          InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', patient_prescriptions.id.to_s)
        end
      end
    end
  end
end
