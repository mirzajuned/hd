json.array!(@final_districts) do |district|
  json.district district[0]
  json.city district[1]
end
