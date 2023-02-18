module OfferMangerHelper
  def self.get_number_format(current_facility, current_organisation)
    number_format = current_facility['number_format'] || current_organisation['number_format'] || 0
  end
end