class Search::Results::ProceduresController < ApplicationController
  include SystemicHistoryHelper

  before_action :authorize
  # before_filter :authorize_onboard
  layout "loggedin"

  def index
    code = params[:code]
    @search_filter = params[:search_filter]

    # @procedure_type = params[:type]
    @procedure_type = get_procedure_type(params[:type])

    if @procedure_type.present?
      common_procedure = @procedure_type.constantize.find_by(code: code)
    else
      common_procedure = CommonProcedure.find_by(code: code)
    end

    @procedure_name = common_procedure.try(:name)

    @procedure_code = code

    if params[:laterality].present?
      laterality = [params[:laterality]]
      @laterality = params[:laterality]
    else
      laterality = ["Right", "Left", "Bilateral", "", nil]
    end
    if params[:format].present? && params[:format] == 'xls'
      params[:gender] = params[:gender].split(',')
    end
    if params[:gender].present?
      gender_array = params[:gender]
      un = false
      if params[:gender].include?("un")
        deleted_nil = gender_array.delete("un")
        gender_array = gender_array.push(nil)
        un = true
      end
      gender = gender_array
      @gender = un ? params[:gender].compact.push('un') : params[:gender].compact
    else
      gender = ["Male", "Female", "Transgender", "", nil]
    end

    if params[:systemic_history].present?
      systemic_history = params[:systemic_history]
      @systemic_history = params[:systemic_history]
    else
      empty_val = ["", nil]
      systemic_history = personal_history_names # method defined in helper
      systemic_history = systemic_history.push(*empty_val)
      @systemic_history = []
    end

    if params[:eye_drop_allergies].present?
      eye_drop_allergies = params[:eye_drop_allergies]
      @eye_drop_allergies = params[:eye_drop_allergies]
    else
      empty_val = ["", nil]
      eye_drop_allergies = eye_drop_allergy_names # method defined in helper
      eye_drop_allergies = eye_drop_allergies.push(*empty_val)
      @eye_drop_allergies = []
    end

    if params[:limit].present? || (params[:show_more].present? && params[:show_more] == "true")
      limit = 200
      @show_more = params[:show_more]
    else
      limit = 50
    end

    if params[:procedure_stage].present?
      procedure_stage = params[:procedure_stage] != "any" ? [params[:procedure_stage]] : ["A", "P", "", nil]
      @procedure_stage = params[:procedure_stage]
    else
      procedure_stage = ["A", "P", "", nil]
      @procedure_stage = ""
    end

    @current_facility = current_facility
    @current_user = current_user

    if params[:above_age].present? || params[:below_age].present?
      if params[:above_age].present?
        above_age = params[:above_age]
        @above_age = params[:above_age]
      else
        above_age = "0"
      end
      if params[:below_age].present?
        below_age = params[:below_age]
        @below_age = params[:below_age]
      else
        below_age = "125"
      end

      # diagnosis filter start
      if @search_filter == "all" && ((@current_user.role_ids.include? 158965000) || @current_user.role_ids.include?(160943002) || @current_user.include?(6868009))
        @patient_procedure = PatientProcedure.where(:organisation_id => @current_facility.organisation_id, :code => code, :laterality.in => laterality, :patient_gender.in => gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies, :procedure_stage.in => procedure_stage).order(last_updated_on: :desc).limit(limit).group_by(&:laterality)
      elsif @search_filter == "facility"
        @patient_procedure = PatientProcedure.where(:facility_ids.in => [@current_facility.id], :code => code, :laterality.in => laterality, :patient_gender.in => gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies, :procedure_stage.in => procedure_stage).order(last_updated_on: :desc).limit(limit).group_by(&:laterality)
      else
        @patient_procedure = PatientProcedure.where(:entered_by_ids.in => [@current_user.id], :code => code, :laterality.in => laterality, :patient_gender.in => gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies, :procedure_stage.in => procedure_stage).order(last_updated_on: :desc).limit(limit).group_by(&:laterality)
      end
      # diagnosis filter end

    else
      # diagnosis filter start
      if @search_filter == "all" && ((@current_user.role_ids.include? 158965000) || @current_user.role_ids.include?(160943002) || @current_user.include?(6868009))
        @patient_procedure = PatientProcedure.where(:organisation_id => @current_facility.organisation_id, :code => code, :laterality.in => laterality, :patient_gender.in => gender, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies, :procedure_stage.in => procedure_stage).order(last_updated_on: :desc).limit(50).group_by(&:laterality)
      elsif @search_filter == "facility"
        @patient_procedure = PatientProcedure.where(:facility_ids.in => [@current_facility.id], :code => code, :laterality.in => laterality, :patient_gender.in => gender, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies, :procedure_stage.in => procedure_stage).order(last_updated_on: :desc).limit(50).group_by(&:laterality)
      else
        @patient_procedure = PatientProcedure.where(:entered_by_ids.in => [@current_user.id], :code => code, :laterality.in => laterality, :patient_gender.in => gender, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies, :procedure_stage.in => procedure_stage).order(last_updated_on: :desc).limit(50).group_by(&:laterality)
      end
    end

    if request.format == :xls
      @filename = "#{Date.today}_patient_procedure.xls"
      respond_to do |format|
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{@filename}\"" }
      end
    end

    puts "================================>", @patient_procedure
  end

  def filter
  end

  def get_procedure_type(procedure_type)
    ['CustomCommonProcedure', 'CommonProcedure', 'SynonymCommonProcedure', 'TranslatedCommonProcedure'].select{|procedure| procedure == procedure_type}.first
  end
  # EOF get_procedure_type
end
