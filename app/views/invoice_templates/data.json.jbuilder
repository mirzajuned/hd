json.sEcho params[:sEcho]
json.iTotalRecords @total_invoice_template_count
json.iTotalDisplayRecords @invoice_templates_count
json.set! "aaData" do
  json.array!(@invoice_templates) do |invoice_template|
    json.set! "0", invoice_template.name
    json.set! "1", '<span class ="mr5"><a data-remote="true" data-target="#invoice-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/invoice_templates/' + invoice_template.id + '/edit"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/invoice_templates/' + invoice_template.id + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
