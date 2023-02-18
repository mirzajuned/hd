class Search::Results::DiagnosesController < ApplicationController
  include SystemicHistoryHelper
  before_action :authorize
  # before_filter :authorize_onboard
  layout "loggedin"

  def index
    icd_code = params[:icd_code]
    @search_filter = params[:search_filter]
    # icd_code = params[:id]

    # @icd_type = params[:type]
    @icd_type = icd_types(params[:type])

    if @icd_type.present?
      icd_diag = @icd_type.constantize.find_by(code: icd_code, organisation_id: current_user.organisation_id)
    else
      icd_diag = IcdDiagnosis.find_by(code: icd_code)
    end

    @diagnosis_name = icd_diag.try(:originalname)

    @diagnosis_code = icd_code

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
      if @search_filter == "all" && (@current_user.role_ids.include?(6868009) || @current_user.role_ids.include?(160943002))
        @patient_diagnosis = PatientDiagnosis.where(:organisation_id => @current_facility.organisation_id, :search_code_array.in => [icd_code], :laterality.in => laterality, :patient_gender.in => gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies).order(last_updated_on: :desc).limit(limit).group_by(&:code)
      elsif @search_filter == "facility"
        @patient_diagnosis = PatientDiagnosis.where(:facility_ids.in => [@current_facility.id], :search_code_array.in => [icd_code], :laterality.in => laterality, :patient_gender.in => gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies).order(last_updated_on: :desc).limit(limit).group_by(&:code)
      else
        @patient_diagnosis = PatientDiagnosis.where(:entered_by_ids.in => [@current_user.id], :search_code_array.in => [icd_code], :laterality.in => laterality, :patient_gender.in => gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies).order(last_updated_on: :desc).limit(limit).group_by(&:code)
      end
      # diagnosis filter end

    else
      # diagnosis filter start
      if @search_filter == "all" && (@current_user.role_ids.include?(6868009) || @current_user.role_ids.include?(160943002))
        @patient_diagnosis = PatientDiagnosis.where(:organisation_id => @current_facility.organisation_id, :search_code_array.in => [icd_code], :laterality.in => laterality, :patient_gender.in => gender, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies).order(last_updated_on: :desc).limit(limit).group_by(&:code)
      elsif @search_filter == "facility"
        @patient_diagnosis = PatientDiagnosis.where(:facility_ids.in => [@current_facility.id], :search_code_array.in => [icd_code], :laterality.in => laterality, :patient_gender.in => gender, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies).order(last_updated_on: :desc).limit(limit).group_by(&:code)
      else
        @patient_diagnosis = PatientDiagnosis.where(:entered_by_ids.in => [@current_user.id], :search_code_array.in => [icd_code], :laterality.in => laterality, :patient_gender.in => gender, :systemic_history_name.in => systemic_history, :eye_drop_allergy_name.in => eye_drop_allergies).order(last_updated_on: :desc).limit(limit).group_by(&:code)
      end
    end

    if request.format == :xls
      @filename = "#{Date.today}_patient_diagnosis.xls"
      respond_to do |format|
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{@filename}\"" }
      end
    end
  end

  # def show
  #   icd_code = params[:id]
  #   icd_diag = IcdDiagnosis.find_by(code: icd_code)
  #
  #   @diagnosis_name = icd_diag.try(:originalname)
  #
  #
  #   @diagnosis_code = icd_code
  #
  #   if params[:laterality].present?
  #     laterality = [params[:laterality]]
  #     @laterality = params[:laterality]
  #   else
  #     laterality = ["Right","Left","Bilateral","",nil]
  #   end
  #
  #   if params[:gender].present?
  #     gender = [params[:gender]]
  #     @gender = params[:gender]
  #   else
  #     gender = ["Male", "Female","Transgender","",nil]
  #   end
  #
  #
  #   @current_facility = current_facility
  #   @current_user = current_user
  #
  #   if params[:above_age].present? || params[:below_age].present?
  #     if params[:above_age].present?
  #       above_age = params[:above_age]
  #       @above_age = params[:above_age]
  #     else
  #       above_age = "0"
  #     end
  #     if params[:below_age].present?
  #       below_age = params[:below_age]
  #       @below_age = params[:below_age]
  #     else
  #       below_age = "125"
  #     end
  #
  #     # diagnosis filter start
  #     if params[:search_filter] == "all"
  #       @patient_diagnosis = PatientDiagnosis.where(:organisation_id=> @current_facility.organisation_id ,:search_code_array.in=> [icd_code],:laterality.in=> laterality , :patient_gender.in=> gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s).order(last_updated_on: :desc).limit(50).group_by(&:code)
  #     elsif params[:search_filter] == "facility"
  #       @patient_diagnosis = PatientDiagnosis.where(:facility_ids.in=> [@current_facility.id] ,:search_code_array.in=> [icd_code],:laterality.in=> laterality , :patient_gender.in=> gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s).order(last_updated_on: :desc).limit(50).group_by(&:code)
  #     else
  #       @patient_diagnosis = PatientDiagnosis.where(:entered_by_ids.in=> [@current_user.id] ,:search_code_array.in=> [icd_code],:laterality.in=> laterality , :patient_gender.in=> gender, :patient_dob_year.gte => (Date.today.year - below_age.to_i).to_s, :patient_dob_year.lte => (Date.today.year - above_age.to_i).to_s).order(last_updated_on: :desc).limit(50).group_by(&:code)
  #     end
  #     # diagnosis filter end
  #
  #   else
  #     # diagnosis filter start
  #     if params[:search_filter] == "all"
  #       @patient_diagnosis = PatientDiagnosis.where(:organisation_id=> @current_facility.organisation_id ,:search_code_array.in=> [icd_code],:laterality.in=> laterality , :patient_gender.in=> gender).order(last_updated_on: :desc).limit(50).group_by(&:code)
  #     elsif params[:search_filter] == "facility"
  #       @patient_diagnosis = PatientDiagnosis.where(:facility_ids.in=> [@current_facility.id] ,:search_code_array.in=> [icd_code],:laterality.in=> laterality , :patient_gender.in=> gender).order(last_updated_on: :desc).limit(50).group_by(&:code)
  #     else
  #       @patient_diagnosis = PatientDiagnosis.where(:entered_by_ids.in=> [@current_user.id] ,:search_code_array.in=> [icd_code],:laterality.in=> laterality , :patient_gender.in=> gender).order(last_updated_on: :desc).limit(50).group_by(&:code)
  #     end
  #   end
  #
  #
  #
  # end

  # def searchdiagnosis
  #
  #   arr = params[:q].tr('^A-Za-z0-9', ' ').gsub("  "," ").downcase.split(" ")
  #   @codearray = ICDARRAY.select { |set| arr.all? { |t| set[:fullname].include?(t) } }
  #
  #   icd_code_arr = []
  #   @codearray.each do |a|
  #     icd_code_arr << a[:code]
  #   end
  #
  #   @icd_code_array = []
  #   @icddiagnosis = IcdDiagnosis.where(:code.in => icd_code_arr, has_laterality: false, :codelength.gte => 4).limit(20)
  #   @icddiagnosis.each do |icd_diagnosis|
  #     icd = Struct.new(:id, :fullname, :code, :is_custom ,:icd_type, :icd_type_label, :originalname).new
  #     icd.id = icd_diagnosis._id
  #     icd.originalname = icd_diagnosis.originalname
  #     icd.fullname = icd_diagnosis.fullname
  #     icd.code = icd_diagnosis.code
  #     icd.icd_type = "IcdDiagnosis"
  #     icd.icd_type_label = "I"
  #     @icd_code_array << icd
  #   end
  #
  # end

  def filter
    # icd_code = params[:id]
    #
    # laterality = params[:laterality]
    #
    # gender = params[:gender]

    # ana_icd_diag = AnalyticsIcdDiagnosis.find_by(code: icd_code)
    #
    # @diagnosis_name = ana_icd_diag.try(:originalname)
    #
    #
    # @diagnosis_code = icd_code
    #
    #
    # if laterality.present? && gender.present?
    #   @patient_diagnosis = PatientDiagnosis.where(parent_icd: icd_code,laterality: laterality , gender: gender)
    # elsif laterality.present? && gender.blank?
    #   @patient_diagnosis = PatientDiagnosis.where(parent_icd: icd_code,laterality: laterality)
    # elsif laterality.blank? && gender.present?
    #   @patient_diagnosis = PatientDiagnosis.where(parent_icd: icd_code, gender: gender)
    # else
    #   @patient_diagnosis = PatientDiagnosis.where(parent_icd: icd_code)
    # end
    #
    #
  end

  def icd_types(icd_type)
    ['TranslatedIcdDiagnosis', 'SynonymIcdDiagnosis', 'CustomIcdDiagnosis', 'IcdDiagnosis', 'IcdDiagnosisCode', 'TopOrthoIcdDiagnosis', 'TopIcdDiagnosis'].select{|i_type| i_type == icd_type}.first
  end
  # EOF icd_types
end
