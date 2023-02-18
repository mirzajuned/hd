module UsersHelper
  def self.get_user_roles_names(role_ids)
    role_array = []
    all_roles = JSON.parse(Global.send("user_roles").to_json)
    role_ids.each do |role_id|
      role_name = all_roles.select { |ele| ele == role_id.to_s }
      if role_name.present?
        name = role_name.values[0]["name"]

        if role_array.any? { |i| ["admin", "owner"].include?(i) }
          role_array.unshift(name)
        else
          role_array << name
        end
      end
    end

    return role_array.join(',')
  end

  def self.get_primary_role(role_ids)
    all_roles = JSON.parse(Global.send("user_roles").to_json)

    if role_ids.count > 1
      if role_ids.include?(158965000)
        role = 'doctor'
      end
    else
      role = all_roles.select { |ele| ele == role_ids[0].to_s }.values[0]["name"]
    end
  end
end
