json.array!(@final_pincodes) do |pin|
  json.state pin[:state]
  json.city pin[:city]
  json.pincode pin[:pincode]
end
