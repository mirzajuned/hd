class CommonHelper::RubyHashes

  def self.hash_to_obj(hash)
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v)
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
    end
  end

  def self.hash_to_obj_struct(hash)
    obj = OpenStruct.new(hash) # obj = OpenStruct.new({name: "Max", age: "40"})
    return obj # obj.name or obj.age
  end

end
