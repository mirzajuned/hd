class CustomOphthalInvestigations::UpdateOphthalInvService
  def self.call(inv_id, params, current_user)
    @investigation = CustomOphthalInvestigation.find_by(id: inv_id)
    if params[:add_subtests]
      custom_oph_inv_params(params[:subtests_values])
      params[:panel_ids] = @code_array
      params[:panel_names] = @panel_names_array
    elsif params[:add_subtests].nil?
      params[:add_subtests] = false
      params[:panel_ids] = []
      params[:panel_names] = []
    end

    @investigation = @investigation.update_attributes(custom_oph_update_params(params))
  end

  private

  def self.custom_oph_inv_params(params)
    @subtests_value = params
    @code_array = []
    @panel_names_array = []
    @subtests_value.each do |key, value|
      @code_array << value["loinc_code"]
      @panel_names_array << value["investigation_name"]
    end
  end

  def self.custom_oph_update_params(params)
    params.permit(:investigation_name, :normal_range, :add_subtests, :panel_ids => [], :panel_names => [])
  end
end
