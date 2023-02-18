class Inventory::Item::MedicineClassName
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :medicine_name, type: String
  field :medicine_class_id, type: String

  embedded_in :item, class_name: '::Inventory::Item'
  embedded_in :variant, class_name: '::Inventory::Item::Variant'
  embedded_in :my_practice_medication_list, class_name: '::MyPracticeMedicationList'
end
