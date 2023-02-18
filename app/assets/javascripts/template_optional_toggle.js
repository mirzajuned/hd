/**
 * Created by aditya on 12/19/14.
 * optional switch for the templates
 */
$(document).ready(function() {
    $('body').on('click','.optional_switch a', function(e) {
        e.preventDefault();
        var parent_id = $(e.srcElement.parentElement.parentElement).attr("hg-parent-element");
        var id = $(e.srcElement).attr("hg-element");
        $(e.srcElement.parentElement.parentElement).children().removeClass("disabled")
        $(e.srcElement.parentElement).addClass("disabled")
        $("#"+parent_id+">div").hide()
        $("#"+parent_id+">#"+id).show()
    });
    
     $('body').on('click','.optional_cardio_switch a', function(e) {
        e.preventDefault();
        var parent_id = $(e.srcElement.parentElement.parentElement).attr("hg-parent-element");
        var id = $(e.srcElement).attr("hg-element");
        $(e.srcElement.parentElement.parentElement).children().removeClass("disabled")
        $(e.srcElement.parentElement).addClass("disabled")
        $("#"+parent_id+">div").hide()
        $("#"+parent_id+">#"+id).show()
    });
     
     $('body').on('click','.optional_physical_switch a', function(e) {
        e.preventDefault();
        var parent_id = $(e.srcElement.parentElement.parentElement).attr("hg-parent-element");
        var id = $(e.srcElement).attr("hg-element");
        $(e.srcElement.parentElement.parentElement).children().removeClass("disabled")
        $(e.srcElement.parentElement).addClass("disabled")
        $("#"+parent_id+">div").hide()
        $("#"+parent_id+">#"+id).show()
    })
})