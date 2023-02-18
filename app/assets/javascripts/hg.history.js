function historySupport() {
  return !!(window.history && window.history.pushState !== undefined);
}

function pushPageState(state, title, href) {
  if (historySupport()) {
    //console.log(href);
    history.pushState(state, title, href);
    //console.log(window.history.length - 1);
  }
}

function replacePageState(state, title, href) {
  if (state == undefined) { state = null; }
  
  if (historySupport()) {
    history.replaceState(state, title, href);
  }
}

jQuery(function() {

    jQuery(window).on("popstate", function(e) {
	    //console.log("window.onpopstate");
	    //console.log("11111");
	    //console.log(window.history.length - 1);
	    //console.log(e);
	    //console.log(e.originalEvent.state['x']);
	    //console.log(location.href);

      window.location.reload();


      // if (e.originalEvent.state !== null) {
	    	// //console.log(e.originalEvent.state);
       //    	jQuery.ajax({
			// 	  url: location.href,
			// 	  dataType: 'script'
			// });



			/*
			.done(function( data ) {
				    if ( console && console.log ) {
				      console.log( "Sample of data:");
				      console.log(data);
				    }
			   });	
			*/      	

	    // }
    	/*
	    jQuery.ajax({
		      url: location.href,
		      dataType: 'script',
		      success: function(data, status, xhr) {
		        jQuery('body').trigger('ajax:success');
		      },
		      error: function(xhr, status, error) {
		        // You may want to do something else depending on the stored state
		        alert('Failed to load ' + location.href);
		      },
		      complete: function(xhr, status) {
		        jQuery('body').attr('data-state-href', location.href);
		      }
	    });
		*/
  	}); 
  	

	var getA = 'a.ps, calendar-ps';
	function getState(el) {
    	// insert your own code here to extract a relevant state object from an <a> or <form> tag
    	// for example, if you rely on any other custom "data-" attributes to determine the link behaviour
    	return {x: "1"};
	};

	jQuery(document).on("click", getA, function() {
		var href = jQuery(this).attr("href");
		//console.log(href);
		pushPageState(getState(this), "Loading...", this.href);
     	window.title = "Loading...";
     	return false;
		//console.log(href);
		//console.log(location.href);
	});

});