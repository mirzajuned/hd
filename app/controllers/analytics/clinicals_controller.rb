# rubocop:disable all
class Analytics::ClinicalsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :set_user_facility
  before_action :get_analytics_filters
  before_action :date_query_creator
  before_action :set_params_hash

  def index
    @total_diagnosis, @total_procedure, @total_ophthal_investigations_list, @total_laboratory_investigations_list, @total_radiology_investigations_list = Analytics::PartialData::ClinicalOverview.total_diagnosis_count(@params_hash)
    @top_ten_diagnosis_labels, @top_ten_diagnosis_data = Analytics::PartialData::DiagnosisData.top_ten_diagnoses(@params_hash)

    # procedure
    @top_ten_procedure_labels, @top_ten_procedure_data = Analytics::PartialData::ProcedureData.top_ten_procedures(@params_hash)

    # Investigation
    @top_ten_laboratory_labels, @top_ten_laboratory_data = Analytics::PartialData::InvestigationsData.top_ten_laboratory_investigations(@params_hash)
    @top_ten_radiology_labels, @top_ten_radiology_data = Analytics::PartialData::InvestigationsData.top_ten_radiology_investigations(@params_hash)
    @top_ten_ophthal_labels, @top_ten_ophthal_data = Analytics::PartialData::InvestigationsData.top_ten_ophthal_investigations(@params_hash)
    @laboratory_investigation_label, @laboratory_investigation_data = Analytics::PartialData::InvestigationsData.laboratory_investigation_data(@params_hash)
  end

  def patient
    disease = params[:disease_value].present? ? params[:disease_value] : 'diabetes'

    @patient_history_label, @patient_history_data, @disease = Analytics::PartialData::PatientsHistoryData.call(@params_hash.merge('disease' => disease))

    allergy = params[:allergy_value].present? ? params[:allergy_value] : 'tropicamide_p'

    @patient_allergy_label, @patient_allergy_data, @allergy = Analytics::PartialData::PatientsAllergyData.call(@params_hash.merge('allergy' => allergy))

    @top5_history_label, @top5_history_data = Analytics::PartialData::PatientsHistoryData.top_five_disease_history(@params_hash)

    @top5_allergy_label, @top5_allergy_data = Analytics::PartialData::PatientsAllergyData.top_five_allergy_history(@params_hash)

    @all_history_label, @all_history_data = Analytics::PartialData::PatientsHistoryData.all_history_data(@params_hash)

    @all_allergy_label, @all_allergy_data = Analytics::PartialData::PatientsAllergyData.all_allergy_data(@params_hash)
  end

  def patient_history_data
    disease = params[:disease_value].present? ? params[:disease_value] : 'diabetes'
    check_partial
    @patient_history_label, @patient_history_data, @disease = Analytics::PartialData::PatientsHistoryData.call(@params_hash.merge('disease' => disease))
  end

  def patient_allergy_data
    allergy = params[:allergy_value].present? ? params[:allergy_value] : 'tropicamide_p'
    check_partial
    @patient_allergy_label, @patient_allergy_data, @allergy = Analytics::PartialData::PatientsAllergyData.call(@params_hash.merge('allergy' => allergy))
  end

  def diagnosis
    @selected_diagnosis = params[:diagnosis_value]

    @top_ten_diagnosis_labels, @top_ten_diagnosis_data = Analytics::PartialData::DiagnosisData.top_ten_diagnoses(@params_hash)

    @commonly_used_diagnosis_labels, @commonly_used_diagnosis_data = Analytics::PartialData::DiagnosisData.commonly_used_diagnosis(@params_hash.merge('diagnosis' => @selected_diagnosis))

    @age_wise_diagnosis_labels, @age_wise_diagnosis_data = Analytics::PartialData::DiagnosisData.get_age_wise_diagnosis_data(@params_hash.merge('diagnosis' => @selected_diagnosis))

    @facility_wise_diagnosis_labels, @facility_wise_diagnosis_data = Analytics::PartialData::DiagnosisData.get_facility_wise_diagnosis_data(@params_hash)
  end

  def get_commonly_used_diagnosis_data
    @selected_diagnosis = params[:diagnosis_value]
    @commonly_used_diagnosis_labels, @commonly_used_diagnosis_data = Analytics::PartialData::DiagnosisData.commonly_used_diagnosis(@params_hash.merge('diagnosis' => @selected_diagnosis))
    check_partial
  end

  def get_age_wise_diagnosis_data
    @selected_diagnosis = params[:diagnosis_value]
    @age_wise_diagnosis_labels, @age_wise_diagnosis_data = Analytics::PartialData::DiagnosisData.get_age_wise_diagnosis_data(@params_hash.merge('diagnosis' => @selected_diagnosis))
    check_partial
  end

  def get_facility_wise_diagnosis_data
    @selected_diagnosis = params[:diagnosis_value]
    @facility_wise_diagnosis_labels, @facility_wise_diagnosis_data = Analytics::PartialData::DiagnosisData.get_facility_wise_diagnosis_data(@params_hash)
  end

  def procedure
    @top_ten_procedure_labels, @top_ten_procedure_data = Analytics::PartialData::ProcedureData.top_ten_procedures(@params_hash)

    @advised_procedure_labels, @advised_procedure_data = Analytics::PartialData::ProcedureData.get_advised_performed_procedures(@params_hash.merge('procedure' => @selected_procedure))

    @age_wise_procedures_labels, @age_wise_procedures_data = Analytics::PartialData::ProcedureData.get_age_wise_procedures_data(@params_hash.merge('region' => @selected_procedure))

    @facility_wise_procedures_labels, @facility_wise_procedures_data = Analytics::PartialData::ProcedureData.get_facility_wise_procedures(@params_hash)
  end

  def get_advised_performed_procedures
    @selected_procedure = params[:procedure_value]
    @advised_procedure_labels, @advised_procedure_data = Analytics::PartialData::ProcedureData.get_advised_performed_procedures(@params_hash.merge('procedure' => @selected_procedure))
    check_partial
  end

  def get_facility_wise_procedures
    @facility_wise_procedures_labels, @facility_wise_procedures_data = Analytics::PartialData::ProcedureData.get_facility_wise_procedures(@params_hash)
  end

  def get_age_wise_procedures_data
    @selected_procedure = params[:procedure_value]
    @age_wise_procedures_labels, @age_wise_procedures_data = Analytics::PartialData::ProcedureData.get_age_wise_procedures_data(@params_hash.merge('region' => @selected_procedure))
    check_partial
  end

  def investigation
    # FACILITY WISE INVESTIGATION SERVICES
    @facility_wise_ophthal_labels, @facility_wise_ophthal_data = Analytics::PartialData::InvestigationsData.facility_wise_ophthal_investigations(@params_hash)

    @facility_wise_laboratory_labels, @facility_wise_laboratory_data = Analytics::PartialData::InvestigationsData.facility_wise_laboratory_investigations(@params_hash)

    @facility_wise_radiology_labels, @facility_wise_radiology_data = Analytics::PartialData::InvestigationsData.facility_wise_radiology_investigations(@params_hash)

    # TOP 10 INVESTIGATIONS SERVICES
    @top_ten_ophthal_labels, @top_ten_ophthal_data = Analytics::PartialData::InvestigationsData.top_ten_ophthal_investigations(@params_hash)

    @top_ten_laboratory_labels, @top_ten_laboratory_data = Analytics::PartialData::InvestigationsData.top_ten_laboratory_investigations(@params_hash)

    @top_ten_radiology_labels, @top_ten_radiology_data = Analytics::PartialData::InvestigationsData.top_ten_radiology_investigations(@params_hash)

    # INVESTIGATIONS DATA
    @investigation_ophthal_label, @investigation_ophthal_data = Analytics::PartialData::InvestigationsData.ophthal_investigation_data(@params_hash.merge('region' => @selected_ophthal_region))

    @laboratory_investigation_label, @laboratory_investigation_data = Analytics::PartialData::InvestigationsData.laboratory_investigation_data(@params_hash)

    @radiology_investigation_label, @radiology_investigation_data = Analytics::PartialData::InvestigationsData.radiology_investigation_data(@params_hash)

    #  AGE WISE INVESTIGATIONS DATA
    @age_wise_ophthal_inv_labels, @age_wise_ophthal_inv_data = Analytics::PartialData::InvestigationsData.age_wise_ophthal_investigations(@params_hash.merge('region' => @selected_ophthal_region))

    @age_wise_laboratory_inv_labels, @age_wise_laboratory_inv_data = Analytics::PartialData::InvestigationsData.age_wise_laboratory_investigations(@params_hash)

    @age_wise_radiology_inv_labels, @age_wise_radiology_inv_data = Analytics::PartialData::InvestigationsData.age_wise_radiology_investigations(@params_hash)
  end

  def get_ophthal_investigations_list
    @selected_ophthal_region = params[:region]
    @investigation_ophthal_label, @investigation_ophthal_data = Analytics::PartialData::InvestigationsData.ophthal_investigation_data(@params_hash.merge('region' => @selected_ophthal_region))
    check_partial
  end

  def get_age_wise_ophthal_investigations_data
    @selected_age_wise_ophthal_region = params[:age_wise_ophthal_region]
    @age_wise_ophthal_inv_labels, @age_wise_ophthal_inv_data = Analytics::PartialData::InvestigationsData.age_wise_ophthal_investigations(@params_hash.merge('region' => @selected_age_wise_ophthal_region))
    check_partial
  end

  # doctor contains static data
  def doctor
    # FACILITY WISE INVESTIGATION SERVICES
    @facility_wise_ophthal_labels_doctor, @facility_wise_ophthal_data_doctor = Analytics::PartialData::DoctorData.facility_wise_doctor_ophthal_investigations(@params_hash)

    @facility_wise_laboratory_labels_doctor, @facility_wise_laboratory_data_doctor = Analytics::PartialData::DoctorData.facility_wise_doctor_laboratory_investigations(@params_hash)

    @facility_wise_radiology_labels_doctor, @facility_wise_radiology_data_doctor = Analytics::PartialData::DoctorData.facility_wise_doctor_radiology_investigations(@params_hash)

    # TOP 10 INVESTIGATIONS SERVICES
    @top_ten_ophthal_labels_doctor, @top_ten_ophthal_data_doctor = Analytics::PartialData::DoctorData.top_ten_doctor_ophthal_investigations(@params_hash)

    @top_ten_laboratory_labels_doctor, @top_ten_laboratory_data_doctor = Analytics::PartialData::DoctorData.top_ten_doctor_laboratory_investigations(@params_hash)

    @top_ten_radiology_labels_doctor, @top_ten_radiology_data_doctor = Analytics::PartialData::DoctorData.top_ten_doctor_radiology_investigations(@params_hash)

    # INVESTIGATIONS DATA
    @investigation_ophthal_label_doctor, @investigation_ophthal_data_doctor = Analytics::PartialData::DoctorData.ophthal_doctor_investigation_data(@params_hash.merge('region' => @selected_ophthal_region))

    @laboratory_investigation_label_doctor, @laboratory_investigation_data_doctor = Analytics::PartialData::DoctorData.laboratory_doctor_investigation_data(@params_hash)

    @radiology_investigation_label_doctor, @radiology_investigation_data_doctor = Analytics::PartialData::DoctorData.radiology_doctor_investigation_data(@params_hash)

    #  AGE WISE INVESTIGATIONS DATA
    @age_wise_ophthal_inv_labels_doctor, @age_wise_ophthal_inv_data_doctor = Analytics::PartialData::DoctorData.age_wise_doctor_ophthal_investigations(@params_hash.merge('region' => @selected_ophthal_region))

    @age_wise_laboratory_inv_labels_doctor, @age_wise_laboratory_inv_data_doctor = Analytics::PartialData::DoctorData.age_wise_doctor_laboratory_investigations(@params_hash)

    @age_wise_radiology_inv_labels_doctor, @age_wise_radiology_inv_data_doctor = Analytics::PartialData::DoctorData.age_wise_doctor_radiology_investigations(@params_hash)
  end

  # counsellor contains static data
  def counsellor
    # FACILITY WISE INVESTIGATION SERVICES
    @facility_wise_ophthal_labels_counsellor, @facility_wise_ophthal_data_counsellor = Analytics::PartialData::CounsellorData.facility_wise_counsellor_ophthal_investigations(@params_hash)

    @facility_wise_laboratory_labels_counsellor, @facility_wise_laboratory_data_counsellor = Analytics::PartialData::CounsellorData.facility_wise_counsellor_laboratory_investigations(@params_hash)

    @facility_wise_radiology_labels_counsellor, @facility_wise_radiology_data_counsellor = Analytics::PartialData::CounsellorData.facility_wise_counsellor_radiology_investigations(@params_hash)

    # TOP 10 INVESTIGATIONS SERVICES
    @top_ten_ophthal_labels_counsellor, @top_ten_ophthal_data_counsellor = Analytics::PartialData::CounsellorData.top_ten_counsellor_ophthal_investigations(@params_hash)

    @top_ten_laboratory_labels_counsellor, @top_ten_laboratory_data_counsellor = Analytics::PartialData::CounsellorData.top_ten_counsellor_laboratory_investigations(@params_hash)

    @top_ten_radiology_labels_counsellor, @top_ten_radiology_data_counsellor = Analytics::PartialData::CounsellorData.top_ten_counsellor_radiology_investigations(@params_hash)

    # INVESTIGATIONS DATA
    @investigation_ophthal_label_counsellor, @investigation_ophthal_data_counsellor = Analytics::PartialData::CounsellorData.ophthal_counsellor_investigation_data(@params_hash.merge('region' => @selected_ophthal_region))

    @laboratory_investigation_label_counsellor, @laboratory_investigation_data_counsellor = Analytics::PartialData::CounsellorData.laboratory_counsellor_investigation_data(@params_hash)

    @radiology_investigation_label_counsellor, @radiology_investigation_data_counsellor = Analytics::PartialData::CounsellorData.radiology_counsellor_investigation_data(@params_hash)

    #  AGE WISE INVESTIGATIONS DATA
    @age_wise_ophthal_inv_labels_counsellor, @age_wise_ophthal_inv_data_counsellor = Analytics::PartialData::CounsellorData.age_wise_counsellor_ophthal_investigations(@params_hash.merge('region' => @selected_ophthal_region))

    @age_wise_laboratory_inv_labels_counsellor, @age_wise_laboratory_inv_data_counsellor = Analytics::PartialData::CounsellorData.age_wise_counsellor_laboratory_investigations(@params_hash)

    @age_wise_radiology_inv_labels_counsellor, @age_wise_radiology_inv_data_counsellor = Analytics::PartialData::CounsellorData.age_wise_counsellor_radiology_investigations(@params_hash)
  end

  def get_age_wise_counsellor_ophthal_investigations_data
    @selected_age_wise_ophthal_region = params[:age_wise_ophthal_region]
    @age_wise_ophthal_inv_labels_counsellor, @age_wise_ophthal_inv_data_counsellor = Analytics::PartialData::CounsellorData.age_wise_counsellor_ophthal_investigations(@params_hash.merge('region' => @selected_age_wise_ophthal_region))
    check_partial
  end

  def get_age_wise_doctor_ophthal_investigations_data
    @selected_age_wise_ophthal_region = params[:age_wise_ophthal_region]
    @age_wise_ophthal_inv_labels_doctor, @age_wise_ophthal_inv_data_doctor = Analytics::PartialData::DoctorData.age_wise_doctor_ophthal_investigations(@params_hash.merge('region' => @selected_age_wise_ophthal_region))
    check_partial
  end

  def get_ophthal_counsellor_investigations_list
    @selected_ophthal_region = params[:region]
    @investigation_ophthal_label_counsellor, @investigation_ophthal_data_counsellor = Analytics::PartialData::CounsellorData.ophthal_counsellor_investigation_data(@params_hash.merge('region' => @selected_ophthal_region))
    check_partial
  end

  def get_ophthal_doctor_investigations_list
    @selected_ophthal_region = params[:region]
    @investigation_ophthal_label_doctor, @investigation_ophthal_data_doctor = Analytics::PartialData::DoctorData.ophthal_doctor_investigation_data(@params_hash.merge('region' => @selected_ophthal_region))
    check_partial
  end

  private

  def set_user_facility
    @current_facility = current_facility
    @current_user = current_user
  end

  def get_analytics_filters
    @facility_id = params[:filtered_facility].present? ? params[:filtered_facility] : current_facility.id
    @specialty_id = (params[:filtered_specialty] if params[:filtered_specialty].present?) || 'all'
    @analytics_to_date = params[:analytics_to_date].present? ? params[:analytics_to_date] : Date.current
    @analytics_from_date = params[:analytics_from_date].present? ? params[:analytics_from_date] : (Date.current - 7)
    @data_type = params[:data_type].present? ? params[:data_type] : 'day'
  end

  def set_params_hash
    @params_hash = {
      'organisation_id' => @current_facility.organisation_id,
      'facility_id' => @facility_id,
      'specialty_id' => @specialty_id,
      'analytics_to_date' => @analytics_to_date,
      'analytics_from_date' => @analytics_from_date,
      'data_type' => @data_type,
      'data_query' => @data_query,
      'label_on' => @label_on
    }
    # check if date is start and end dates are same

    @todays_data = true if @analytics_from_date == @analytics_to_date
  end

  def check_partial
    @partial_name = params[:partial_name] == 'true'
  end

  def date_query_creator
    from_date = @analytics_from_date
    to_date   = @analytics_to_date

    @data_query, @label_on = Analytics::AnalyticsDate::QueryGenerator.query_array_builder(to_date, from_date)
  end
end
