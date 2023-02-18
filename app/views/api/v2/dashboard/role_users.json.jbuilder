json.roles do
  json.id @role_user.pluck(:id)
  json.name @role_user.pluck(:fullname)
end