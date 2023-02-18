class SynonymProcedure::CreateService
  def self.call(params)
    @synonym_new_procedure_name_field_hash = params[:name]

    @synonym_new_procedure_name_field_hash.each do |key, value|
      new_procedure_params(params, value)
      @procedure = SynonymCommonProcedure.new(synonym_procedure_params(params))
      @procedure.save
    end

    return @procedure
  end

  private

  def self.new_procedure_params(params, value)
    params[:name] = value
    @procedure_type = params[:procedure_type]
    @attach_procedure = eval(@procedure_type).find_by(code: params[:code])
    params[:region] = @attach_procedure.region
  end

  def self.synonym_procedure_params(params)
    params.permit!
  end
end
