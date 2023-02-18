class NephrologyOpdRecord
  attr_reader :opdrecord, :templatetype

  def initialize(opdrecord, templatetype)
    @opdrecord = opdrecord
    @templatetype = templatetype
  end

  def initialize_nested_objects
    1.times do
      opdrecord.build_advice
    end
  end
end
