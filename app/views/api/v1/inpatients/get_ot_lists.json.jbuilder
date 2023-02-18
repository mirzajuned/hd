json.tabs 5

json.ALL @all_list.each do |admitted_list|
  json.ot_id admitted_list.ot_id
  json.patient_name admitted_list.patient_name
  json.ot_time admitted_list.ot_time.try(:strftime, "%I:%M %p")
  json.operating_doctor admitted_list.operating_doctor
  json.reason_for_admission admitted_list.reason_for_admission
  if admitted_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code admitted_list.ward_code.upcase + "/" + admitted_list.room_code.upcase + "/" + admitted_list.bed_code.upcase
  end
end

json.SCHEDULED @scheduled_list.each do |scheduled_list|
  json.ot_id scheduled_list.ot_id
  json.patient_name scheduled_list.patient_name
  json.ot_time scheduled_list.ot_time.try(:strftime, "%I:%M %p")
  json.operating_doctor scheduled_list.operating_doctor
  json.reason_for_admission scheduled_list.reason_for_admission
  if scheduled_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code scheduled_list.ward_code.upcase + "/" + scheduled_list.room_code.upcase + "/" + scheduled_list.bed_code.upcase
  end
end

json.ADMITTED @admitted_list.each do |admitted_list|
  json.ot_id admitted_list.ot_id
  json.patient_name admitted_list.patient_name
  json.ot_time admitted_list.ot_time.try(:strftime, "%I:%M %p")
  json.operating_doctor admitted_list.operating_doctor
  json.reason_for_admission admitted_list.reason_for_admission
  if admitted_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code admitted_list.ward_code.upcase + "/" + admitted_list.room_code.upcase + "/" + admitted_list.bed_code.upcase
  end
end

json.ENGAGED @engaged_list.each do |engaged_list|
  json.ot_id engaged_list.ot_id
  json.patient_name engaged_list.patient_name
  json.ot_time engaged_list.ot_time.try(:strftime, "%I:%M %p")
  json.operating_doctor engaged_list.operating_doctor
  json.reason_for_admission engaged_list.reason_for_admission
  if engaged_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code engaged_list.ward_code.upcase + "/" + engaged_list.room_code.upcase + "/" + engaged_list.bed_code.upcase
  end
end

json.COMPLETED @completed_list.each do |completed_list|
  json.ot_id completed_list.ot_id
  json.patient_name completed_list.patient_name
  json.ot_time completed_list.ot_time.try(:strftime, "%I:%M %p")
  json.operating_doctor completed_list.operating_doctor
  json.reason_for_admission completed_list.reason_for_admission
  if completed_list.ward_code.nil?
    json.ward_code "DAYCARE"
  else
    json.ward_code completed_list.ward_code.upcase + "/" + completed_list.room_code.upcase + "/" + completed_list.bed_code.upcase
  end
end
