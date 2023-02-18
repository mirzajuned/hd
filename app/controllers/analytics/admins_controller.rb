class Analytics::AdminsController < ApplicationController
  before_action :authorize
  before_action :authenticate_admin_user, only: [:index]
  before_action :get_analytics_filters
  before_action :set_user_facility
  # before_filter :authorize_onboard
  before_action :date_query_creator
  before_action :set_params_hash
  layout "loggedin"

  def index
  end

  def overview
    @current_facility = current_facility
    @organisation_id = @current_facility.organisation_id
    # over view first row box data
    @total_appointment_created, @total_appointment_arrived, @total_opd_new_pat_count, @total_opd_old_pat_count, @total_admission_created, @total_admission_admitted = Analytics::PartialData::AdminOverviewData.appointment_admission_data(@params_hash)
    # overviewr view first row box data end

    # to show box data doctor data row 2 start
    # analytics v2 code start
    @doctor_pharmacy_data_labels, @doctor_pharmacy_data_total_count, @doctor_pharmacy_data_converted_count, @doctor_pharmacy_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_pharmacy(@params_hash)

    @doctor_optical_data_labels, @doctor_optical_data_total_count, @doctor_optical_data_converted_count, @doctor_optical_data_not_converted = Analytics::PartialData::DoctorOperationalData.doctor_converted_optical(@params_hash)

    @procedure_labels, @procedures_total_count, @procedures_converted_count, @procedures_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_procedures_converted(@params_hash)

    @ophthal_investigations_labels, @ophthal_investigations_total_count, @ophthal_investigations_converted_count, @ophthal_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_ophthal_investigations_converted(@params_hash)

    @laboratory_investigations_labels, @laboratory_investigations_total_count, @laboratory_investigations_converted_count, @laboratory_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_laboratory_investigations_converted(@params_hash)

    @radiology_investigations_labels, @radiology_investigations_total_count, @radiology_investigations_converted_count, @radiology_investigations_not_converted_count, @group_by = Analytics::PartialData::DoctorOperationalData.doctor_radiology_investigations_converted(@params_hash)

    # analytics v2 code end row 2 end

    # version 2 refactoring started row 3 start
    # counsoler data

    @counsellor_procedure_labels, @counsellor_procedures_converted_count, @counsellor_procedures_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_procedures_converted(@params_hash)

    @counsellor_ophthal_investigations_labels, @counsellor_ophthal_investigations_converted_count, @counsellor_ophthal_investigations_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_ophthal_investigations_converted(@params_hash)

    @counsellor_laboratory_investigations_labels, @counsellor_laboratory_investigations_converted_count, @counsellor_laboratory_investigations_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_laboratory_investigations_converted(@params_hash)

    @counsellor_radiology_investigations_labels, @counsellor_radiology_investigations_converted_count, @counsellor_radiology_investigations_not_converted_count, @group_by = Analytics::PartialData::CounsellorOperationalData.counsellor_radiology_investigations_converted(@params_hash)
    # version 2 counsoller done row 3 end

    # pharmacy data row 4 start
    @pharmacy_chart_labels, @pharmacy_total_count, @pharmacy_converted_count, @pharmacy_not_converted_count = Analytics::PartialData::PharmacyData.call(@params_hash)
    # row 4 end

    # pharmacy data row 5 start
    @optical_chart_labels, @optical_total_count, @optical_converted_count, @optical_not_converted_count = Analytics::PartialData::OpticalData.call(@params_hash)

    # getting data from  row 7 start
    # @pharmacy_old_patient_amount_fin, @pharmacy_new_patient_amount_fin, @optical_old_patient_amount_fin, @optical_new_patient_amount_fin, @opd_new_patient_amount_fin, @opd_old_patient_amount_fin, @ipd_new_patient_amount_fin, @ipd_old_patient_amount_fin = Analytics::PartialData::AdminOverviewData.financial_data(@params_hash)
    # row 7 end
    
    
    # @total_earnings = @pharmacy_old_patient_amount_fin.to_f +
    #                   @pharmacy_new_patient_amount_fin.to_f +
    #                   @optical_old_patient_amount_fin.to_f  +
    #                   @optical_new_patient_amount_fin.to_f  +
    #                   @opd_new_patient_amount_fin.to_f +
    #                   @opd_old_patient_amount_fin.to_f +
    #                   @ipd_new_patient_amount_fin.to_f +
    #                   @ipd_old_patient_amount_fin.to_f

    @total_collection, @ipd_collection,
      @opd_collection, @optical_collection,
      @pharmacy_collection = Analytics::Invoice::CollectionData.call(@params_hash)
    @pharmacy_bill, @optical_bill, @opd_bill, @ipd_bill = Analytics::Invoice::BillData.call(@params_hash)
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

  def authenticate_admin_user
    department_ids = current_user.department_ids
    if department_ids.present?
      if department_ids.include?("224608005")
        # custom_check_for_lockup
      else
        redirect_to user_department_url(current_user)
      end
    else
      redirect_to '/'
    end
  end

  def custom_check_for_lockup
    multi_auth = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:multi_auth)
    return unless multi_auth
    return unless respond_to?(:lockup) && lockup_codeword
    return if cookies[:lockup].present? && cookies[:lockup] == lockup_codeword.to_s.downcase

    if request.xhr?
      respond_to do |format|
        format.js { render inline: "location.reload();" }
      end
    else
      redirect_to lockup.unlock_path(
        return_to: request.fullpath.split('?lockup_codeword')[0],
        lockup_codeword: params[:lockup_codeword],
      )
    end
  end

  def get_analytics_filters
    @facility_id = params[:filtered_facility] || current_facility.id
    @specialty_id = (params[:filtered_specialty] if params[:filtered_specialty].present?) || 'all'
    @analytics_from_date = params[:analytics_from_date] || Date.today.strftime("%d/%m/%Y")
    @analytics_to_date = params[:analytics_to_date] || Date.today.strftime("%d/%m/%Y")
    @data_type = params[:data_type].present? ? params[:data_type] : 'day'
  end

  def set_user_facility
    @current_facility = current_facility
    @current_user = current_user
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
