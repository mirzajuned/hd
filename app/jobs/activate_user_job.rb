class ActivateUserJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    organisation = Organisation.find_by(:id => args[0])
    organisation.users.each do |user|
      if !user.is_active
        UserMailer.activate_user_account(user).deliver_now
        user.update_attributes(is_active: true)
        # facility_id = user.facility_ids[0]
        # inventory_departments = Inventory::Department.where(facility_id: facility_id)
        # inventory_departments.each do |inventory_department|
        #   user.inventories.create(current: false,department_id: inventory_department.department_id)
        # end
      end
    end
  end
end
