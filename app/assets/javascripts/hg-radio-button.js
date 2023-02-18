$(document).ready(function() {
  $('body').on("click",".custom-radio-button", function(e) {
  	var current_class = $(this).attr("class");
  	var target_id = $(this).parent().attr("target-input-id");
  	var target_value = "";

  	if(current_class.indexOf("btn-brown") >= 0 && target_value !== "") {
  		$(this).removeClass('btn-brown');
  		$(this).blur();
  	} else {
	    $(this).addClass('btn-brown').siblings().removeClass('btn-brown');
	    target_value = $(this).attr("input-value");
  	}
    $("#"+target_id).val(target_value);
    $("#"+target_id).trigger("change");
  });
});
