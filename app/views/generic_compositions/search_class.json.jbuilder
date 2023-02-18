json.array! (@generic_compositions) do |item|
  json.name item.name
  json.category item.category
  json.class_id item.id
end
