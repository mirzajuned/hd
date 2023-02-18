function confirm_alert(invoice_id, user_id, type, action) {
  var params = {invoice_id: invoice_id, user_id: user_id, type: type, action: action};
  var confirm_message = confirm("Are you sure you want to convert this draft bill to a final bill? You will not be able to remove any services or packages that are already added.");
  if (confirm_message == true) {
    $.ajax({
      type: "GET",
      dataType: "json",
      url: "/invoice/invoices/convert_to_final",
      data: {ajax: params, remote: "true" },
      success: function(response){
        $('.btn-remove-draft').hide();
        $('.btn-convert-final').hide();
        $('#edit_ins_invoice_path').text('Edit')
      }
    })
  }
}

function refresh_main_list() {
  $('.active-admission').trigger("click");
  $('.active-appointment').trigger("click");
}
