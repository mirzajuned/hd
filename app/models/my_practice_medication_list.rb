class MyPracticeMedicationList
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :med_type, type: String
  field :contents, type: String
  field :level, type: String
  field :is_migrated, type: Boolean, default: true
  field :is_uploaded, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false
  field :code, type: String
  field :generic_display_name, type: String
  field :generic_display_ids, type: Array, default: []

  belongs_to :user, index: { background: true }
  belongs_to :organisation, index: { background: true }
  belongs_to :facility, index: { background: true }

  embeds_many :generic_names, class_name: 'Inventory::Item::GenericName'
  embeds_many :medicine_class_name, class_name: 'Inventory::Item::MedicineClassName'

  accepts_nested_attributes_for :generic_names,
                                reject_if: proc { |attributes| attributes['name'].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :medicine_class_name,
                                reject_if: proc { |attributes| attributes['medicine_class_id'].blank? },
                                allow_destroy: true

  index({ name: 1 }, { background: true })

  before_save do
    self.generic_display_ids = self.generic_names.pluck(:generic_id)
    self.generic_display_name = self.contents
  end

  DISPENSING_UNIT = [
    ['Tablets','Tablets'],['Capsules','Capsules'],['Sachets','Sachets'],['Syrups','Syrups'],
    ['Spray','Spray'],['Powder','Powder'],['Eyedrops','Eyedrops'],['Vaccines','Vaccines'],
    ['Ointment','Ointment'],['Granules','Granules'],['Inhalers','Inhalers'],['Rotacaps','Rotacaps'],
    ['Oraldrops','Oraldrops'],['Eardrops','Eardrops'],['Cream','Cream'],['Aerosols','Aerosols'],
    ['Cartridges','Cartridges'],['Gel','Gel'],['Enema','Enema'],['Suppository','Suppository'],
    ['Pessary','Pessary'],['Lotion','Lotion'],['Nosedrops','Nosedrops'],['Solution','Solution'],
    ['Suspension','Suspension'],['Injectable','Injectable'], ['Liquid', 'Liquid']
  ]
end
