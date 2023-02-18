module NursingRecordHelper
  def self.object_finder(type, val)
    nursing_yml = Global.nursing
    val = nursing_yml[type][val.to_s]
    return val
  end
end
