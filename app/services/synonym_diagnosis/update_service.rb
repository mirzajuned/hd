class SynonymDiagnosis::UpdateService
  def self.call(params, icd_id)
    synonym_icd_diagnosis = SynonymIcdDiagnosis.find_by(id: icd_id)
    params[:abbrevated_name] = params[:fullname].gsub(',', ' ').gsub(' ', '')
    synonym_icd_diagnosis.update_attributes(fullname: params[:fullname], abbrevated_name: params[:abbrevated_name])
  end
end
