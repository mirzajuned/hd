json.tabs 4

json.ADMITTED_PATIENTS @admitted_list.each do |admitted_list|
  json.admission_id admitted_list.admission_id
  json.patient_name admitted_list.patient_name
  json.admission_time admitted_list.admission_time.strftime('%I:%M %p (%d%b)')
  json.admitting_doctor admitted_list.admitting_doctor
  json.reason_for_admission admitted_list.reason_for_admission
  if admitted_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code admitted_list.ward_code.upcase + "/" + admitted_list.room_code.upcase + "/" + admitted_list.bed_code.upcase
  end
end

json.SCHEDULED @scheduled_list.each do |scheduled_list|
  json.admission_id scheduled_list.admission_id
  json.patient_name scheduled_list.patient_name
  json.admission_time scheduled_list.admission_time.strftime('%I:%M %p (%d%b)')
  json.admitting_doctor scheduled_list.admitting_doctor
  json.reason_for_admission scheduled_list.reason_for_admission
  if scheduled_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code scheduled_list.ward_code.upcase + "/" + scheduled_list.room_code.upcase + "/" + scheduled_list.bed_code.upcase
  end
end

json.ADMITTED @current_admitted_list.each do |current_admitted_list|
  json.admission_id current_admitted_list.admission_id
  json.patient_name current_admitted_list.patient_name
  json.admission_time current_admitted_list.admission_time.strftime('%I:%M %p (%d%b)')
  json.admitting_doctor current_admitted_list.admitting_doctor
  json.reason_for_admission current_admitted_list.reason_for_admission
  if current_admitted_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code current_admitted_list.ward_code.upcase + "/" + current_admitted_list.room_code.upcase + "/" + current_admitted_list.bed_code.upcase
  end
end

json.DISCHARGED @discharged_list.each do |discharged_list|
  json.admission_id discharged_list.admission_id
  json.patient_name discharged_list.patient_name
  json.discharge_time discharged_list.discharge_time.try(:strftime, "%I:%M %p")
  json.admitting_doctor discharged_list.admitting_doctor
  json.reason_for_admission discharged_list.reason_for_admission
  if discharged_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code discharged_list.ward_code.upcase + "/" + discharged_list.room_code.upcase + "/" + discharged_list.bed_code.upcase
  end
end
