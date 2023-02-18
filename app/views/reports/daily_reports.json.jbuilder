json.array!(@today_list) do |today_list|
  json.today_list today_list.attributes
  if today_list.try(:_type)
    unless today_list._type == "Invoice::Inventories::Department::OpticalInvoice" || today_list._type == "Invoice::Inventories::Department::PharmacyInvoice"
      json.patient_name Patient.find(today_list.patient_id).fullname
      json.patient_org_id PatientIdentifier.find_by(patient_id: today_list.patient_id).try(:patient_org_id)
    end
  end

  if today_list.try(:cash_register_type)
    json.patient_name Patient.find(today_list.patient_id).fullname
    json.patient_org_id PatientIdentifier.find_by(patient_id: today_list.patient_id).try(:patient_org_id)
  end
end
