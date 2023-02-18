//= require jquery.min
//= require jquery_ujs
//= require jquery.remotipart
//= require jquery.form-validator.min
//= require bootstrap.min
//= require pnotify.custom.min.js
//= require Chart.min
//= require select2.full.min
//= require jquery.tipsy.min
//= require jquery-fileupload
//= require jquery-fileupload/vendor/tmpl
//= require hg.history
//= require summernote.min

$( document ).ajaxComplete(function( event, xhr, settings ) {
    if(settings.dataType == "json") {
        var data = $.parseJSON(xhr.responseText);
        if(data && data.error && data.error == 'session_expired') {
            window.location.reload();
        }
    }
});