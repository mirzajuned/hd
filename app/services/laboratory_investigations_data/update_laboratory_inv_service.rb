class LaboratoryInvestigationsData::UpdateLaboratoryInvService
  def self.call(inv_id, params, current_user)
    if params[:has_sub_tests] == 'true' && params[:subtests_values].present?
      custom_lab_inv_params(params[:subtests_values])
    else
      @panel_data_array = []
    end

    params[:panel_ids] = @panel_data_array
    @organisation_id = params[:organisation_id]
    @facilities = Organisation.find_by(id: @organisation_id).facilities.pluck(:id)
    @investigations = LaboratoryInvestigationData.where(loinc_code: params[:loinc_code], :facility_id.in => @facilities)
    @investigations.each do |investigation|
      investigation.update(custom_lab_params(params))
    end
  end

  private

  def self.custom_lab_inv_params(params)
    @subtests_value = params
    @panel_data_array = []
    @subtests_value.each do |key, value|
      code = value["loinc_code"]
      @panel_data_array.push(code)
    end
  end

  def self.custom_lab_params(params)
    params.permit(:investigation_name, :loinc_code, :organisation_id, :facility_id, :created_by, :normal_range, :loinc_class, :short_name, :test_type, :specialty_id, :investigation_id, :department_id, :has_sub_tests, :is_custom, :only_sub_test, :panel_ids => [])
  end
end
