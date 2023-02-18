json.set! 'organisation' do
  json.id @organisation.id
  json.name @organisation.name
end

json.set! 'users' do
  json.array!(@users) do |user|
    json.id user.id
    json.fullname user.fullname
    json.username user.username
    json.email user.email
    json.roles user.selected_role
    json.registered_date user.created_at.to_date
    json.facility_names user.facilities.pluck(:name)
    json.active user.is_active
  end
end
