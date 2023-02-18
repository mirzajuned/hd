json.sEcho @s_echo
json.iTotalRecords @total_custom_consent_count
json.iTotalDisplayRecords @custom_consent_count

json.set! 'aaData' do
  json.array!(@custom_consent) do |custom_consent|
    @specialty_name = Specialty.find_by(id: custom_consent.specialty_id).name
    json.set! '0', '<strong>' + custom_consent.name + '</strong>'
    json.set! '1', @specialty_name
    json.set! '2', custom_consent.created_at.strftime("%d %b'%y")
    json.set! '3', '<span class ="mr5"><a data-remote="true" data-target="#custom-consents-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/custom_consents/' + custom_consent.id + '/edit?level=' + custom_consent.level + '"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure you want to delete?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/custom_consents/' + custom_consent.id + '?level=' + custom_consent.level + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
end
