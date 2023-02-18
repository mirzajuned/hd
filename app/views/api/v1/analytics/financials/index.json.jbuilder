json.set! "financial_collections_opd_collection" do
  json.opd_new_patient_amount @todays_data.present? ? @opd_new_patient_amount.reject(&:blank?).last.to_f : @opd_new_patient_amount.reject(&:blank?).sum.to_f
  json.opd_old_patient_amount @todays_data.present? ? @opd_old_patient_amount.reject(&:blank?).last.to_f : @opd_old_patient_amount.reject(&:blank?).sum.to_f
end
json.set! "financial_collections_ipd_collection" do
  json.ipd_new_patient_amount @todays_data.present? ? @ipd_new_patient_amount.reject(&:blank?).last.to_f : @ipd_new_patient_amount.reject(&:blank?).sum.to_f
  json.ipd_old_patient_amount @todays_data.present? ? @ipd_old_patient_amount.reject(&:blank?).last.to_f : @ipd_old_patient_amount.reject(&:blank?).sum.to_f
end
json.set! "financial_collections_optical_collection" do
  json.optical_new_patient_amount @todays_data.present? ? @optical_new_patient_amount.reject(&:blank?).last.to_f : @optical_new_patient_amount.reject(&:blank?).sum.to_f
  json.optical_old_patient_amount @todays_data.present? ? @optical_old_patient_amount.reject(&:blank?).last.to_f : @optical_old_patient_amount.reject(&:blank?).sum.to_f
end
json.set! "financial_collections_optical_collection" do
  json.pharmacy_new_patient_amount @todays_data.present? ? @pharmacy_new_patient_amount.reject(&:blank?).last.to_f : @pharmacy_new_patient_amount.reject(&:blank?).sum.to_f
  json.pharmacy_old_patient_amount @todays_data.present? ? @pharmacy_old_patient_amount.reject(&:blank?).last.to_f : @pharmacy_old_patient_amount.reject(&:blank?).sum.to_f
end

json.set! 'total_outpatient_data' do
  json.appointment_chart_labels @appointment_chart_labels
  json.opd_new_patient_amount @opd_new_patient_amount
  json.opd_old_patient_amount @opd_old_patient_amount
  json.opd_invoice_count @opd_invoice_count
end

json.set! 'total_inpatient_data' do
  json.appointment_chart_labels @appointment_chart_labels
  json.ipd_new_patient_amount @ipd_new_patient_amount
  json.ipd_old_patient_amount @ipd_old_patient_amount
  json.ipd_invoice_count @ipd_invoice_count
end

json.set! 'total_pharmacy_data' do
  json.appointment_chart_labels @appointment_chart_labels
  json.pharmacy_new_patient_amount @pharmacy_new_patient_amount
  json.pharmacy_old_patient_amount @pharmacy_old_patient_amount
  json.pharmacy_invoice_count @pharmacy_invoice_count
end

json.set! 'total_optical_data' do
  json.optical_new_patient_amount @optical_new_patient_amount
  json.optical_old_patient_amount @optical_old_patient_amount
  json.optical_invoice_count @optical_invoice_count
end

json.set! 'total_collection_in_last_one_week' do
  json.appointment_chart_labels @appointment_chart_labels
  json.weekly_overall_amount @weekly_overall_amount
end

json.set! 'total_collection_by_departments_this_week' do
  json.appointment_chart_labels @appointment_chart_labels
  json.weekly_opd_amount @weekly_opd_amount
  json.weekly_ipd_amount @weekly_ipd_amount
  json.weekly_pharmacy_amount @weekly_pharmacy_amount
  json.weekly_optical_amount @weekly_optical_amount
end

json.set! 'opd_old_vs_new_earning' do
  json.appointment_chart_labels @appointment_chart_labels
  json.weekly_opd_new_patient_amount @weekly_opd_new_patient_amount
  json.weekly_opd_old_patient_amount @weekly_opd_old_patient_amount
end

json.set! 'ipd_old_vs_new_earning' do
  json.appointment_chart_labels @appointment_chart_labels
  json.weekly_ipd_new_patient_amount @weekly_ipd_new_patient_amount
  json.weekly_ipd_old_patient_amount @weekly_ipd_old_patient_amount
end

json.set! 'pharmacy_old_vs_new_earning' do
  json.appointment_chart_labels @appointment_chart_labels
  json.weekly_pharmacy_new_patient_amount @weekly_pharmacy_new_patient_amount
  json.weekly_pharmacy_old_patient_amount @weekly_pharmacy_old_patient_amount
end

json.set! 'optical_old_vs_new_earning' do
  json.appointment_chart_labels @appointment_chart_labels
  json.weekly_optical_new_patient_amount @weekly_optical_new_patient_amount
  json.weekly_optical_old_patient_amount @weekly_optical_old_patient_amount
end
