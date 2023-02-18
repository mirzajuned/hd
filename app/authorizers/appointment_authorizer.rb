class AppointmentAuthorizer < ApplicationAuthorizer
  # Class methods -- define here, below this

  def self.creatable_by?(user)
    user.role_ids.any? { |ele| [158965000, 159561009, 106292003, 405277009].include?(ele) }
  end

  def self.manageable_by?(user)
    user.role_ids.any? { |ele| [158965000, 28229004].include?(ele) }
  end

  def self.printable_by?(user)
    user.role_ids.any? { |ele| [158965000, 159561009].include?(ele) }
  end

  def self.updatable_by?(user)
    user.role_ids.any? { |ele| [158965000, 159561009].include?(ele) }
  end

  def self.deletable_by?(user)
    user.role_ids.any? { |ele| [158965000, 159561009].include?(ele) }
  end

  # Class methods -- ends here
  # -----------------------------------------------------

  # Instance methods -- define here, below this

  def manageable_by?(user)
    user.role_ids.any? { |ele| [158965000, 28229004].include?(ele) }
  end

  # Instance methods -- ends here
  # -----------------------------------------------------

  # Other methods -- define here, below this

  # Other methods -- ends here
  # -----------------------------------------------------
end
