class DownloadUserService
  class << self
    def call(organisation_id)
      @data_array = []
      users_data(organisation_id)

      @data_array
    end

    def user_download_data(organisation_id)
      @data_array = []
      user_wise_data(organisation_id)

      @data_array
    end

    private

    def users_data(organisation_id)
      options = { organisation_id: organisation_id }

      options = options.merge(is_active: true)


      facilities = Facility.where(options).order_by(name: 'asc')
      return if facilities.empty?

      facilities.each do |facility|
        next if facility.blank?
        facility_users = User.where(facility_ids: facility.id).order_by(fullname: 'asc')
        next if facility_users.empty?


        facility_name = facility.try(:name)

        facility_users.each do |user|
          user_name = user.try(:fullname)
          user_designation = user.try(:designation)
          user_email = user.try(:email)
          user_employee_id = user.try(:employee_id)
          user_state = user&.is_active? ? "Active" : "Inactive"
          @data_array << [facility_name, user_name, user_designation, user_email, user_employee_id, user_state]
        end
      end
    end

    def user_wise_data(organisation_id)
      options = { organisation_id: organisation_id }
      users = User.where(options).order_by(name: 'asc')
      users.each do |user|
        user_name = user.try(:fullname)
        user_designation = user.try(:designation)
        user_email = user.try(:email)
        user_employee_id = user.try(:employee_id)
        user_state = user&.is_active? ? "Active" : "Inactive"
        @data_array << [user_name, user_designation, user_email, user_employee_id, user_state]
      end
    end

  end
end
