require 'nokogiri'
class HgRadioButtonInput < SimpleForm::Inputs::CollectionRadioButtonsInput
  def input(_wrapper_options)
    label_method, value_method = detect_collection_methods
    wrapper_html = options[:wrapper_html]
    options[:wrapper_html] = nil
    options[:as] = :hidden
    options[:input_html][:value] = options[:checked] if options[:checked].present?

    hidden_input = @builder.input(attribute_name, options)
    hidden_html = Nokogiri::HTML(hidden_input)
    options[:wrapper_html] = wrapper_html
    out = '<div class="btn-group" target-input-id="' + hidden_html.xpath('//input/@id').first.value + '">'
    collection.each do |item|
      value = item.send(value_method)
      label = item.send(label_method)
      active = ''
      active = ' btn-brown' unless out =~ / btn-brown/ || value != input_options[:checked]
      input_html_options[:value] = value unless active.empty?
      btn = input_options[:class] + ' custom-radio-button'
      out << <<-HTML
          <button type="button" input-value="#{value}" class="#{btn} #{active}"name="#{attribute_name}">#{label}</button>
      HTML
    end
    out << '</div>'
    out << hidden_input
    out.html_safe
  end
end
