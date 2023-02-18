module Api::V1::Analytics
  class ClinicalsController < ApiApplicationController
    before_action :authorize_token
    before_action :get_analytics_filters
    before_action :set_user_facility
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

    private

    def get_analytics_filters
      @organisation_id = current_facility.organisation_id

      @facility_id = params[:filtered_facility].present? ? params[:filtered_facility] : current_facility.id
      @analytics_to_date = params[:analytics_to_date].present? ? params[:analytics_to_date] : Date.current
      @analytics_from_date = params[:analytics_from_date].present? ? params[:analytics_from_date] : Date.current
      @data_type = params[:data_type].present? ? params[:data_type] : 'day'
    end

    def set_user_facility
      @current_user = current_user
      @current_facility = current_facility
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
