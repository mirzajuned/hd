module MethodMissing
  def method_missing(name, *args)
    name_reader = name.to_s.reader
    super unless name_reader.present?

    if name.to_s.writer?
      define_dynamic_writer(name_reader)
      write_attribute(name_reader, args.first)
    else
      define_dynamic_reader(name_reader)
      attribute_will_change!(name_reader)
      read_attribute(name_reader)
    end
  end

  def respond_to_missing?(name, _include_private); end

  # Old MethodMissing Code
  # def method_missing(name, *args)
  #   attr = name.to_s
  #   if attr.writer?
  #     getter = attr.reader
  #     define_dynamic_writer(getter)
  #     write_attribute(getter, args.first)
  #   elsif attr.before_type_cast?
  #     define_dynamic_before_type_cast_reader(attr.reader)
  #     attribute_will_change!(attr.reader)
  #     read_attribute_before_type_cast(attr.reader)
  #   else
  #     getter = attr.reader
  #     define_dynamic_reader(getter)
  #     attribute_will_change!(attr.reader)
  #     read_attribute(getter)
  #   end
  # end

  # def method_missing(name)
  #   self.send(:read_attribute, name)
  # end
end
