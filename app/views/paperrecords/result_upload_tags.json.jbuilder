json.array!(@results_upload_tags) do |upload_tags|
  json.id "#{upload_tags.id}"
  json.text "#{upload_tags.tag_name}"
end
