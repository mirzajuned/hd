json.sEcho @sEcho
json.iTotalRecords @total_services_count
json.iTotalDisplayRecords @services_count
json.set! "aaData" do
  json.array!(@services) do |service|
    json.set! "0", service.name
    json.set! "1", service.unit_cost
    json.set! "2", service.default_units
    json.set! "3", '<a data-remote="true" data-target="#invoice-modal" class="btn btn-xs btn-primary" data-toggle="modal" href="/services/' + service.id + '/edit?service_type=' + service.service_type.to_s + '&service_type_id=' + service.service_type_id.to_s + '"><i class="fa fa-pencil-square-o"></i></a> <a data-confirm="Are you sure?" data-method="delete" data-remote="true" class="btn btn-xs btn-danger" href="/services/' + service.id + '" rel="nofollow"><i class="fa fa-trash-alt"></i></a>'
  end
end
