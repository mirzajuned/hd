module Analytics::ClinicalData
  class CreateUpdateService
    def self.call(params, current_user_id, current_facility_id)
      params = JSON.parse(params)
      facility = Facility.find_by(id: current_facility_id)
      organisation_id = facility.try(:organisation_id)
      params["time_zone"] = facility.try(:time_zone)

      validate_params(params)
      # services for operational section graphs
      Analytics::Diagnosis::CreateUpdateService.call(params, current_user_id, current_facility_id, organisation_id)

      Analytics::Procedure::CreateUpdateService.call(params, current_user_id, current_facility_id, organisation_id)

      Analytics::Investigations::CreateUpdateService.call(params, current_user_id, current_facility_id, organisation_id)

      # services for clinical section graphs
      Analytics::Diagnosis::ClinicalSection.call(params, current_user_id, current_facility_id, organisation_id)

      Analytics::Procedure::ClinicalSection.call(params, current_user_id, current_facility_id, organisation_id)

      Analytics::Investigations::ClinicalSection.call(params, current_user_id, current_facility_id, organisation_id)
    end

    private

    def self.validate_params(params)
      params["before_save_patient_age"] = "" if !params.has_key?("before_save_patient_age")
      params["before_save_patient_gender"] = "" if !params.has_key?("before_save_patient_gender")
      params["before_save_diagnosis"] = [] if !params.has_key?("before_save_diagnosis")
      params["before_save_procedure"] = [] if !params.has_key?("before_save_procedure")
      params["before_save_ophthal_investigations"] = [] if !params.has_key?("before_save_ophthal_investigations")
      params["before_save_radiology_investigations"] = [] if !params.has_key?("before_save_radiology_investigations")
      params["before_save_laboratory_investigations"] = [] if !params.has_key?("before_save_laboratory_investigations")

      params["after_save_patient_age"] = "" if !params.has_key?("after_save_patient_age")
      params["after_save_patient_gender"] = "" if !params.has_key?("after_save_patient_gender")
      params["after_save_diagnosis"] = [] if !params.has_key?("after_save_diagnosis")
      params["after_save_procedure"] = [] if !params.has_key?("after_save_procedure")
      params["after_save_ophthal_investigations"] = [] if !params.has_key?("after_save_ophthal_investigations")
      params["after_save_radiology_investigations"] = [] if !params.has_key?("after_save_radiology_investigations")
      params["after_save_laboratory_investigations"] = [] if !params.has_key?("after_save_laboratory_investigations")
    end
  end
end
