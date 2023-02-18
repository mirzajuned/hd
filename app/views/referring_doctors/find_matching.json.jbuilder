json.array!(@referring_doc_list) do |referring_doc|
  json.id referring_doc.id.to_s
  json.label referring_doc.name
  json.value referring_doc.name
  json.user_id referring_doc.user_id
  json.mobile_number referring_doc.mobile_number
  json.email referring_doc.email
  json.hospital_name referring_doc.hospital_name
  json.speciality referring_doc.speciality
  json.city referring_doc.city
end
