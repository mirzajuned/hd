json.array!(@patients) do |pat|
  json.name pat[:name]
  json.arrived_time pat[:arrived_time]
end
@patient
