class Analytics::UsersController < ApplicationController
  before_action :authorize
  before_action :get_analytics_filters
  before_action :set_user_facility
  # before_filter :authorize_onboard
  before_action :date_query_creator
  before_action :set_params_hash
  layout "loggedin"

  def index
  end

  def overview
    # Huzi New Query
    @current_user = current_user
    @current_facility = current_facility
    @organisation_id = @current_facility.organisation_id

    # clean up code for analytics version 2

    # conversion pharmacy optical

    @doctor_pharmacy_data_labels, @doctor_pharmacy_data_total_count, @doctor_pharmacy_data_converted_count, @doctor_pharmacy_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_pharmacy(@params_hash)

    # converted optical
    @doctor_optical_data_labels, @doctor_optical_data_total_count, @doctor_optical_data_converted_count, @doctor_optical_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_optical(@params_hash)
    # procedure doctor wise
    @procedure_labels, @procedures_total_count, @procedures_converted_count, @procedures_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_procedures_converted(@params_hash)

    @diagnoses_labels, @diagnoses_total_count, @diagnoses_advised_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_diagnosis_advised(@params_hash)

    @ophthal_investigations_labels, @ophthal_investigations_total_count, @ophthal_investigations_converted_count, @ophthal_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_ophthal_investigations_converted(@params_hash)

    @laboratory_investigations_labels, @laboratory_investigations_total_count, @laboratory_investigations_converted_count, @laboratory_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_laboratory_investigations_converted(@params_hash)

    @radiology_investigations_labels, @radiology_investigations_total_count, @radiology_investigations_converted_count, @radiology_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_radiology_investigations_converted(@params_hash)

    @doctor_name_labels, @total_patient_seen, @total_time_given, @total_avg_time_given = Analytics::PartialData::DoctorOperationalData.doctor_average_time(@params_hash)

    @total_appointment_created, @total_appointment_arrived, @total_opd_new_pat_count, @total_opd_old_pat_count, @total_admission_created, @total_admission_admitted = Analytics::PartialData::AdminOverviewData.appointment_admission_data(@params_hash)

    # @total_earnings = Analytics::PartialData::AdminOverviewData.over_all_earnings(@params_hash)
  end

  def finance
    d1 = Date.today
    d2 = Date.today - 7
    @finance_chart_labels = d2.upto(d1).to_a.map { |date| date.strftime("%A") }
    @finance_opd_data = [654, 354, 748, 560, 424, 543, 445, 487]
    @finance_ipd_data = [545, 666, 775, 464, 575, 657, 543, 267]
    @finance_optical_data = [440, 346, 733, 404, 550, 637, 514, 267]
    @finance_pharmacy_data = [645, 566, 477, 244, 355, 567, 454, 367]
    @top_opd_facility = Facility.where(organisation_id: current_facility.organisation_id).limit(5).pluck(:name).map { |i| i.split.map(&:first).join.upcase }
  end

  def insights
    d1 = Date.today
    d2 = Date.today - 7

    @top_opd_facility = Facility.where(organisation_id: current_facility.organisation_id).limit(5).pluck(:name).map { |i| i.split.map(&:first).join.upcase }
    # @finance_chart_labels = d2.upto(d1).to_a.map{ |date| date.strftime("%A") }
    # @finance_opd_data = [654,354,748,560,424,543,445,487]
    # @finance_ipd_data = [545,666,775,464,575,657,543,267]
    # @finance_optical_data = [440,346,733,404,550,637,514,267]
    # @finance_pharmacy_data = [645,566,477,244,355,567,454,367]
    # @top_opd_facility = Facility.where(organisation_id: current_facility.organisation_id).limit(5).pluck(:name).map{|i| i.split.map(&:first).join.upcase}
  end

  def clinical
    d1 = Date.today
    d2 = Date.today - 7
    # @finance_chart_labels = d2.upto(d1).to_a.map{ |date| date.strftime("%A") }
    # @finance_opd_data = [654,354,748,560,424,543,445,487]
    # @finance_ipd_data = [545,666,775,464,575,657,543,267]
    # @finance_optical_data = [440,346,733,404,550,637,514,267]
    # @finance_pharmacy_data = [645,566,477,244,355,567,454,367]
    @top_diagnoses = ["Cataract", "Glaucoma", "Retina", "Squint", "Refraction", "Others"]
    @top_procedures = ["Cornea", "Retina", "Glaucoma", "Cataract", "Plasty", "squint"]
    @top_investigations = ["Cornea", "Retina", "Glaucoma", "Cataract", "Neuro-Ophthal & Squint"]

    # PatientDiagnosis.all.map{|pd| pd.search_code_array.find {|i| i.length == 5  }}
    @patient_diagnoses = PatientDiagnosis.where(organisation_id: current_facility.organisation_id).map { |pd| pd.search_code_array.sort_by(&:size)[0] }

    puts @patient_diagnoses

    @patient_diagnoses_count = Hash.new(0)
    @patient_diagnoses.each do |v|
      @patient_diagnoses_count[v] += 1
    end

    @patient_procedures = PatientProcedure.where(organisation_id: current_facility.organisation_id).pluck(:code)
    @patient_procedures_count = Hash.new(0)
    @patient_procedures.each do |v|
      @patient_procedures_count[v] += 1
    end
  end

  private

  def get_analytics_filters
    @facility_id = params[:filtered_facility] || current_facility.id
    @analytics_to_date = params[:analytics_to_date] || Date.today.strftime("%d/%m/%Y")
    @analytics_from_date = params[:analytics_from_date] || Date.today.strftime("%d/%m/%Y")
    @data_type = params[:data_type].present? ? params[:data_type] : 'day'
  end

  def set_params_hash
    @params_hash = {
      "organisation_id" => @current_facility.organisation_id,
      "facility_id" => @facility_id,
      "user_id" => current_user.id.to_s,
      "specialty_id" => current_user.specialty_ids[0].to_s,
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

  def set_user_facility
    @current_facility = current_facility
    @current_user = current_user
  end

  def date_query_creator
    from_date = @analytics_from_date
    to_date   = @analytics_to_date

    @data_query, @label_on = Analytics::AnalyticsDate::QueryGenerator.query_array_builder(to_date, from_date)
  end
end
