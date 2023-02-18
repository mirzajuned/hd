module DepartmentsDropdownHelper
  def self.create(specialty_id, user, facility_id)
    role_ids = user.role_ids
    departments_array = GetFacilities.current_facility_departments(facility_id)

    # Remove Dept. if patient is assigned to the Dept.
    if role_ids.include?(2822900478) || specialty_id != '309988001'
      departments_array.delete_if { |department| department[0] == '309935007' }
    end

    if role_ids.include?(387619007) || specialty_id != '309988001'
      departments_array.delete_if { |department| department[0] == '50121007' }
    end

    departments_array.delete_if { |department| department[0] == '284748001' } if role_ids.include?(46255001)
    departments_array.delete_if { |department| department[0] == '309964003' } if role_ids.include?(41904004)
    departments_array.delete_if { |department| department[0] == '261904005' } if role_ids.include?(159282002)
    departments_array.delete_if { |department| department[0] == '450368792' } if role_ids.exclude?(499992366)

    departments_array
  end
end
