json.array!(@final_pincodes) do |pin|
  if pin[0] == "KH_039"
    json.state pin[1]
    json.district pin[3]
    json.commune pin[4]
    json.pincode pin[2]
  elsif pin[0] == "IN_108"
    json.state pin[1]
    json.city pin[3]
    json.pincode pin[2]
    json.area_managers pin[4]
    json.location_id pin[5]
    json.gst_state_code pin[6]
    json.alpha_code pin[7]
    json.is_union_territory pin[8]
    json.is_utgst_applicable pin[9]
  else
    json.state pin[1]
    json.city pin[3]
    json.pincode pin[2]
  end
end
