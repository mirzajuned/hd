json.sEcho params[:sEcho]
json.iTotalRecords @summary[:count]
json.iTotalDisplayRecords @summary[:count]
json.totalAmountArray @summary
json.set! 'aaData' do
  json.array!(@data_array) do |data_set|
    # Table Data
    data_set.each_with_index do |data, i|
      json.set! i.to_s, data.to_s
    end
  end
end
