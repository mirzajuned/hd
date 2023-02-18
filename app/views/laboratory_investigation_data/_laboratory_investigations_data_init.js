var custom_investigations = jQuery('#custom-laboratory-investigations-list').dataTable({
  "bDestroy": true,
  "sPaginationType": "full_numbers",
  "bServerSide": true,
  "sAjaxSource":"/laboratory_investigation_data/investigations_data.json" ,
  "aoColumns": [
    {"sTitle":"Investigation Name","sWidth": "30%", "bSortable": false},
    {"sTitle":"Code","sWidth": "15%" , "bSortable": false},
    {"sTitle":"Is Custom","sWidth": "10%" , "bSortable": false},
    {"sTitle":"Subtests Present","sWidth": "15%" , "bSortable": false},
    {"sTitle":"Actions","sWidth": "15%", "bSortable": false}
  ],
  "oLanguage": {
    "sZeroRecords": "No Investigation found",
    "sLoadingRecords": "Please wait - loading custom investigation..."
  }
})
jQuery("select[name='custom-laboratory-investigations-list_length']").chosen({
  'min-width': '100px',
  'white-space': 'nowrap',
  disable_search_threshold: 10
})

