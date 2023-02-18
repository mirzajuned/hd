json.selected_facility [@admission.facility_id, @admission.facility.name]
json.selected_doctor [@admission.doctor, @admission_list_view.admitting_doctor]
json.facilities @facilities.pluck(:id, :name)
json.current_doctors @current_doctors.pluck(:id, :fullname)
json.admissiondate @admission.admissiondate.to_date.strftime('%d/%m/%Y')
json.admissiontime @admission.admissiontime.strftime('%I:%M %p')
json.admissionstatus @admission_list_view.current_state
json.reason_for_admission @admission.admissionreason
json.dischargedate @admission.dischargedate.to_date.strftime('%d/%m/%Y')
json.dischargetime @admission.dischargetime.strftime('%I:%M %p')
json.managementplan @admission.managementplan
json.mindischargedate @min_date
