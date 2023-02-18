json.array!(@prescriptions) do |prescription|
  json.id prescription.id
  json.created_at prescription.encounterdate.strftime("%d %b %Y")
  json.created_at_time prescription.encounterdate.strftime("%I:%M %p")
  json.patient_name Patient.find(prescription.patient_id).try(:fullname) || 'NA'
  json.department "284748001"
  json.doctor_name prescription.doctor_name
  json.patient_id PatientIdentifier.find_by(patient_id: prescription.patient_id).try(:patient_org_id) || 'NA'
  json.dispatched_from_pharmacy prescription.dispatched_from_pharmacy
  mr_no = PatientOtherIdentifier.find_by(patient_id: prescription.patient_id).try(:mr_no)
  if mr_no.present?
    json.mr_no PatientOtherIdentifier.find_by(patient_id: prescription.patient_id).mr_no
  end
  json.items prescription.medications.each do |med|
    json.inventory_item_id med[:pharmacy_item_id]
    json.name med[:medicinename]
    json.medicine_instructions med[:medicineinstructions]
    json.medicine_frequency med[:medicinefrequency]
    json.medicinedurationoption med[:medicinedurationoption]
    json.medicineduration med[:medicineduration]
    json.quantity med[:medicinequantity].to_i
    if med[:medicinetype] == "Tablets"
      # Quantity
      if med[:medicinequantity] == "1/2"
        quantity = 0.5
      elsif med[:medicinequantity] == "1/4"
        quantity = 0.25
      else
        quantity = med[:medicinequantity].to_i
      end

      # Frequency
      if med[:medicinefrequency] == "once a month"
        frequency = 0.033333 # 1/30
      elsif med[:medicinefrequency] == "once a week"
        frequency = 0.142857 # 1/7
      elsif med[:medicinefrequency] == "Sat-Sun"
        frequency = 2
      else
        frequency = med[:medicinefrequency].split("-").map { |i| i.to_i }.sum()
      end
      # Duration
      if med[:medicineduration] == ""
        duration = 1
      else
        duration = med[:medicineduration]
      end
      # DurationOption
      if med[:medicinedurationoption] == "W"
        durationoption = 7
      elsif med[:medicinedurationoption] == "M"
        durationoption = 30
      elsif med[:medicinedurationoption] == "D"
        durationoption = 1
      else
        durationoption = 5
      end
      # Total Units
      puts quantity
      total_units = quantity * frequency * durationoption * duration.to_i
    else
      total_units = 1
    end
    json.total_units total_units
    # puts med[:medicinename]
    # puts total_units
  end
end

json.partial! '/invoice/inventories/department/pharmacy_invoices/patient_prescription.js.erb', patient_prescription: @prescriptions
