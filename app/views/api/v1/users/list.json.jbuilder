json.array!(@users) do |user|
  json.id user.id
  json.fullname user.fullname
  json.department_id user.department_id
  json.facility_ids user.facility_ids
end
