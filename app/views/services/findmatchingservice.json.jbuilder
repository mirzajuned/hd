json.array!(@servicelist) do |service|
  json.id service.id.to_s
  json.label service.name
  json.value service.name
end
