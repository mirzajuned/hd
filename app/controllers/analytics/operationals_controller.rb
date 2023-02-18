class Analytics::OperationalsController < ApplicationController
  before_action :authorize
  before_action :set_user_facility
  before_action :get_analytics_filters
  before_action :date_query_creator
  before_action :set_params_hash
  layout "loggedin"

  def index
    # count data
    @total_appointment_created, @total_appointment_arrived, @total_opd_new_pat_count, @total_opd_old_pat_count, @total_admission_created, @total_admission_admitted = Analytics::PartialData::AdminOverviewData.appointment_admission_data(@params_hash)
    @top_5_facility_names_abbr, @top_5_facility_names_full, @top_5_appointment_not_arrived_count, @top_5_appointment_arrived_count, @facility_names_abbr, @facility_names_full, @appointment_not_arrived_count, @appointment_arrived_count = Analytics::PartialData::AdminOverviewData.appointments_facility_data(@params_hash)
    # corrected
    @patient_gender_array = Analytics::PartialData::PatientData.patient_gender_count_data(@params_hash)
    @patient_age_array = Analytics::PartialData::PatientData.patient_age_group_count_data(@params_hash)

    @facility_feedback_label, @facility_feedback_data = Analytics::PartialData::PatientFeedbacks.each_facility_rating(@params_hash)

    @organisation_feedback_label, @organisation_feedback_data = Analytics::PartialData::PatientFeedbacks.organisation_level_rating(@params_hash)

    # line_chart_weeks
    @org_data_labels, @org_feedback_data = Analytics::PartialData::PatientFeedbacks.overall_organisation_rating(@params_hash)
  end

  def patient
    @appointment_chart_labels, @appointment_chart_new_pat_data, @appointment_chart_old_pat_data = Analytics::PartialData::NewOldPatient.call(@params_hash)

    @frequency_of_opd_revisits_data = Analytics::PartialData::OpdRevisitPatient.call(@params_hash)

    @patient_gender_array = Analytics::PartialData::PatientData.patient_gender_count_data(@params_hash)

    @patient_age_array = Analytics::PartialData::PatientData.patient_age_group_count_data(@params_hash)

    @referral_types_labels, @referral_types_data = Analytics::PartialData::ReferralSource.call(@params_hash)

    @patient_types_labels, @patient_types_data = Analytics::PartialData::PatientData.get_patient_types(@params_hash)

    @feedback_labels, @feedback_data = Analytics::PartialData::PatientFeedbacks.overall_rating(@params_hash)

    @facility_feedback_label, @facility_feedback_data = Analytics::PartialData::PatientFeedbacks.each_facility_rating(@params_hash)

    @organisation_feedback_label, @organisation_feedback_data = Analytics::PartialData::PatientFeedbacks.organisation_level_rating(@params_hash)
  end

  def outpatient
    @appointment_chart_labels, @appointment_chart_new_pat_data, @appointment_chart_old_pat_data = Analytics::PartialData::NewOldPatient.call(@params_hash)

    @frequency_of_opd_revisits_data = Analytics::PartialData::OpdRevisitPatient.call(@params_hash)

    @opd_chart_labels, @opd_average_time = Analytics::PartialData::OpdAverageTime.call(@params_hash)

    @referral_types_labels, @referral_types_data = Analytics::PartialData::ReferralSource.call(@params_hash)

    @appointment_type_labels, @appointment_type_data = Analytics::PartialData::OutpatientData.get_appointment_types_data(@params_hash)

    @appointment_category_type_labels, @appointment_category_type_data = Analytics::PartialData::OutpatientData.get_appointment_category_types_data(@params_hash)

    @walkin_type_labels, @walkin_type_data = Analytics::PartialData::OutpatientData.get_walkin_types_data(@params_hash)
  end

  def inpatient
  end

  def doctor
    # not fake
    # analytics v2 code start
    @doctor_pharmacy_data_labels, @doctor_pharmacy_data_total_count, @doctor_pharmacy_data_converted_count, @doctor_pharmacy_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_pharmacy(@params_hash)

    @doctor_optical_data_labels, @doctor_optical_data_total_count, @doctor_optical_data_converted_count, @doctor_optical_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_optical(@params_hash)

    @procedure_labels, @procedures_total_count, @procedures_converted_count, @procedures_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_procedures_converted(@params_hash)

    @diagnoses_labels, @diagnoses_total_count, @diagnoses_advised_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_diagnosis_advised(@params_hash)

    @ophthal_investigations_labels, @ophthal_investigations_total_count, @ophthal_investigations_converted_count, @ophthal_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_ophthal_investigations_converted(@params_hash)

    @laboratory_investigations_labels, @laboratory_investigations_total_count, @laboratory_investigations_converted_count, @laboratory_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_laboratory_investigations_converted(@params_hash)

    @radiology_investigations_labels, @radiology_investigations_total_count, @radiology_investigations_converted_count, @radiology_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_radiology_investigations_converted(@params_hash)

    @doctor_name_labels, @total_patient_seen, @total_time_given, @total_avg_time_given = Analytics::PartialData::DoctorOperationalData.doctor_average_time(@params_hash)

    @all_doctors_name_label, @all_doctors_patient_seen, @best_5_doctors_label, @best_5_doctors_patient_seen = Analytics::PartialData::DoctorOperationalData.patient_seen_by_doctors(@params_hash)

    @all_facility_name_seen, @all_total_patient_seen_count, @facility_name_label, @total_patient_seen_count, @all_facility_abbreviation = Analytics::PartialData::DoctorOperationalData.total_patient_seen_by_doc_in_facility(@params_hash)

    # analytics v2 code end
  end

  def counsellor
    @counsellor_procedure_labels, @counsellor_procedures_converted_count, @counsellor_procedures_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_procedures_converted(@params_hash)

    @counsellor_ophthal_investigations_labels, @counsellor_ophthal_investigations_converted_count, @counsellor_ophthal_investigations_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_ophthal_investigations_converted(@params_hash)

    @counsellor_laboratory_investigations_labels, @counsellor_laboratory_investigations_converted_count, @counsellor_laboratory_investigations_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_laboratory_investigations_converted(@params_hash)

    @counsellor_radiology_investigations_labels, @counsellor_radiology_investigations_converted_count, @counsellor_radiology_investigations_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_radiology_investigations_converted(@params_hash)
  end

  def optometrist
    @optometrist_name_labels, @optometrist_total_time, @total_patient_seen_by_opto, @avg_time_given_opto = Analytics::PartialData::OptometristAverageTime.call(@params_hash)
  end

  def pharmacy
    @pharmacy_chart_labels, @pharmacy_total_count, @pharmacy_converted_count, @pharmacy_not_converted_count, @pharmacy_earnings = Analytics::PartialData::PharmacyData.call(@params_hash)
  end

  def optical
    @optical_chart_labels, @optical_total_count, @optical_converted_count, @optical_not_converted_count, @optical_earnings = Analytics::PartialData::OpticalData.call(@params_hash)
  end

  def tpa
  end

  def inventory
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
      "organisation_id" => @current_facility.organisation_id,
      "facility_id" => @facility_id,
      "specialty_id" => @specialty_id,
      "analytics_to_date" => @analytics_to_date,
      "analytics_from_date" => @analytics_from_date,
      "data_type" => @data_type,
      "data_query" => @data_query,
      "label_on" => @label_on
    }
    # check if start and end dates are same

    if @analytics_from_date == @analytics_to_date
      @todays_data = true
    end
  end

  def date_query_creator
    from_date = @analytics_from_date
    to_date   = @analytics_to_date

    @data_query, @label_on = Analytics::AnalyticsDate::QueryGenerator.query_array_builder(to_date, from_date)
  end
end
