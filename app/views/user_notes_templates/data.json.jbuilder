json.sEcho @sEcho
json.iTotalRecords @total_certificate_template_count
json.iTotalDisplayRecords @user_notes_template_count
json.set! 'aaData' do
  json.array!(@user_notes_template) do |certificate_template|
    json.set! '0', certificate_template.name
    json.set! '1', '<span class ="mr5"><a data-remote="true" data-target="#invoice-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/user_notes_templates/' + certificate_template.id + '/edit?level=' + certificate_template.try(:level) + '"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/user_notes_templates/' + certificate_template.id + '?level=' + certificate_template.try(:level) + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
