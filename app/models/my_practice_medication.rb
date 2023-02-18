class MyPracticeMedication
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  has_many :my_practice_medication_lists
  accepts_nested_attributes_for :my_practice_medication_lists, reject_if: proc { |attributes| attributes['name'].blank? }

  def initialize_nested_objects
    10.times do
      self.my_practice_medication_lists.build
    end
  end
end
