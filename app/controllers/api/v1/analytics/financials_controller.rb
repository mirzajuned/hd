module Api::V1::Analytics
  class FinancialsController < ApiApplicationController
    before_action :authorize_token
    before_action :get_analytics_filters
    before_action :set_user_facility
    before_action :date_query_creator
    before_action :set_params_hash
    before_action :get_financial_data

    def index
      @opd_new_patient_amount, @opd_old_patient_amount, @opd_invoice_count = ::Analytics::PartialData::FinanceOverviewData.total_outpatient_data(@finance_analytics)

      @ipd_new_patient_amount, @ipd_old_patient_amount, @ipd_invoice_count = ::Analytics::PartialData::FinanceOverviewData.total_inpatient_data(@finance_analytics)

      @pharmacy_new_patient_amount, @pharmacy_old_patient_amount, @pharmacy_invoice_count = ::Analytics::PartialData::FinanceOverviewData.total_pharmacy_data(@finance_analytics)

      @optical_new_patient_amount, @optical_old_patient_amount, @optical_invoice_count = ::Analytics::PartialData::FinanceOverviewData.total_optical_data(@finance_analytics)

      @weekly_opd_new_patient_amount, @weekly_opd_old_patient_amount, @weekly_opd_amount, @weekly_opd_invoice_count = ::Analytics::PartialData::FinanceOverviewData.periodic_outpatient_data(@weekly_financial_overview)

      @weekly_ipd_new_patient_amount, @weekly_ipd_old_patient_amount, @weekly_ipd_amount, @weekly_ipd_invoice_count = ::Analytics::PartialData::FinanceOverviewData.periodic_inpatient_data(@weekly_financial_overview)

      @weekly_pharmacy_new_patient_amount, @weekly_pharmacy_old_patient_amount, @weekly_pharmacy_amount, @weekly_pharmacy_invoice_count = ::Analytics::PartialData::FinanceOverviewData.periodic_pharmacy_data(@weekly_financial_overview)

      @weekly_optical_new_patient_amount, @weekly_optical_old_patient_amount, @weekly_optical_amount, @weekly_optical_invoice_count = ::Analytics::PartialData::FinanceOverviewData.periodic_optical_data(@weekly_financial_overview)

      @weekly_overall_amount = @weekly_financial_overview.map { |el| el["opd_new_patient_amount"].to_f + el["opd_old_patient_amount"].to_f + el["ipd_new_patient_amount"].to_f + el["ipd_old_patient_amount"].to_f + el["pharmacy_new_patient_amount"].to_f + el["pharmacy_old_patient_amount"].to_f + el["optical_new_patient_amount"].to_f + el["optical_old_patient_amount"].to_f }
    end

    private

    def get_analytics_filters
      @organisation_id = current_facility.organisation_id

      @facility_id = params[:filtered_facility].present? ? params[:filtered_facility] : current_facility.id
      @analytics_to_date = params[:analytics_to_date].present? ? params[:analytics_to_date] : Date.current
      @analytics_from_date = params[:analytics_from_date].present? ? params[:analytics_from_date] : Date.current
      @currency_id = params[:currency_id] || Facility.find_by(id: @facility_id).try(:currency_id) || current_facility.currency_id
      @data_type = params[:data_type].present? ? params[:data_type] : 'day'
      # @appointment_chart_labels, @finance_analytics, @weekly_financial_overview = ::Analytics::PartialData::FinanceOverviewData.call(@organisation_id,@facility_id, @analytics_from_date, @analytics_to_date)
      # #@weekly_financial_overview = d2.upto(d1).to_a.map{ |date| @weekly_financial_overview_grp_by_date[date]}.flatten
    end

    def get_financial_data
      @appointment_chart_labels, @finance_analytics, @weekly_financial_overview = Analytics::PartialData::FinanceOverviewData.call(@params_hash)
    end

    def set_user_facility
      @current_facility = current_facility
      @current_user = current_user
    end

    def set_params_hash
      @params_hash = {
        "organisation_id" => @current_facility.organisation_id,
        "facility_id" => @facility_id,
        "analytics_to_date" => @analytics_to_date,
        "analytics_from_date" => @analytics_from_date,
        "currency_id" => @currency_id,
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
