json.array!(@results_name) do |upload_tags|
  json.id "#{upload_tags.id}"
  puts json.value "#{upload_tags.name}"
end
