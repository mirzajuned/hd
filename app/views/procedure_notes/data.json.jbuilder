json.sEcho @sEcho
json.iTotalRecords @total_procedure_note_count
json.iTotalDisplayRecords @procedure_notes_count
json.set! "aaData" do
  json.array!(@procedure_notes) do |procedure_note|
    json.set! "0", procedure_note.name
    json.set! "1", '<span class ="mr5"><a data-remote="true" data-target="#invoice-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/procedure_notes/' + procedure_note.id + '/edit?level=' + procedure_note.level + '"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/procedure_notes/' + procedure_note.id + '?level=' + procedure_note.level + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
