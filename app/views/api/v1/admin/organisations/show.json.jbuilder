json.set! 'organisation' do
  json.id @organisation.id
  json.name @organisation.name
  json.tagline @organisation.tagline
  json.total_user_count @users.count
  json.active_user_count @users.count { |user| user.is_active }
  json.inactive_user_count @users.count { |user| !user.is_active }
  json.total_facility_count @facilities.count
  json.active_facility_count @facilities.count { |facility| facility.is_active }
  json.inactive_facility_count @facilities.count { |facility| !facility.is_active }
  json.appointments_count @appointments.count
  json.admissions_count @admissions.count
  json.total_pharmacy_count @pharmacy_prescriptions.count
  json.converted_pharmacy_count @pharmacy_prescriptions.count { |pharmacy| pharmacy.converted }
  json.not_converted_pharmacy_count @pharmacy_prescriptions.count { |pharmacy| !pharmacy.converted }
  json.total_optical_count @optical_prescriptions.count
  json.converted_optical_count @optical_prescriptions.count { |optical| optical.converted }
  json.not_converted_optical_count @optical_prescriptions.count { |optical| !optical.converted }
end
