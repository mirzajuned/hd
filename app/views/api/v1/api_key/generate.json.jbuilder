json.status 'success'
json.access_token @api_key.access_token
json.expiry_time @api_key.expiry_time
json.id @user.id
json.username @user.username
json.salutation @user.salutation
json.fullname @user.fullname
json.designation @user.designation
json.gender @user.gender
json.mobilenumber @user.mobilenumber
json.email @user.email
json.user_profile_pic @user.user_profile_pic
json.roles @user.selected_role.split(',')
json.primary_role @user.primary_role
json.organisation_id @user.organisation_id
json.facilities @user.facilities.as_json
json.department_ids @user.department_ids
json.specialty_ids @user.specialty_ids
json.users_each_facility @user.organisation.facilities.map do |facility|
  users_fac = User.where(:facility_ids.in => [facility.id.to_s])
  json.facility_id facility.id.to_s
  json.user_count users_fac.size
  json.users users_fac.map { |user| { id: user.id, salutation: user.salutation, fullname: user.fullname, user_profile_pic: user.user_profile_pic, department_ids: user.department_ids, specialty_ids: user.specialty_ids, roles: user.roles.map(&:name) } }
end
# if @user.selected_role.split(",")[0] == "doctor"
#   json.doctors @user.facilities.map { |facility|
#                  { "#{facility.id}": [ { id: @user.id, salutation: @user.salutation, fullname: @user.fullname } ]
#                  } }
# elsif @user.selected_role.split(",")[0] == "receptionist"
json.doctors @user.facilities.map { |facility|
  @users = User.where(:facility_ids.in => [facility.id.to_s], :role_ids.in => [158965000], is_active: true)
  { "#{facility.id}": @users.map { |user|
    { id: user.id, salutation: user.salutation, fullname: user.fullname }
  } }
}
# end
