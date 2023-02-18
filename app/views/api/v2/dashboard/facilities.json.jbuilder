json.facilities @current_user.facilities do |facility|
  json.id facility&.id
  json.name facility&.name
  json.abbreviation facility&.abbreviation
end