class OpdRecordAuthorizer < ApplicationAuthorizer
  # Class methods -- define here, below this

  # def signoff_opdrecord_by?(user)
  #   user.has_role? :doctor
  # end

  # Class methods -- ends here
  # -----------------------------------------------------

  # Instance methods -- define here, below this

  def signoff_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def unlock_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def edit_oprecord_by?(user)
    user.has_role? :doctor
  end

  def delete_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def create_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def update_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def print_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def email_pdf_opdrecord_by?(user)
    user.has_role? :doctor
  end

  def lock_opdrecord_by?(user)
    user.has_role? :doctor
  end

  # Instance methods -- ends here
  # -----------------------------------------------------

  # Other methods -- define here, below this

  # Other methods -- ends here
  # -----------------------------------------------------
end
