class OtListViews::CreateService
  class << self
    def call(ot_schedule)
      specialty = Specialty.find_by(id: ot_schedule.specialty_id)
      doctor = User.find_by(id: ot_schedule.surgeonname)

      patient = ot_schedule.patient
      patient_display_id = patient&.patient_identifier_id
      patient_mr_no = patient&.patient_mr_no
      patient_type = patient&.patient_type
      patient_type_hash = { label: patient_type&.label, color: patient_type&.color }

      admission = ot_schedule.admission
      admission_reason = admission&.admissionreason
      daycare = admission&.daycare
      admission_type = admission&.admission_type || 'planned'
      insurance_state = admission&.insurance_status || 'Not Insured'

      ward_details = get_ward_details(admission)
      current_state = get_current_state(admission, ot_schedule)

      ot_room = ot_schedule.theatreno.present? ? OtRoom.find_by(id: ot_schedule.theatreno) : nil
      theatre_name = ot_room.present? ? ot_room.name : ot_schedule.theatreno

      OtListView.create(
        patient_name: patient&.fullname, specialty_id: specialty.id, specialty_name: specialty.name,
        patient_display_id: patient_display_id, patient_mr_no: patient_mr_no, patient_age: patient&.exact_age,
        patient_gender: patient&.gender, admission_display_id: admission&.display_id,
        ot_display_id: ot_schedule.display_id, operating_doctor: doctor&.fullname,
        operating_doctor_id: ot_schedule.surgeonname, ot_date: ot_schedule.otdate, ot_time: ot_schedule.ottime,
        ot_end_time: ot_schedule.otendtime, procedures: ot_schedule.procedurename, theatre_name: theatre_name,
        reason_for_admission: admission_reason, current_state: current_state[:name],
        current_state_color: current_state[:color], facility_id: ot_schedule.facility_id,
        organisation_id: ot_schedule.organisation_id, ot_id: ot_schedule.id, admission_id: ot_schedule.admission_id,
        daycare: daycare, ward_name: ward_details[:ward_name], ward_code: ward_details[:ward_code],
        room_name: ward_details[:room_name], room_code: ward_details[:room_code], bed_name: ward_details[:bed_name],
        bed_code: ward_details[:bed_code], patient_id: ot_schedule.patient_id, theatre_number: ot_schedule.theatreno,
        admission_type: admission_type, insurance_state: insurance_state, patient_type: patient_type_hash[:label],
        patient_type_color: patient_type_hash[:color], admission_stage: admission&.admission_stage,
        admission_milestones: admission&.admission_milestones, city: patient&.city, commune: patient&.commune,
        pincode: patient&.pincode, district: patient&.district, state: patient&.state,
        patient_mobilenumber: patient&.mobilenumber, age: patient&.age
      )
    end

    def get_current_state(admission, ot_schedule)
      is_engaged = ot_schedule.is_engaged
      is_done = ot_schedule.operation_done
      current_state = if ot_schedule.is_deleted
                        { name: 'Deleted', color: '#000000' }
                      elsif admission&.id
                        if admission&.patient_arrived && !is_engaged && !is_done
                          { name: 'Admitted', color: '#f0ad4e' }
                        elsif !is_done && is_engaged
                          { name: 'Engaged', color: '#ff8735' }
                        elsif is_done && !is_engaged
                          { name: 'Completed', color: '#5cb85c' }
                        end
                      end
      current_state || { name: 'Scheduled', color: '#d9534f' }
    end

    def get_ward_details(admission)
      if admission&.ward_id.nil? || admission&.room_id.nil? || admission&.bed_id.nil?
        { ward_code: nil, ward_name: nil, room_code: nil, room_name: nil, bed_code: nil, bed_name: nil }
      else
        ward = Ward.find_by(id: admission.ward_id)
        room = Room.find_by(id: admission.room_id)
        bed = room.beds.find_by(id: admission.bed_id)
        { ward_code: ward.code, ward_name: ward.name, room_code: room.code, room_name: room.name,
          bed_code: bed.code, bed_name: bed.name }
      end
    end
  end
end
