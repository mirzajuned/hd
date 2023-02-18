var custom_investigations = jQuery('#custom-radiology-investigations-list').dataTable({
  "bDestroy": true,
  "sPaginationType": "full_numbers",
  "bServerSide": true,
  "sAjaxSource":"/custom_radiology_investigations/investigations_data.json" ,
  "aoColumns": [
    {"sTitle":"Custom Investigation Name","sWidth": "50%", "bSortable": false},
    {"sTitle":"Code","sWidth": "30%" , "bSortable": false},
    {"sTitle":"Actions","sWidth": "20%", "bSortable": false}
  ],
  "oLanguage": {
    "sZeroRecords": "No Investigation found",
    "sLoadingRecords": "Please wait - loading custom investigation..."
  }
})
jQuery("select[name='custom-radiology-investigations-list_length']").chosen({
  'min-width': '100px',
  'white-space': 'nowrap',
  disable_search_threshold: 10
})

