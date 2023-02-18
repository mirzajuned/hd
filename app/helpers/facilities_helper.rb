module FacilitiesHelper
  def get_facility_users_roles(facility_ids, organisation_id)
    all_roles = JSON.parse(Global.send("user_roles").to_json)
    final_roles_arr = []

    facility_ids.each do |facility_id|
      users_roles = User.collection.aggregate(
        [
          { "$match" => { "organisation_id" => BSON::ObjectId("#{organisation_id}"), "facility_ids" => { "$in" => [facility_id, "$facility_ids"] } } },
          { "$unwind" => "$role_ids" },
          { "$group" => { "_id" => "$role_ids" } }
        ]
      ).to_a

      roles_map_arr = []
      role_ids = users_roles.pluck("_id")
      role_ids.each_with_index do |role, i|
        found_role = all_roles.select { |ele| ele == role.to_s }
        roles_map_arr << { name: found_role.values[0]["label"], role_id: role } if found_role.present?
      end
      final_roles_arr << { "#{facility_id}" => roles_map_arr }
    end

    return final_roles_arr
  end

  def get_roles_name(organisation_id)
    all_roles = Global.send("user_roles").to_hash
    final_hash = {}

    users_roles = User.collection.aggregate(
      [
        { "$match" => { "organisation_id" => BSON::ObjectId(organisation_id) } },
        { "$unwind" => "$facility_ids" },
        { "$group" => { "_id" => "$facility_ids", "role_ids" => { "$addToSet" => "$role_ids" } } },
      ]
    ).to_a

    users_roles.each do |u|
      role_ids = u["role_ids"].flatten.map(&:to_s)
      role_names = all_roles.select { |role| role_ids.include?(role.to_s) }

      final_hash[u["_id"].to_s] = role_names
    end

    return final_hash
  end

  def enable_qm_settings
    accessible_time = Time.current.between?(Time.zone.parse('21:00'), Time.zone.parse('23:59:59'))
    non_production_environment = !(Rails.env.production? || Rails.env.preproduction?)

    params[:action] == 'new' || accessible_time || non_production_environment
  end
end
