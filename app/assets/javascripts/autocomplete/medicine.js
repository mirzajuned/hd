$(document).ready(function() {

  medi_autocomplete_bind();

  function medi_autocomplete_bind() {
    x = []
    medication_type = []
    category = []
    var store_id = $('#opdrecord_view_pharmacy_store_id').val()
    jQuery(".medicinename").autocomplete({
      minLength: 3,
      source: function(request, response) {
        jQuery.ajax({
          dataType: "json",
          type: 'get',
          url: '/icdtree/getitems',
          //data: {searchpatient: params, remote: "true" },
          data: {
            q: request.term,
            remote: "true",
            store_id: store_id
          },
          success: function(data) {
            //jQuery('#searchpatientkeyword').removeClass('ui-autocomplete-loading')
            items = [];
            for(i = 0; i < data.length; i++){
              items[i] = data[i]
            }
            //Find Unique items from array
            //http://stackoverflow.com/questions/1960473/unique-values-in-an-array
            function onlyUnique(value, index, self) {
              return self.indexOf(value) === index;
            }
            unique = items.filter(onlyUnique);
            response(unique);
          },
          error: function(data) {}
        });
      },
      focus: function(event, ui) {
        //return false;
      },
      select: function(event, ui) {
        var itemname = ui.item.value;
        jQuery(this).val(itemname);



        // name = $(this).attr('name').replace('medicinename', 'pharmacy_item_id', 'medicinetype'); #Who used this and why
        // $('<input>').attr({
        //     type: 'hidden',
        //     // id: 'foo',
        //     name: name, // Where is name defined
        //     value: ui.item.item_id
        // }).appendTo($(this).parent());
        // alert("Helo");
        console.log(ui.item)
        jQuery(this).closest('.medicinetype').val(itemname);
        $(this).closest(".treatmentmedications").find(".lot_id").val(ui.item.lot_id)
        $(this).closest(".treatmentmedications").find(".code").val(ui.item.code)
        $(this).closest(".treatmentmedications").find('.medicinetype').val(ui.item.med_type)
        $(this).closest(".treatmentmedications").find('.pharmacy_item_id').val(ui.item.item_id)
        $(this).closest(".treatmentmedications").find('.generic_display_ids').val(ui.item.generic_display_ids)
        $(this).closest(".treatmentmedications").find('.generic_display_name').val(ui.item.generic_display_name)
        $(this).closest(".treatmentmedications").find('.medicine_from').val(ui.item.medicine_from)
        // jQuery(this).val(dosage);
        jQuery(this).closest('div').next().find('textarea').val(itemname);
        //                jQuery(this).val(medicinemame);
        //                jQuery(this).closest('div').next().find('textarea').val(presentation);
        //            }
        return false;
      },
      create: function() {
        $(this).data('ui-autocomplete')._renderItem = function(ul, item) {
          if (item.med_type && item.stock) {
            return $('<li>')
              .append('<a>' + item.label + '(' + item.med_type + ')' + '<label class=\"badge\">' + item.stock + '</label>' + '&nbsp; &nbsp; &nbsp;' + "<span class=\"badge pull-right\">" + item.type + "</span>" + '</a>')
              .appendTo(ul);
          } else if (item.med_type) {
            return $('<li>')
              .append('<a>' + item.label + '(' + item.med_type + ')' + '&nbsp; &nbsp; &nbsp;' + "<span class=\"badge pull-right\">" + item.type + "</span>" + '</a>')
              .appendTo(ul);
          } else if (item.stock) {
            return $('<li>')
              .append('<a>' + item.label + '&nbsp;' + '<label class=\"badge\">' + item.stock + '</label>' + '&nbsp; &nbsp; &nbsp;' + "<span class=\"badge pull-right\">" + item.type + "</span>" + '</a>')
              .appendTo(ul);
          } else {
            return $('<li>')
              .append('<a>' + item.label + '&nbsp; &nbsp; &nbsp;' + "<span class=\"badge pull-right\">" + item.type + "</span>" + '</a>')
              .appendTo(ul);
          }
        };
      }
    })

    // jQuery(".medication_group").on('click',"[id^=remove_medication_item_]",function(e){

    //     var id = e.currentTarget.id

    //     jQuery("#"+id).parent().parent().remove()
    // })


  }

  $('#opdrecord_view_pharmacy_store_id').on('change', function(e) {
    e.preventDefault()  
    medi_autocomplete_bind();
  })
});