json.array!(@facilities) do |facility|
  json.id facility.id
  json.name facility.name
end
