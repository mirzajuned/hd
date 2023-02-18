class LaboratoryInvestigationsData::CreateLaboratoryInvService
  def self.call(params, current_user)
    if params[:has_sub_tests] == 'true'
      custom_lab_inv_params(params[:subtests_values])
    elsif params[:only_sub_test] == 'false'
      @panel_data_array = []
    end
    params[:is_custom] = true
    params[:loinc_code] = CommonHelper::get_custom_laboratory_investigation_identifier(current_user)
    params[:investigation_id] = CommonHelper::get_custom_laboratory_id_investigation_identifier(current_user)
    @facilities = Facility.where(organisation_id: params[:organisation_id])

    @facilities.each do |fac|
      @custom_lab_inv = LaboratoryInvestigationData.new(custom_lab_params(params))
      @custom_lab_inv.panel_ids = @panel_data_array
      @custom_lab_inv.facility_id = fac.id
      @custom_lab_inv.level = 'facility'
      @custom_lab_inv.save
    end
  end

  private

  def self.custom_lab_inv_params(params)
    @subtests_value = params
    @panel_data_array = []
    @subtests_value.each do |key, value|
      code = value["loinc_code"]
      @panel_data_array << code
    end
  end

  def self.custom_lab_params(params)
    params.permit(:investigation_name, :loinc_code, :organisation_id, :facility_id, :level, :created_by, :normal_range, :loinc_class, :short_name, :test_type, :specialty_id, :investigation_id, :department_id, :has_sub_tests, :is_custom, :only_sub_test)
  end
end
