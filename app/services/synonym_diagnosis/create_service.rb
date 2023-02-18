class SynonymDiagnosis::CreateService
  def self.call(params)
    @synonym_new_diagnosis_name_field_hash = params[:fullname]

    @synonym_new_diagnosis_name_field_hash.each do |key, value|
      new_diagnosis_params(params, value)

      @icd_diagnosis = SynonymIcdDiagnosis.new(synonym_diagnosis_params(params))
      @icd_diagnosis.save
    end

    return @icd_diagnosis
  end

  private

  def self.new_diagnosis_params(params, value)
    params[:fullname] = value
    params[:abbrevated_name] = value.gsub(',', ' ').gsub(' ', '')
  end

  def self.synonym_diagnosis_params(params)
    params.permit!
  end
end
