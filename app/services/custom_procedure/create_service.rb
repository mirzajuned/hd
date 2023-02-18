class CustomProcedure::CreateService
  def self.call(params, current_user)
    new_procedure_params(params, current_user)
    @procedure = CustomCommonProcedure.new(custom_common_create_params(params))
    @procedure.save

    return @procedure
  end

  private

  def self.new_procedure_params(params, current_user)
    params[:code] = CommonHelper::get_common_procedure_identifier(current_user)
    @laterality = [{ side_name: 'Bilateral', side_id: '40638003' }, { side_name: 'Right', side_id: '18944008' }, { side_name: 'Left', side_id: '8966001' }]
    params[:laterality] = (@laterality if params[:has_laterality] == 'true') || []
  end

  def self.custom_common_create_params(params)
    params.permit!
  end
end
