module Api::V1::Analytics
  class OperationalsController < ApiApplicationController
    before_action :authorize_token
    before_action :get_analytics_filters
    before_action :set_user_facility
    before_action :date_query_creator
    before_action :set_params_hash
    def index
      # corrected
      @total_appointment_created, @total_appointment_arrived, @total_opd_new_pat_count, @total_opd_old_pat_count, @total_admission_created, @total_admission_admitted = Analytics::PartialData::AdminOverviewData.appointment_admission_data(@params_hash)
      @total_earnings = Analytics::PartialData::AdminOverviewData.over_all_earnings(@params_hash)

      # row 2
      @doctor_pharmacy_data_labels, @doctor_pharmacy_data_total_count, @doctor_pharmacy_data_converted_count, @doctor_pharmacy_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_pharmacy(@params_hash)

      @doctor_optical_data_labels, @doctor_optical_data_total_count, @doctor_optical_data_converted_count, @doctor_optical_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_optical(@params_hash)

      # row 3

      @ophthal_investigations_labels, @ophthal_investigations_total_count, @ophthal_investigations_converted_count, @ophthal_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_ophthal_investigations_converted(@params_hash)
      @laboratory_investigations_labels, @laboratory_investigations_total_count, @laboratory_investigations_converted_count, @laboratory_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_laboratory_investigations_converted(@params_hash)
      @radiology_investigations_labels, @radiology_investigations_total_count, @radiology_investigations_converted_count, @radiology_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_radiology_investigations_converted(@params_hash)

      if @todays_data.present?
        @all_investigation_total = @ophthal_investigations_total_count.reject(&:blank?).last.to_i + @laboratory_investigations_total_count.reject(&:blank?).last.to_i + @radiology_investigations_total_count.reject(&:blank?).last.to_i

        @all_investigation_converted = @ophthal_investigations_converted_count.reject(&:blank?).last.to_i + @laboratory_investigations_converted_count.reject(&:blank?).last.to_i + @radiology_investigations_converted_count.reject(&:blank?).last.to_i

      else
        @all_investigation_total = @ophthal_investigations_total_count.reject(&:blank?).sum + @laboratory_investigations_total_count.reject(&:blank?).sum + @radiology_investigations_total_count.reject(&:blank?).sum

        @all_investigation_converted = @ophthal_investigations_converted_count.reject(&:blank?).sum + @laboratory_investigations_converted_count.reject(&:blank?).sum + @radiology_investigations_converted_count.reject(&:blank?).sum
      end

      @procedure_labels, @procedures_total_count, @procedures_converted_count, @procedures_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_procedures_converted(@params_hash)

      @patient_gender_array = Analytics::PartialData::PatientData.patient_gender_count_data(@params_hash)
      @patient_age_array = Analytics::PartialData::PatientData.patient_age_group_count_data(@params_hash)
      @patient_gender_list = ["Male", "Female", "Transgender", "Unspecified"]
      @patient_age_label = ["0-20", "21-40", "41-60", "61-80", ">81"]

      @facility_feedback_label, @facility_feedback_data = Analytics::PartialData::PatientFeedbacks.each_facility_rating(@params_hash)

      @organisation_feedback_label, @organisation_feedback_data = Analytics::PartialData::PatientFeedbacks.organisation_level_rating(@params_hash)

      # line_chart_weeks
      @org_data_labels, @org_feedback_data = Analytics::PartialData::PatientFeedbacks.overall_organisation_rating(@params_hash)
    end

    private

    def set_user_facility
      @current_facility = current_facility
      @current_user = current_user
    end

    def get_analytics_filters
      @facility_id = params[:filtered_facility].present? ? params[:filtered_facility] : current_facility.id
      @analytics_to_date = params[:analytics_to_date].present? ? params[:analytics_to_date] : Date.current
      @analytics_from_date = params[:analytics_from_date].present? ? params[:analytics_from_date] : (Date.current - 7)
      @data_type = params[:data_type].present? ? params[:data_type] : 'day'
    end

    def set_params_hash
      @params_hash = {
        "organisation_id" => @current_facility.organisation_id,
        "facility_id" => @facility_id,
        "analytics_to_date" => @analytics_to_date,
        "analytics_from_date" => @analytics_from_date,
        "data_type" => @data_type,
        "data_query" => @data_query,
        "label_on" => @label_on
      }
      # check if date is start and end dates are same

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
end
