class TranslatedDiagnosis::UpdateService
  def self.call(params, icd_id)
    translated_icd_diagnosis = TranslatedIcdDiagnosis.find_by(id: icd_id)
    params[:abbrevated_name] = params[:fullname].tr(',', ' ').delete(' ')
    translated_icd_diagnosis.update_attributes(fullname: params[:fullname], abbrevated_name: params[:abbrevated_name])
  end
end
