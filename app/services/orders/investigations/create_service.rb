class Orders::Investigations::CreateService
  def self.call(order_item_advised_id, current_user, current_facility)
    order_advised = Order::Advised.find_by(order_item_advised_id: order_item_advised_id.to_s)
    case_sheet = CaseSheet.find_by(id: order_advised.case_sheet_id)
    appointment = Appointment.find_by(id: order_advised.appointment_id)
    patient = Patient.find_by(id: appointment.patient_id)
    flag = order_advised.type.gsub('_investigations', '')    
    queue = Investigation::Queues::CreateService.call(appointment.id, patient, flag, current_user, current_facility, Time.current)

    if flag == 'ophthal'
      ophthal_investigation = Investigation::Ophthal.find_by(order_item_advised_id: order_item_advised_id.to_s)
      unless ophthal_investigation
        ophthal_investigation = Investigation::Ophthal.new
      end
      ophthal_investigation.assign_attributes(name: order_advised.investigationname,
        investigation_side: order_advised.investigationside,
        investigation_id: order_advised.investigation_id,
        investigation_full_code: order_advised.investigation_id,
        is_custom: order_advised.is_custom,
        investigation_type: 'OphthalmologyInvestigationData',
        requested_by: current_user.id,
        entered_by: current_user.id,
        entered_by_username: current_user.fullname,
        entered_at: Time.current,
        entered_at_facility_id: current_facility.id,
        entered_at_facility_name: current_facility.name,
        advised_by: current_user.id,
        advised_by_username: current_user.fullname,
        advised_at: Time.current,
        advised_datetime: Time.current,
        advised_at_facility_id: current_facility.id,
        advised_at_facility_name: current_facility.name,
        facility_id: current_facility.id,
        organisation_id: current_facility.organisation_id,
        patient_id: patient.id,
        appointment_id: appointment.try(:id),
        queue_id: queue.id,
        case_sheet_id: case_sheet.id,
        patient_fullname: patient.fullname,
        patient_mobilenumber: patient.mobilenumber,
        patient_district: patient.district,
        patient_commune: patient.commune,
        patient_city: patient.city,
        patient_state: patient.state,
        patient_pincode: patient.pincode,
        patient_display_id: patient.patient_identifier_id,
        patient_mrno: patient.patient_mrn,
        patient_location: patient.patient_full_address,
        patient_gender: patient.gender,
        patient_age: patient.age,
        patient_exact_age: patient.exact_age,
        specialization: order_advised.get_label_for_side(order_advised.investigationside),
        order_item_advised_id: order_advised.order_item_advised_id.to_s
      )
      ophthal_investigation.save
      if ophthal_investigation.advised_at > queue.appointment_time
        queue.update(appointment_date: ophthal_investigation.advised_at, appointment_time: ophthal_investigation.advised_at)
      end
      CaseSheet::CreateInvestigationDetailService.call(appointment, ophthal_investigation, current_facility.id, current_user.id)
      
      Investigation::PatientOpd::CreateService.call(ophthal_investigation, flag)
    elsif flag == 'laboratory'
      laboratory_investigation = Investigation::Laboratory.find_by(order_item_advised_id: order_advised.order_item_advised_id.to_s)
      unless laboratory_investigation
        laboratory_investigation = Investigation::Laboratory.new
      end
      laboratory_investigation.assign_attributes(name: order_advised.investigationname,
        name: order_advised.investigationname,
        loinc_class: order_advised.loinc_class,
        loinc_code: order_advised.loinc_code,
        investigation_id: order_advised.investigation_id,
        investigation_full_code: order_advised.investigation_id,
        is_custom: order_advised.is_custom,
        investigation_type: 'LaboratoryInvestigationData',
        requested_by: current_user.id,
        entered_by: current_user.id,
        entered_by_username: current_user.fullname,
        entered_at: Time.current,
        entered_at_facility_id: current_facility.id,
        entered_at_facility_name: current_facility.name,
        advised_by: current_user.id,
        advised_by_username: current_user.fullname,
        advised_at: Time.current,
        advised_datetime: Time.current,
        advised_at_facility_id: current_facility.id,
        advised_at_facility_name: current_facility.name,
        facility_id: current_facility.id,
        organisation_id: current_facility.organisation_id,
        patient_id: patient.id,
        appointment_id: appointment.try(:id),
        queue_id: queue.id,
        case_sheet_id: case_sheet.id,
        patient_fullname: patient.fullname,
        patient_mobilenumber: patient.mobilenumber,
        patient_district: patient.district,
        patient_commune: patient.commune,
        patient_city: patient.city,
        patient_state: patient.state,
        patient_pincode: patient.pincode,
        patient_display_id: patient.patient_identifier_id,
        patient_mrno: patient.patient_mrn,
        patient_location: patient.patient_full_address,
        patient_gender: patient.gender,
        patient_age: patient.age,
        patient_exact_age: patient.exact_age,
        order_item_advised_id: order_advised.order_item_advised_id.to_s
      )
      laboratory_investigation.save
      if laboratory_investigation.advised_at > queue.appointment_time
        queue.update(appointment_date: laboratory_investigation.advised_at, appointment_time: laboratory_investigation.advised_at)
      end
      
      CaseSheet::CreateInvestigationDetailService.call(appointment, laboratory_investigation, current_facility.id, current_user.id)
      
      Investigation::PatientOpd::CreateService.call(laboratory_investigation, flag)
    elsif flag == 'radiology'
      radiology_investigation = Investigation::Radiology.find_by(order_item_advised_id: order_advised.order_item_advised_id.to_s)
      unless radiology_investigation
        radiology_investigation = Investigation::Radiology.new
      end

      radiology_investigation.assign_attributes(name: order_advised.investigationname,
        investigation_id: order_advised.investigation_id,
        investigation_full_code: order_advised.investigation_id.to_s + '###' + order_advised.laterality.to_s + '###' + order_advised.loinc_code.to_s,
        has_laterality: order_advised.haslaterality,
        laterality: order_advised.laterality,
        is_spine: 'Y',
        loinc_code: order_advised.loinc_code,
        radiology_options: order_advised.radiologyoptions,
        is_custom: order_advised.is_custom,
        investigation_type: 'RadiologyInvestigationData',
        requested_by: current_user.id,
        entered_by: current_user.id,
        entered_by_username: current_user.fullname,
        entered_at: Time.current,
        entered_at_facility_id: current_facility.id,
        entered_at_facility_name: current_facility.name,
        advised_by: current_user.id,
        advised_by_username: current_user.fullname,
        advised_at: Time.current,
        advised_datetime: Time.current,
        advised_at_facility_id: current_facility.id,
        advised_at_facility_name: current_facility.name,
        facility_id: current_facility.id,
        organisation_id: current_facility.organisation_id,
        patient_id: patient.id,
        appointment_id: appointment.try(:id),
        queue_id: queue.id,
        case_sheet_id: case_sheet.id,
        patient_fullname: patient.fullname,
        patient_mobilenumber: patient.mobilenumber,
        patient_district: patient.district,
        patient_commune: patient.commune,
        patient_city: patient.city,
        patient_state: patient.state,
        patient_pincode: patient.pincode,
        patient_display_id: patient.patient_identifier_id,
        patient_mrno: patient.patient_mrn,
        patient_location: patient.patient_full_address,
        patient_gender: patient.gender,
        patient_age: patient.age,
        patient_exact_age: patient.exact_age,
        specialization:  '',
        order_item_advised_id: order_advised.order_item_advised_id.to_s
      )
      radiology_investigation.save
      if radiology_investigation.advised_at > queue.appointment_time
        queue.update(appointment_date: radiology_investigation.advised_at, appointment_time: radiology_investigation.advised_at)
      end
      
      CaseSheet::CreateInvestigationDetailService.call(appointment, radiology_investigation, current_facility.id, current_user.id)
      
      Investigation::PatientOpd::CreateService.call(radiology_investigation, flag)
    end
  end
end