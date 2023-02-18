json.array!(@servicelist) do |service|
  json.value service.service_name
end
