json.array!(@final_communes) do |commune|
  json.city commune[:city]
  json.district commune[:district]
  json.commune commune[:commune]
end
