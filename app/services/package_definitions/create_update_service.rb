class PackageDefinitions::CreateUpdateService
  class << self
    def call(params)
      if params[:id].present?
        package_definition = PackageDefinition.find_by(id: params[:id])
        package_definition.update_attributes!(package_definition_params(params))
      else
        package_definition = PackageDefinition.new(package_definition_params(params))
        package_definition.save!
      end
    end

    private

    def package_definition_params(params)
      params.permit(:id, :organisation_id, :facility_id, :specialty_id, :sub_specialty_id, :department_id, :user_id,
                    :name, :display_name, :room_type, :service_group_id, :service_sub_group_id, :valid_from,
                    :valid_till, :service_type, :service_type_code_name, :service_type_code, :package_group_id)
    end
  end
end
