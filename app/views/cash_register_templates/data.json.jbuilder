json.sEcho @sEcho
json.iTotalRecords @total_cash_register_template_count
json.iTotalDisplayRecords @cash_register_templates_count
json.set! "aaData" do
  json.array!(@cash_register_templates) do |cash_register_template|
    json.set! "0", cash_register_template.name
    json.set! "1", '<span class ="mr5"><a data-remote="true" data-target="#cash-register-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/cash_register_templates/' + cash_register_template.id + '/edit"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/cash_register_templates/' + cash_register_template.id + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
