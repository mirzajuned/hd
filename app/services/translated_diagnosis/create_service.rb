class TranslatedDiagnosis::CreateService
  class << self
    def call(params, current_user)
      @translated_new_diagnosis_name_field_hash = params[:data]
      @translated_new_diagnosis_name_field_hash.each do |_key, value|
        @icd_diagnosis = TranslatedIcdDiagnosis.find_by(code: value[:code], organisation_id: params[:organisation_id])
        if @icd_diagnosis.present?
          @icd_diagnosis.update!(fullname: value[:fullname], abbrevated_name: value[:fullname], is_deleted: false)
        else
          icd_diagnosis = IcdDiagnosis.find_by(code: value[:code]) || CustomIcdDiagnosis.find_by(code: value[:code])
          diagnosis_params(icd_diagnosis, params, value, current_user)
        end
      end

      @icd_diagnosis
    end

    private

    def diagnosis_params(icd_diagnosis, params, value, current_user)
      diagnosis_hash = icd_diagnosis.attributes.to_h
      diagnosis_data = diagnosis_hash.except('_id', 'updated_at', 'created_at', 'is_deleted', 'fullname', 'icd_type')
      diagnosis_data[:translated_icd_code] = CommonHelper.get_translated_icd_identifier(current_user)
      diagnosis_data[:fullname] = value[:fullname]
      diagnosis_data[:abbrevated_name] = value[:fullname].tr(',', ' ').delete(' ')
      diagnosis_data[:organisation_id] = params[:organisation_id]
      diagnosis_data[:translated_language] = params[:translated_language]
      diagnosis_data[:search_icd_name] = params[:search_icd_name]
      diagnosis_data[:specialty_id] = params[:specialty_id]
      diagnosis_data[:facility_ids] = params[:facility_ids]
      icd_diagnosis = TranslatedIcdDiagnosis.new(diagnosis_data)
      icd_diagnosis.save
    end
  end
end
