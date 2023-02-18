class Inventory::Item::GenericName
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :quantity, type: Float
  field :unit, type: String
  field :generic_id, type: String
  field :full_name, type: String
  field :medicine_from, type: String

  embedded_in :item, class_name: '::Inventory::Item'
  embedded_in :variant, class_name: '::Inventory::Item::Variant'
  embedded_in :my_practice_medication_list, class_name: '::MyPracticeMedicationList'
end
