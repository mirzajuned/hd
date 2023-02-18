json.set! "organisation_data" do
  json.organisation_name @organisation_name
  json.active_users @active_users
  json.total_doctors @total_doctors
  json.total_centers @total_centers
end
