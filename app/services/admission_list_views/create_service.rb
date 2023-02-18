class AdmissionListViews::CreateService
  class << self
    def call(admission)
      specialty = Specialty.find_by(id: admission.specialty_id)
      doctor = User.find_by(id: admission.doctor)
      patient = admission.patient
      patient_display_id = patient&.patient_identifier_id
      patient_mr_no = patient&.patient_mr_no
      patient_type = patient&.patient_type
      patient_type_hash = { label: patient_type&.label, color: patient_type&.color }

      admission_reason = admission&.admissionreason
      daycare = admission&.daycare
      admission_type = admission&.admission_type || 'planned'
      insurance_state = admission&.insurance_status || 'Not Insured'

      ward_details = get_ward_details(admission)
      current_state = get_current_state(admission)
      insurance_badge_color = get_insurance_badge_color(insurance_state)

      AdmissionListView.create(
        patient_name: patient.fullname, specialty_id: specialty.id, specialty_name: specialty.name,
        patient_display_id: patient_display_id, patient_mr_no: patient_mr_no, patient_age: patient&.exact_age,
        patient_gender: patient&.gender, admission_display_id: admission.display_id, admitting_doctor: doctor&.fullname,
        admitting_doctor_id: admission.doctor, admission_date: admission.admissiondate,
        admission_time: admission.admissiontime, discharge_date: admission.dischargedate,
        discharge_time: admission.dischargetime, daycare: daycare, ward_name: ward_details[:ward_name],
        ward_code: ward_details[:ward_code], room_name: ward_details[:room_name], room_code: ward_details[:room_code],
        bed_name: ward_details[:bed_name], bed_code: ward_details[:bed_code], reason_for_admission: admission_reason,
        current_state: current_state[:name], current_state_color: current_state[:color],
        insurance_state: insurance_state, insurance_badge_color: insurance_badge_color,
        facility_id: admission.facility_id, organisation_id: admission.organisation_id, admission_id: admission.id,
        patient_id: admission.patient_id, admission_type: admission_type, patient_type: patient_type_hash[:label],
        patient_type_color: patient_type_hash[:color], admission_stage: admission.admission_stage,
        admission_milestones: admission.admission_milestones, city: patient&.city, commune: patient&.commune,
        pincode: patient&.pincode, district: patient&.district, state: patient&.state,
        patient_mobilenumber: patient&.mobilenumber, age: patient&.age, user_id: admission.user_id
      )
    end

    def get_current_state(admission)
      if admission.is_deleted
        { name: 'Deleted', color: '#000000' }
      elsif admission.patient_arrived && !admission.isdischarged
        { name: 'Admitted', color: '#f0ad4e' }
      elsif admission.patient_arrived && admission.isdischarged
        { name: 'Discharged', color: '#5cb85c' }
      else
        { name: 'Scheduled', color: '#d9534f' }
      end
    end

    def get_insurance_badge_color(insurance_state)
      if insurance_state == 'Not Insured'
        'default'
      elsif insurance_state == 'Approved'
        'success'
      elsif insurance_state == 'Rejected'
        'danger'
      elsif insurance_state == 'Waiting'
        'info'
      end
    end

    def get_ward_details(admission)
      if admission.ward_id.nil? || admission.room_id.nil? || admission.bed_id.nil?
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
