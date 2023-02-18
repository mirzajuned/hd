$(document).ready(function() {
  $('body').on('click','.custom-checkbox', function(e) {
  	
  	var current_class = $(this).attr("class");
  	var target_id = $(this).parent().attr("target-input-id");
  	var target_value = "";
  	var target_prev_value = $("#"+target_id).val();
  	if(target_prev_value !== "") {
  		var values_array = target_prev_value.split(",");	
  	} else {
  		var values_array = Array();
  	}
  	
  	if(current_class.indexOf("btn-darkblue") >= 0) {
  		$(this).removeClass('btn-darkblue');
  		values_array.splice( $.inArray($(this).attr("input-value"), values_array), 1 );
  		$(this).blur();
  	} else {
	    $(this).addClass('btn-darkblue');
	    values_array.push($(this).attr("input-value"))

  	}
  	target_value = values_array.toString();
  	$("#"+target_id).val(target_value);
      $("#"+target_id).trigger("change");
  });
});