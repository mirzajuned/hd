class CommonHelper::RubyStrings

  def self.if_nil_return_empty(str)
    str.nil? ? "" : str
  end

end
