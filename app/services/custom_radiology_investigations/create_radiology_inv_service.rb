class CustomRadiologyInvestigations::CreateRadiologyInvService
  def self.call(params, current_user)
    if params[:add_subtests]
      custom_rad_inv_params(params[:subtests_values])
      params[:panel_ids] = @code_array
      params[:panel_names] = @panel_names_array
    end

    params[:loinc_code] = CommonHelper::get_custom_radiology_investigation_identifier(current_user)
    @custom_rad_inv = CustomRadiologyInvestigation.new(custom_rad_params(params))
    @custom_rad_inv.save
  end

  private

  def self.custom_rad_inv_params(params)
    @subtests_value = params
    @code_array = []
    @panel_names_array = []
    @subtests_value.each do |key, value|
      @code_array << value["loinc_code"]
      @panel_names_array << value["investigation_name"]
    end
  end

  def self.custom_rad_params(params)
    params.permit(:investigation_name, :loinc_code, :organisation_id, :normal_range, :loinc_class, :short_name, :test_type, :specialty_id, :investigation_id, :department_id, :add_subtests, :panel_ids => [], :panel_names => [])
  end
end
