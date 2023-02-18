json.sEcho @s_echo
json.iTotalRecords @total_icd_diagnosis_count
json.iTotalDisplayRecords @custom_icd_diagnosis_count
json.set! "aaData" do
  json.array!(@custom_icd_diagnosis) do |custom_icd_diagnosis|
    if custom_icd_diagnosis.icd_type == 'TranslatedIcdDiagnosis'
      json.set! "0", (custom_icd_diagnosis.try(:fullname) if custom_icd_diagnosis.try(:fullname).present?) || custom_icd_diagnosis.try(:originalname)
    else
      json.set! "0", (custom_icd_diagnosis.try(:originalname) if custom_icd_diagnosis.try(:originalname).present?) || custom_icd_diagnosis.try(:fullname)
    end

    if custom_icd_diagnosis.icd_type == 'CustomIcdDiagnosis'
      # code_length = custom_icd_diagnosis.code.to_s.size
      split_code = custom_icd_diagnosis.code
      # split_code = split_code.split('')
      # part1 = split_code[0..2].join()
      # part2 = split_code[3..5].join()
      # part3 = split_code[6..code_length].join()
      custom_code = split_code.scan(/.{3}|.+/).join("-").upcase
    end
    json.set! "1", custom_code || custom_icd_diagnosis.code.upcase

    json.set! "2", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (custom_icd_diagnosis.is_attached == true)) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>' if (custom_icd_diagnosis.is_attached == false))

    json.set! "3", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (custom_icd_diagnosis.has_children == true)) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>' if (custom_icd_diagnosis.has_children == false))

    icd_type = custom_icd_diagnosis.icd_type
    json.set! "4", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (icd_type == 'TranslatedIcdDiagnosis')) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>' if (icd_type != 'TranslatedIcdDiagnosis'))

    json.set! "5", '<span class ="mr5"><a data-remote="true" data-target="#custom-icd-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/custom_icd_diagnoses/' + custom_icd_diagnosis.id + '/edit"><i class="fa fa-pencil-square-o"></i> Edit</a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/custom_icd_diagnoses/' + custom_icd_diagnosis.id + '" rel="nofollow"><i class="fa fa-ban"></i> Disable</a></span>'
  end
end
