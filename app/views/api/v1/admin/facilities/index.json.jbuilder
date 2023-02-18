json.set! 'organisation' do
  json.id @organisation.id
  json.name @organisation.name
end

json.set! 'facilities' do
  json.array!(@facilities) do |facility|
    json.id facility.id
    json.name facility.name
    json.abbreviation facility.abbreviation
    json.registered_date facility.created_at.to_date
    json.total_user_count @users.count { |user| user.facility_ids.include?(facility.id) }
    json.active_user_count @users.count { |user| user.is_active && user.facility_ids.include?(facility.id) }
    json.inactive_user_count @users.count { |user| !user.is_active && user.facility_ids.include?(facility.id) }
    json.active facility.is_active
  end
end
