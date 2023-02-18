
jQuery(window).load(function() {
   
   // Page Preloader
   jQuery('#status').fadeOut();
   //jQuery('#preloader').delay(350).fadeOut(function(){
   //   jQuery('body').delay(350).css({'overflow':'auto'});
   //});
});

jQuery(document).ready(function() {


//Custom Code to avoid showing Password Confirmation msg before entering in Password confirmation field
  (function() {
    var $confirmationField, $element, handleBlur;

    $confirmationField = $element = handleBlur = function() {
      $confirmationField.data("blurredOnce", true);
      $element.data("changed", true);
      return $element.isValid($element[0].form.ClientSideValidations.settings.validators);
    };

    ClientSideValidations.validators.local.confirmation = function(element, options) {
      $element = element;
      $confirmationField = $("#" + (element.attr('id')) + "_confirmation");
      $confirmationField.off("blur", handleBlur).on("blur", handleBlur);
      if ($confirmationField.data("blurredOnce") && $element.val() !== $confirmationField.val()) {
        return options.message;
      }
    };

  }).call(this);

   // Toggle Left Menu
   //jQuery('.nav-parent > a').click(function() {
   //
   //   var parent = jQuery(this).parent();
   //   var sub = parent.find('> ul');
   //
   //   // Dropdown works only when leftpanel is not collapsed
   //   if(!jQuery('body').hasClass('leftpanel-collapsed')) {
   //      if(sub.is(':visible')) {
   //         sub.slideUp(200, function(){
   //            parent.removeClass('nav-active');
   //            jQuery('.mainpanel').css({height: ''});
   //            adjustmainpanelheight();
   //         });
   //      } else {
   //         closeVisibleSubMenu();
   //         parent.addClass('nav-active');
   //         sub.slideDown(200, function(){
   //            adjustmainpanelheight();
   //         });
   //      }
   //   }
   //   return false;
   //});
   //
   //function closeVisibleSubMenu() {
   //   jQuery('.nav-parent').each(function() {
   //      var t = jQuery(this);
   //      if(t.hasClass('nav-active')) {
   //         t.find('> ul').slideUp(200, function(){
   //            t.removeClass('nav-active');
   //         });
   //      }
   //   });
   //}
   //
   //function adjustmainpanelheight() {
   //   // Adjust mainpanel height
   //   var docHeight = jQuery(document).height();
   //   if(docHeight > jQuery('.mainpanel').height())
   //      jQuery('.mainpanel').height(docHeight);
   //}
   
   
   // Tooltip
   jQuery('.tooltips').tooltip({ container: 'body'});
   
   // Popover
   jQuery('.popovers').popover();
   
   // Close Button in Panels
   jQuery('.panel .panel-close').click(function(){
      jQuery(this).closest('.panel').fadeOut(200);
      return false;
   });
   
   // Form Toggles
   //jQuery('.toggle').toggles({on: true});
   
   //jQuery('.toggle-chat1').toggles({on: false});
   
   //// Sparkline
   //jQuery('#sidebar-chart').sparkline([4,3,3,1,4,3,2,2,3,10,9,6], {
	//  type: 'bar',
	//  height:'30px',
   //   barColor: '#428BCA'
   //});
   //
   //jQuery('#sidebar-chart2').sparkline([1,3,4,5,4,10,8,5,7,6,9,3], {
	//  type: 'bar',
	//  height:'30px',
   //   barColor: '#D9534F'
   //});
   //
   //jQuery('#sidebar-chart3').sparkline([5,9,3,8,4,10,8,5,7,6,9,3], {
	//  type: 'bar',
	//  height:'30px',
   //   barColor: '#1CAF9A'
   //});
   //
   //jQuery('#sidebar-chart4').sparkline([4,3,3,1,4,3,2,2,3,10,9,6], {
	//  type: 'bar',
	//  height:'30px',
   //   barColor: '#428BCA'
   //});
   //
   //jQuery('#sidebar-chart5').sparkline([1,3,4,5,4,10,8,5,7,6,9,3], {
	//  type: 'bar',
	//  height:'30px',
   //   barColor: '#F0AD4E'
   //});
   
   
   // Minimize Button in Panels
   jQuery('.minimize').click(function(){
      var t = jQuery(this);
      var p = t.closest('.panel');
      if(!jQuery(this).hasClass('maximize')) {
         p.find('.panel-body, .panel-footer').slideUp(200);
         t.addClass('maximize');
         t.html('&plus;');
      } else {
         p.find('.panel-body, .panel-footer').slideDown(200);
         t.removeClass('maximize');
         t.html('&minus;');
      }
      return false;
   });
   
   
   // Add class everytime a mouse pointer hover over it
   jQuery('.nav-bracket > li').hover(function(){
      jQuery(this).addClass('nav-hover');
   }, function(){
      jQuery(this).removeClass('nav-hover');
   });
   
   
   // Menu Toggle
   jQuery('.menutoggle').click(function(event){
       event.stopPropagation();
       jQuery(".leftnav").toggle();
   });
   jQuery('html').click(function(e){
       if(jQuery(".leftnav").is(':visible')){
           jQuery(".leftnav").toggle()
       }
   })
   // Chat View
   jQuery('#chatview').click(function(){
      
      var body = jQuery('body');
      var bodypos = body.css('position');
      
      if(bodypos != 'relative') {
         
         if(!body.hasClass('chat-view')) {
            body.addClass('leftpanel-collapsed chat-view');
            jQuery('.nav-bracket ul').attr('style','');
            
         } else {
            
            body.removeClass('chat-view');
            
            if(!jQuery('.menutoggle').hasClass('menu-collapsed')) {
               jQuery('body').removeClass('leftpanel-collapsed');
               jQuery('.nav-bracket li.active ul').css({display: 'block'});
            } else {
               
            }
         }
         
      } else {
         
         if(!body.hasClass('chat-relative-view')) {
            
            body.addClass('chat-relative-view');
            body.css({left: ''});
         
         } else {
            body.removeClass('chat-relative-view');   
         }
      }
      
   });
   
   reposition_searchform();
   
   jQuery(window).resize(function(){
      
      if(jQuery('body').css('position') == 'relative') {

         jQuery('body').removeClass('leftpanel-collapsed chat-view');
         
      } else {
         
         jQuery('body').removeClass('chat-relative-view');         
         jQuery('body').css({left: '', marginRight: ''});
      }
      
      reposition_searchform();
      
   });
   
   function reposition_searchform() {
      if(jQuery('.searchform').css('position') == 'relative') {
         jQuery('.searchform').insertBefore('.leftpanelinner .userlogged');
      } else {
         jQuery('.searchform').insertBefore('.header-right');
      }
   }
   
   
   // Sticky Header
   if(jQuery.cookie('sticky-header'))
      jQuery('body').addClass('stickyheader');
      
   // Sticky Left Panel
   if(jQuery.cookie('sticky-leftpanel')) {
      jQuery('body').addClass('stickyheader');
      jQuery('.leftpanel').addClass('sticky-leftpanel');
   }
   
   // Left Panel Collapsed
   if(jQuery.cookie('leftpanel-collapsed')) {
      jQuery('body').addClass('leftpanel-collapsed');
      jQuery('.menutoggle').addClass('menu-collapsed');
   }
   
   // Changing Skin
   var c = jQuery.cookie('change-skin');
   if(c) {
      jQuery('head').append('<link id="skinswitch" rel="stylesheet" href="css/style.'+c+'.css" />');
   }

    //$(".nav-bracket a").on("click",function(){
    //    if(!$(this).parent().hasClass("nav-parent")) {
    //        $(".nav-bracket li").removeClass("nav-active active")
    //    }
    //
    //})
    //
    //$(".nav-bracket >.nav-parent").on("click",function(){
    //    $(this).addClass("nav-active")
    //})
    //
    //$(".nav-bracket .children > li").on("click",function(){
    //    $(this).addClass("active")
    //})


    $(function () {
        $('.modal').scroll(sticky_relocate);
    });

});
//bootstrap modal fix for focus issue
var enforceModalFocusFn = $.fn.modal.Constructor.prototype.enforceFocus;

$.fn.modal.Constructor.prototype.enforceFocus = function() {};

//end of fix

function sticky_relocate() {
    var window_top = $(window).scrollTop();
    if($('#hg-sticky-anchor').length > 0){
        var div_top = $('#hg-sticky-anchor').offset().top;
        if (window_top > div_top) {
            $('.hg-sticky').addClass('hg-stick').css('top',window_top-div_top+134);
        } else {
            $('.hg-sticky').removeClass('hg-stick').removeAttr("style");
        }
    }

}
