json.sEcho @sEcho
json.iTotalRecords @total_ophthal_set_count
json.iTotalDisplayRecords @ophthal_sets_count
json.set! "aaData" do
  json.array!(@ophthal_sets) do |ophthal_set|
    json.set! "0", ophthal_set.name
    json.set! "1", '<span class ="mr5"><a data-remote="true" data-target="#laboratory-set-modal" data-toggle="modal" class="btn btn-success btn-xs edit-opthal-set-button" href="/ophthal_laboratory_sets/' + ophthal_set.id + '/edit"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs delete-opthal-set-button" href="/ophthal_laboratory_sets/' + ophthal_set.id + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
