json.sEcho @sEcho
json.iTotalRecords @total_records_count
json.iTotalDisplayRecords @total_investigations_count
json.set! "aaData" do
  json.array!(@custom_investigations) do |investigation|
    json.set! "0", investigation.try(:investigation_name)

    json.set! "1", investigation.loinc_code

    json.set! "2", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (investigation.is_custom == true)) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>')

    json.set! "3", ('<i style="color: green;" class="fa fa-check" aria-hidden="true"></i>' if (investigation.panel_ids.present?)) || ('<i style="color: red;" class="fa fa-times" aria-hidden="true"></i>')

    json.set! "4", '<span class ="mr5"><a data-remote="true" data-target="#custom-investigation-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/laboratory_investigation_data/' + investigation.id + '/edit "><i class="fa fa-pencil-square-o"></i> Edit</a></span>
        <span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/laboratory_investigation_data/' + investigation.id + '" rel="nofollow"><i class="fa fa-ban"></i> Disable</a></span>'
  end
end
