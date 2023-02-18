// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//


//= require d3.min
//= require form-validator/jquery.form-validator.min

//= require bootstrap.min
//= require jquery-textcomplete
//= require signature_pad
//= require jquery-migrate-1.2.1.min
//= require jquery_ujs
//= require jquery.remotipart
//= require turbolinks
//= require webcam.min
//= require hg.history
//= require jquery.tipsy.min
//= require jquery-fileupload
//= require jquery-fileupload/vendor/tmpl
//= require jquery_nested_form
//= require jquery.sparkline.min
//= require jquery.cookies
//= require moment
//= require jquery.elevateZoom-3.0.8.min.js
//= require chosen.jquery.min
//= require fullcalendar.min
//= require jquery.tokeninput
//= require jquery.prettyPhoto
//= require jquery.datatables.min
//= require chosen.jquery.min
//= require custom
//= require daterangepicker
//= require daterangepicker_init
//= require daterangepicker.min.js
//= require raphael
//= require morris
//= require rickshaw.min
//= require hg-radio-button
//= require hg-checkbox
//= require template_optional_toggle
//= require rails.validations
//= require rails.validations.simple_form
//= require rails.validations.override
//= require jquery.blueimp-gallery.min
//= require bootstrap-image-gallery
//= require acc-wizard
//= require dropzone
//= require select2.full.min
//= require select2-optgroup-search
//= require spectrum
//= require jquery.hotkeys
//= require bootcards.min
//= require summernote.min
//= require wysihtml5-0.3.0.min
//= require bootstrap-wysihtml5
//= require data-confirm-modal
//= require pnotify.custom.min.js
//= require Chart.min.js
//= require common_print.js
//= require timer.jquery
//= require jquery.ba-throttle-debounce
//= require intro.js
//= require renumberIndex.js
//= require copyToClipboard.js
//= require jquery.multiselect.js
//= require multi-select.js
//= require invoices.js
//= require intlTelInput
//= require libphonenumber-js.min
// moment-timezone all timezone data
//= require moment-timezone-with-data

//= require cable.js

$( document ).ajaxComplete(function( event, xhr, settings ) {
    if(settings.dataType == "json") {
        var data = $.parseJSON(xhr.responseText);
        if(data && data.error && data.error == 'session_expired') {
            window.location.reload();
        }
    }
});

function remove_fields(link) {
  $(link).previous("input[type=hidden]").value = "1";
  $(link).up(".fields").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $(link).up().insert({
    before: content.replace(regexp, new_id)
  });
}


$(document).ready(function(){
  $(document).on('click','.settings_update li ul >li',function(){
    $('.padded_list li.active').removeClass('active');
    $(this).addClass('active');
  })

  $.datepicker._updateDatepicker_original = $.datepicker._updateDatepicker;
  $.datepicker._updateDatepicker = function(inst) {
      $.datepicker._updateDatepicker_original(inst);
      var afterShow = this._get(inst, 'afterShow');
      if (afterShow)
          afterShow.apply((inst.input ? inst.input[0] : null));  // trigger custom callback
  }
});
