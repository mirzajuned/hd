class Analytics::CustomDashboardsController < ApplicationController
  layout "loggedin"
  before_action :get_analytics_filters

  def index
    @appointment_chart_labels, @appointment_chart_new_pat_data, @appointment_chart_old_pat_data = Analytics::PartialData::NewOldPatient.call(current_facility.organisation_id, @facility_id, @analytics_to_date, @analytics_from_date)

    @frequency_of_opd_revisits_data = Analytics::PartialData::OpdRevisitPatient.call(current_facility.organisation_id, @facility_id, @analytics_to_date, @analytics_from_date)

    patient_gender_grp = ::Patient.collection.aggregate([{ "$match" => { "reg_hosp_ids" => [current_facility.organisation_id.to_s], "created_at" => { "$gte" => Time.parse(@analytics_from_date).utc, "$lte" => Time.parse(@analytics_to_date) + 1.day } } }, { "$group" => { "_id" => "$gender", "total_count" => { "$sum" => 1 } } }]).to_a

    transgender_patient = patient_gender_grp.find { |set| set["_id"] == "Transgender" }.try(:[], "total_count").to_i
    male_patient = patient_gender_grp.find { |set| set["_id"] == "Male" }.try(:[], "total_count").to_i
    female_patient = patient_gender_grp.find { |set| set["_id"] == "Female" }.try(:[], "total_count").to_i
    unspecified_patient = patient_gender_grp.find { |set| (set["_id"] == nil || set["_id"] == "") }.try(:[], "total_count").to_i

    @patient_gender_array = [male_patient, female_patient, transgender_patient, unspecified_patient]

    @patient_age_grp_array = ::Patient.collection.aggregate([{ "$match" => { "reg_hosp_ids" => [current_facility.organisation_id.to_s], "created_at" => { "$gte" => Time.parse(@analytics_from_date).utc, "$lte" => Time.parse(@analytics_to_date) + 1.day } } }, { "$group" => { "_id" => "$age", "total_count" => { "$sum" => 1 } } }]).to_a

    @patient_age_array = [@patient_age_grp_array.select { |set| set["_id"].to_i <= 20 && set["_id"] != nil }.pluck("total_count").sum, @patient_age_grp_array.select { |set| set["_id"].to_i > 21 && set["_id"].to_i <= 40 }.pluck("total_count").sum, @patient_age_grp_array.select { |set| set["_id"].to_i > 41 && set["_id"].to_i <= 60 }.pluck("total_count").sum, @patient_age_grp_array.select { |set| set["_id"].to_i > 61 && set["_id"].to_i <= 80 }.pluck("total_count").sum, @patient_age_grp_array.select { |set| set["_id"].to_i > 81 }.pluck("total_count").sum]

    @opd_chart_labels, @opd_average_time = Analytics::PartialData::OpdAverageTime.call(current_facility.organisation_id, @facility_id, @analytics_to_date, @analytics_from_date)

    @custom_dashboard = Analytics::CustomDashboard.find_by(id: params[:custom_dashboard_id])
  end

  def new
    @custom_dashboard = Analytics::CustomDashboard.new
  end

  def create
    @custom_dashboard = Analytics::CustomDashboard.new(custom_dashboard_params)

    if @custom_dashboard.save!
      respond_to do |format|
        format.js {}
      end
    end
  end

  def update
    @custom_dashboard = Analytics::CustomDashboard.find_by(id: params[:id])

    if @custom_dashboard.update_attributes(custom_dashboard_params)
      respond_to do |format|
        format.js {}
      end
    end
  end

  private

  def get_analytics_filters
    @facility_id = params[:filtered_facility] || current_facility.id
    @analytics_to_date = params[:analytics_to_date]
    @analytics_from_date = params[:analytics_from_date]
  end

  def custom_dashboard_params
    params.require(:analytics_custom_dashboard).permit(:dashboard_name, :selected_data, :user_id, :facility_id, :organisation_id)
  end
end
