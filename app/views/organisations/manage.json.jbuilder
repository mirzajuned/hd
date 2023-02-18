json.name @organisation.name
json.n_type "organisations"
json.n_child_display "Facility"
json.n_child_type "facilities"
json.n_id @organisation.id.to_s
json.children @organisation.facilities.where(:is_active => true).each do |facility|
  json.name facility.name
  json.n_type "facilities"
  json.n_child_display "Department"
  json.n_child_type "departments"
  json.n_id facility.id.to_s
  json.children facility.departments do |department|
    json.name department.name
    json.n_type "departments"
    json.n_child_display "User"
    json.n_child_type "users"
    json.n_id department.id.to_s
    json.facility_id facility.id.to_s

    json.children User.where(:department_id => department.id, :facility_ids.in => [facility.id], :is_active => true) do |user|
      json.name user.fullname
      json.n_type "users"
      json.n_id user.id.to_s
    end
  end
end
