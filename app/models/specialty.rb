class Specialty
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :is_launched, type: Boolean, default: false

  has_many :sub_specialties

  validates_presence_of :name

  def underscored_name
    name
      .downcase
      .tr(' ', '_')
      .gsub('_and_', '_') # for 'Obstetrics and Gynecology'
  end
end
