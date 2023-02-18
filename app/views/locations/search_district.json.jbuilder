json.array!(@final_districts) do |district|
  if district[0] == "KH_039"
    json.district district[1]
  else
    json.district district[1]
    json.city district[2]
  end
end
