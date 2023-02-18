json.array!(@final_cities) do |city|
  json.city city[0]
  json.state city[1]
end
