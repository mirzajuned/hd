function setPrintUrl(){
  jQuery(document).ready(function(){
    (function(){
      facility_id = jQuery("#facility-filter").val();
      defaulthref = jQuery("#btn-print-appointment").prop('href');
      btnhref = defaulthref + facility_id;
      jQuery("#btn-print-appointment").prop('href', btnhref);
      jQuery("#facility-filter").on('change', function(e){
        facility_id = jQuery(e.currentTarget).val();
        btnhref = defaulthref + facility_id;
        jQuery("#btn-print-appointment").prop('href', btnhref);
        console.log(btnhref);
      });
    })();
  });
}