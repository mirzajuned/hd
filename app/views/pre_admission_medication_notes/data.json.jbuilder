json.sEcho @sEcho
json.iTotalRecords @total_pre_admission_medication_note_count
json.iTotalDisplayRecords @pre_admission_medication_notes_count
json.set! "aaData" do
  json.array!(@pre_admission_medication_notes) do |pre_admission_medication_note|
    json.set! "0", pre_admission_medication_note.name
    json.set! "1", '<span class ="mr5"><a data-remote="true" data-target="#invoice-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/pre_admission_medication_notes/' + pre_admission_medication_note.id + '/edit?level=' + pre_admission_medication_note.level + '"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/pre_admission_medication_notes/' + pre_admission_medication_note.id + '?level=' + pre_admission_medication_note.level + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
