json.sEcho @sEcho
json.iTotalRecords @total_records_count
json.iTotalDisplayRecords @total_investigations_count
json.set! "aaData" do
  json.array!(@custom_investigations) do |investigation|
    json.set! "0", investigation.try(:investigation_name)

    # code_length = investigation.investigation_id.to_s.size
    split_code = investigation.investigation_id
    # split_code = split_code.split('')
    # part1 = split_code[0..2].join()
    # part2 = split_code[3..5].join()
    # part3 = split_code[6..code_length].join()
    # custom_code = (part1.to_s + '-' + part2.to_s + '-' + part3.to_s).upcase
    custom_code = split_code.scan(/.{3}|.+/).join("-").upcase

    json.set! "1", custom_code

    json.set! "2", '<span class ="mr5"><a data-remote="true" data-target="#custom-investigation-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/custom_radiology_investigations/' + investigation.id + '/edit "><i class="fa fa-pencil-square-o"></i> Edit</a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/custom_radiology_investigations/' + investigation.id + '" rel="nofollow"><i class="fa fa-ban"></i> Disable</a></span>'
  end
end
