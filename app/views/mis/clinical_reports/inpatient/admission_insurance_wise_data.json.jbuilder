# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_admission_count
json.iTotalDisplayRecords @total_admission_count
json.set! "aaData" do
  json.array!(@admissions) do |admission|
    # Table Data
    json.set! "0", admission[:_id].to_s.titleize
    json.set! "1", admission[:admission_count]
  end
end
