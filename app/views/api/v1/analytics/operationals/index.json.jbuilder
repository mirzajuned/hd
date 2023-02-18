json.set! "appointment_admission_data" do
  json.total_appointment_created @todays_data.present? ? @total_appointment_created.last.to_i : @total_appointment_created.sum.to_i
  json.total_appointment_arrived @todays_data.present? ? @total_appointment_arrived.last.to_i : @total_appointment_arrived.sum.to_i
  json.total_admission_created @todays_data.present? ? @total_admission_created.last.to_i : @total_admission_created.sum.to_i
  json.total_earnings @total_earnings
end

json.set! "doctor_converted_pharmacy" do
  json.doctor_pharmacy_data_total_count @todays_data.present? ? @doctor_pharmacy_data_total_count.last.to_i : @doctor_pharmacy_data_total_count.sum.to_i
  json.doctor_pharmacy_data_converted_count @todays_data.present? ? @doctor_pharmacy_data_converted_count.last.to_i : @doctor_pharmacy_data_converted_count.sum.to_i
end

json.set! "doctor_converted_optical" do
  json.doctor_optical_data_total_count @todays_data.present? ? @doctor_optical_data_total_count.last.to_i : @doctor_optical_data_total_count.sum.to_i
  json.doctor_optical_data_converted_count @todays_data.present? ? @doctor_optical_data_converted_count.last.to_i : @doctor_optical_data_converted_count.sum.to_i
end

json.set! "all_investigation" do
  json.all_investigation_total @all_investigation_total
  json.all_investigation_converted @all_investigation_converted
end

json.set! "surgery" do
  json.procedures_total_count @todays_data.present? ? @procedures_total_count.last.to_i : @procedures_total_count.reject(&:blank?).sum.to_i
  json.procedures_converted_count @todays_data.present? ? @procedures_converted_count.last.to_i : @procedures_converted_count.sum.to_i
end

json.set! "each_facility_rating" do
  json.facility_feedback_label @facility_feedback_label
  json.facility_feedback_data @facility_feedback_data
end

json.set! "patient_gender" do
  json.patient_gender_list @patient_gender_list
  json.patient_gender_array @patient_gender_array
end

json.set! "patient_age" do
  json.patient_age_label @patient_age_label
  json.patient_age_array @patient_age_array
end

json.set! "organisation_feedback_label" do
  json.organisation_feedback_label @organisation_feedback_label.map(&:titleize)
  json.organisation_feedback_data @organisation_feedback_data
end

json.set! "org_data_labels" do
  json.org_data_labels @org_data_labels
  json.org_feedback_data @org_feedback_data.map { |v| v.round(2) }
end
