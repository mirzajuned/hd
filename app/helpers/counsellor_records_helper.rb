module CounsellorRecordsHelper
  def self.get_boolean(value)
    if ["true", true].include? value
      output = true
    elsif ["false", false].include? value
      output = false
    else
      output = nil
    end
    return output
  end
end
