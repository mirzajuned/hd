json.sEcho @sEcho
json.iTotalRecords @total_radiology_set_count
json.iTotalDisplayRecords @radiology_sets_count
json.set! "aaData" do
  json.array!(@radiology_sets) do |radiology_set|
    json.set! "0", radiology_set.name
    json.set! "1", '<span class ="mr5"><a data-remote="true" data-target="#laboratory-set-modal" data-toggle="modal" class="btn btn-success btn-xs edit-radiology-set-button" href="/radiology_laboratory_sets/' + radiology_set.id + '/edit"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs delete-radiology-set-button" href="/radiology_laboratory_sets/' + radiology_set.id + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
