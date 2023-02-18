json.array!(@final_communes) do |commune|
  if commune[0] == "KH_039"
    json.district commune[1]
    json.commune commune[2]
    json.state commune[3]
  else
    json.district commune[1]
    json.commune commune[2]
    json.city commune[3]
  end
end
