module UsersDropdownHelper
  class << self
    def create_opd(specialty_id, facility_id, facility_setting)
      if facility_setting&.queue_management
        sub_stations = QueueManagement::SubStation.where(facility_id: facility_id, is_deleted: false)
        sub_station_users = if facility_setting&.user_set_station
                              sub_stations.pluck(:active_user_id).uniq
                            else
                              sub_stations.pluck(:user_id).uniq
                            end
        user_roles = User.where(:id.in => sub_station_users, facility_ids: facility_id.to_s)
                         .pluck(:role_ids).flatten.uniq
      else
        user_roles = User.where(facility_ids: facility_id.to_s).pluck(:role_ids).flatten.uniq
      end

      get_dropdown_users(specialty_id, facility_id, user_roles, 'opd')
    end

    def create_ipd(specialty_id, facility_id)
      user_roles = User.where(facility_ids: facility_id.to_s).pluck(:role_ids).flatten.uniq

      get_dropdown_users(specialty_id, facility_id, user_roles, 'ipd')
    end

    def consultant_frozen(appointment, details)
      new_details = []
      details.each do |detail|
        new_details << detail if detail[0] == appointment.consultant_id.to_s
      end

      new_details
    end

    private

    def get_dropdown_users(specialty_id, facility_id, user_roles, department)
      specialty_ids = [specialty_id]
      dropdown_users = {}
      dropdown_roles = get_dropdown_roles(department)
      dropdown_roles.each do |role|
        if user_roles.include?(role[0].to_i)
          users = GetUsers.workflow_users_dropdown(facility_id.to_s, specialty_ids, role[0])
          dropdown_users[role[1]] = users if users.present?
        end
      end

      dropdown_users
    end

    def get_dropdown_roles(department)
      if department == 'opd'
        [['159561009', 'receptionist'], ['28229004', 'optometrist'], ['158965000', 'doctor'], ['106292003', 'nurse'],
         ['499992366', 'counsellor'], ['59561000', 'floormanager'], ['28221005', 'ar_nct'], ['159562000', 'cashier'],
         ['46255001', 'pharmacist'], ['387619007', 'optician'], ['41904004', 'radiologist'], ['573021946', 'tpa'],
         ['159282002', 'technician'], ['2822900478', 'ophthalmology_technician']]
      elsif department == 'ipd'
        [['159561009', 'receptionist'], ['106292003', 'nurse'], ['158965000', 'doctor'],
         ['499992366', 'counsellor'], ['573021946', 'tpa']]
      end
    end
  end
end
