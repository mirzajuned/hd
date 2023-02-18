class IpdRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  embeds_many :treatmentmedication, class_name: "::MedicationRecord" # medications
  embeds_many :ophthal_investigations_list, class_name: "::OphthalmologyInvestigation" # OphthalmologyInvestigation
  embeds_many :radiology_investigations_list, class_name: "::RadiologyInvestigation" # rads
  embeds_many :laboratory_investigations_list, class_name: "::Inpatient::LaboratoryInvestigation" # labs

  accepts_nested_attributes_for :ophthal_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :radiology_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :laboratory_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  # embeds_many :ot_inventory_item, class_name: "::OtInventoryItem"

  # accepts_nested_attributes_for :ot_inventory_item, reject_if: proc { |attributes| attributes['description'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :treatmentmedication, reject_if: proc { |attributes| attributes['medicinename'].blank? }, allow_destroy: true # medications

  def compute_medication_stop_duration(duration, durationoption)
    if durationoption == "D"
      return (Date.current + ("#{duration}".to_f).day)
    elsif durationoption == "W"
      return (Date.current + ("#{duration}".to_f).week)
    elsif durationoption == "M"
      return (Date.current + ("#{duration}".to_i).month)
    end
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end
end
