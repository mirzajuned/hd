class OphthalmologyOpdRecord
  attr_reader :opdrecord, :templatetype

  def initialize(opdrecord, templatetype)
    @opdrecord = opdrecord
    @templatetype = templatetype
  end

  def initialize_nested_objects
    if (templatetype == "eye")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "vision")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "express")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "quickeye")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "freeform")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "pmt")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "postop")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "paediatrics")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "lens")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "trauma")
      1.times do
        opdrecord.build_advice
      end
    elsif (templatetype == "orthoptics")
      1.times do
        opdrecord.build_advice
      end
    end
  end
end
