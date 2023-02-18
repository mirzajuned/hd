window.ClientSideValidations.formBuilders['ActionView::Helpers::FormBuilder'] = {
    add: function(element, settings, message) {
        // custom add code here
        var form, inputErrorField, label, labelErrorField;
        form = $(element[0].form);
        if (element.data('valid') !== false && (form.find("label.message[for='" + (element.attr('id')) + "']")[0] == null)) {
            inputErrorField = jQuery(settings.input_tag);
            labelErrorField = jQuery(settings.label_tag);
            label = form.find("label[for='" + (element.attr('id')) + "']:not(.message)");
            if (element.attr('autofocus')) {
                element.attr('autofocus', false);
            }
            //for custom error field
            if($("#"+$(element[0]).attr("id")+"_error").length) {
                $("#"+$(element[0]).attr("id")+"_error").html(inputErrorField);
            }
            else {
                element.before(inputErrorField);
                inputErrorField.find('span#input_tag').replaceWith(element);
            }
            $(element[0]).parent().addClass("has-error")
            inputErrorField.find('label.message').attr('for', element.attr('id'));
            labelErrorField.find('label.message').attr('for', element.attr('id'));
            labelErrorField.insertAfter(label);
            labelErrorField.find('label#label_tag').replaceWith(label);
        }
        return form.find("label.message[for='" + (element.attr('id')) + "']").text(message);
    },

    remove: function(element, settings) {
        // custom remove code here
        var errorFieldClass, form, inputErrorField, label, labelErrorField;
        form = $(element[0].form);
        errorFieldClass = jQuery(settings.input_tag).attr('class');
        inputErrorField = element.closest("." + (errorFieldClass.replace(/\ /g, ".")));
        label = form.find("label[for='" + (element.attr('id')) + "']:not(.message)");
        labelErrorField = label.closest("." + errorFieldClass);
        $(element[0]).parent().removeClass("has-error")
        if (inputErrorField[0]) {
            inputErrorField.find("#" + (element.attr('id'))).detach();
            inputErrorField.replaceWith(element);
            label.detach();
            return labelErrorField.replaceWith(label);
        } else if($("#"+$(element[0]).attr("id")+"_error").length) {
            $("#"+$(element[0]).attr("id")+"_error").html("")
        }
    }
}
