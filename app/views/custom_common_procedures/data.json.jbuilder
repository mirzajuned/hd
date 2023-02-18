json.sEcho @sEcho
json.iTotalRecords @total_procedures_count
json.iTotalDisplayRecords @custom_procedures_count
json.set! "aaData" do
  json.array!(@custom_common_procedure) do |custom_common_procedure|
    json.set! "0", custom_common_procedure.name

    if custom_common_procedure.procedure_type == 'CustomCommonProcedure'
      # code_length = custom_common_procedure.code.to_s.size
      split_code = custom_common_procedure.code
      # split_code = split_code.split('')
      # part1 = split_code[0..2].join()
      # part2 = split_code[3..5].join()
      # part3 = split_code[6..code_length].join()
      # custom_code = (part1.to_s + '-' + part2.to_s + '-' + part3.to_s).upcase
      custom_code = split_code.scan(/.{3}|.+/).join("-").upcase
    end

    json.set! "1", custom_code || custom_common_procedure.code.upcase
    json.set! "2", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (custom_common_procedure.is_attached == true)) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>' if (custom_common_procedure.is_attached == false))
    json.set! "3", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (custom_common_procedure.has_laterality == true)) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>' if (custom_common_procedure.has_laterality == false))
    json.set! "4", '<span class ="mr5"><a data-remote="true" data-target="#custom-procedure-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/custom_common_procedures/' + custom_common_procedure.id + '/edit"><i class="fa fa-pencil-square-o"></i> Edit</a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/custom_common_procedures/' + custom_common_procedure.id + '" rel="nofollow"><i class="fa fa-ban"></i> Disable</a></span>'
  end
end
