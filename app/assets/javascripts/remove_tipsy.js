function remove_tipsy(){
  $(".tipsy").on('hover', function(){
    $(this).remove();
  });
}