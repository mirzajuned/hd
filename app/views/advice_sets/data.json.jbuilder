json.sEcho @s_echo
json.iTotalRecords @total_advice_sets_count
json.iTotalDisplayRecords @advice_sets_count

json.set! "aaData" do
  json.array!(@advice_sets) do |advice_set|
    json.set! "0", '<strong>' + advice_set.name + '</strong>'
    json.set! "1", advice_set.created_at.strftime("%d %b'%y")
    json.set! "2", '<span class ="mr5"><a data-remote="true" data-target="#advice-set-modal" data-toggle="modal" class="btn btn-success btn-xs" href="/advice_sets/' + advice_set.id + '/edit?level=' + advice_set.level + '"><i class="fa fa-pencil-square-o"></i></a></span><span><a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-danger btn-xs" href="/advice_sets/' + advice_set.id + '?level=' + advice_set.level + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a></span>'
  end
  json.array!(@hg_advice_sets) do |advice_set|
    json.set! "0", '<strong>' + advice_set[:name] + '</strong>'
    json.set! "1", '<button class="btn btn-success btn-xs" style="border-radius:25px;opacity:1;border:0;" disabled="">Provided by HealthGraph</button>'
    json.set! "2", "<span class ='mr5'><a data-remote='true' data-target='#advice-set-modal' data-toggle='modal' class='btn btn-success btn-xs' href='/advice_sets/hg_data?id=" + advice_set[:id] + "'><i class='fa fa-file-alt'></i></a></span> <button class='btn btn-warning btn-xs' style='opacity:1;border:0;' disabled=''>Not Editable</button>"
  end
end
