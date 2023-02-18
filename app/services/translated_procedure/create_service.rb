class TranslatedProcedure::CreateService
  def self.call(params, current_user)
    @translated_new_procedure_name_field_hash = params[:name]
    @translated_new_procedure_name_field_hash.each do |_key, value|
      @procedure = TranslatedCommonProcedure.find_by(code: params[:code], organisation_id: params[:organisation_id])
      if @procedure.present?
        @procedure.update!(name: value, is_deleted: false)
      else
        new_procedure_params(params, value, current_user)
        @procedure = TranslatedCommonProcedure.new(translated_procedure_params(params))
        @procedure.save
      end
    end

    @procedure
  end

  private

  def self.new_procedure_params(params, value, current_user)
    params[:code] = params[:code]
    params[:common_procedure_code] = CommonHelper::get_translated_procedure_identifier(current_user)
    params[:name] = value
    params[:display_name] = value
    attach_procedure = CommonProcedure.find_by(code: params[:code]) || CustomCommonProcedure.find_by(code: params[:code], organisation_id: current_user.try(:organisation_id).to_s)
    params[:region] = attach_procedure.region
    params[:has_laterality] = attach_procedure.has_laterality
    params[:laterality] = attach_procedure.laterality
    params[:original_name] = attach_procedure.name
  end

  def self.translated_procedure_params(params)
    params.permit!
  end
end
