json.sEcho @sEcho
json.iTotalRecords @total_referring_docs_count
json.iTotalDisplayRecords @referring_docs_count
json.set! "aaData" do
  json.array!(@referring_doctors) do |referring_doc|
    json.set! "0", referring_doc.name
    json.set! "1", referring_doc.mobile_number
    json.set! "2", referring_doc.email
    json.set! "3", referring_doc.hospital_name
    json.set! "4", referring_doc.speciality
    json.set! "5", referring_doc.city
    json.set! "6", '<span class ="mr5"><a data-remote="true" data-target="#ref-doc-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/referring_doctors/' + referring_doc.id + '/edit"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" class="btn btn-danger btn-xs" data-remote="true" href="/referring_doctors/' + referring_doc.id + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
