json.sEcho @sEcho
json.iTotalRecords @total_ward_list_count
json.iTotalDisplayRecords @ward_list_count
count = 0
json.set! "aaData" do
  json.array!(@ward_list) do |ward|
    count += 1
    # json.set! "0", ward.name
    json.set! "0", render('ipd_patients/partials/bedsmanagement_layout.html', ward: ward, ward_list: @ward_list, count: count, seatmapname: "seatmap#{count}")
  end
end
