class Role
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :label, type: String
  field :name, type: String
  field :code, type: Integer

  has_and_belongs_to_many :users
  belongs_to :resource, polymorphic: true, optional: true

  scopify

  before_destroy :cancel

  def cancel
    false
  end
end
