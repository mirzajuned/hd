json.message "Succesfully Logged in"
json.access_token @api_key.access_token
json.user do
  json.id @user.id
  json.username @user.username
  json.salutation @user.salutation
  json.fullname @user.fullname
  json.designation @user.designation
  json.gender @user.gender
  json.mobilenumber @user.mobilenumber
  json.email @user.email
  json.user_profile_pic @user.user_profile_pic
  json.roles @user.selected_role.split(",")
end
json.facilities @user.facilities do |facility|
  json.id facility&.id
  json.name facility&.name
  json.abbreviation facility&.abbreviation
end
json.organisation_id @user.organisation_id

