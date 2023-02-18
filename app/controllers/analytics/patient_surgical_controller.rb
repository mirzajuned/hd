class Analytics::PatientSurgicalController < ApplicationController
  before_action :authorize
  before_action :set_user_facility
  before_action :get_analytics_filters
  before_action :set_params_hash
  def index
    # complication_wise data

    @facility_name_label, @complicated_surgery, @not_complicated_surgery, @all_facility_name_complications, @all_complicated_surgery, @all_not_complicated_surgery = Analytics::PartialData::PatientOutcome.marked_complicated_data(@params_hash)
    # emergency vs elective data
    @facility_name_label_emergency, @emergency, @elective, @not_filled, @all_facility_name_labels_emergency, @all_emergency, @all_elective, @all_not_filled = Analytics::PartialData::PatientOutcome.facility_wise_elective_emergency(@params_hash)
    # patient count bcva age near
    @labels_eye_sight_near, @not_complicated_data_near, @complicated_data_near = Analytics::PartialData::PatientOutcome.patients_count_bcva_near(@params_hash)

    # patient count bcva age far
    @labels_eye_sight_far, @not_complicated_data_far, @complicated_data_far = Analytics::PartialData::PatientOutcome.patients_count_bcva_far(@params_hash)

    # patient count by surgery type
    @surgery_label, @count_data = Analytics::PartialData::PatientOutcome.patient_count_surgery_type(@params_hash)

    @labels_cornea, @cornea_count_data, @labels_cataract, @cataract_count_data = Analytics::PartialData::PatientOutcome.patient_count_by_cornia_surgery_type(@params_hash)

    @labels_cataract_gender, @cataract_male, @cataract_female, @cataract_trans, @cataract_other, @labels_cornea_gender, @cornea_male, @cornea_female, @cornea_trans, @cornea_other = Analytics::PartialData::PatientOutcome.patient_count_by_diagnosis_gender(@params_hash)

    @laterality_labels, @male_data, @female_data, @trans_data, @other_data = Analytics::PartialData::PatientOutcome.patients_count_by_laterality(@params_hash)

    @labels_cataract_age, @cataract_0_20, @cataract_21_40, @cataract_41_60, @cataract_61, @labels_cornea_age, @cornea_0_20, @cornea_21_40, @cornea_41_60, @cornea_61 = Analytics::PartialData::PatientOutcome.patients_count_by_surgery_age_cataract(@params_hash)
  end

  private

  def set_user_facility
    @current_facility = current_facility
    @current_user = current_user
  end

  def get_analytics_filters
    @organisation_id = current_facility.organisation_id

    @facility_id = params[:filtered_facility].present? ? params[:filtered_facility] : current_facility.id
    @analytics_to_date = params[:analytics_to_date].present? ? params[:analytics_to_date] : Date.current - 6.days
    @analytics_from_date = params[:analytics_from_date].present? ? params[:analytics_from_date] : Date.current
  end

  def set_params_hash
    @params_hash = {
      "organisation_id" => @current_facility.organisation_id,
      "facility_id" => @facility_id,
      "analytics_to_date" => @analytics_to_date,
      "analytics_from_date" => @analytics_from_date
    }
    # check if date is start and end dates are same

    if @analytics_from_date == @analytics_to_date
      @todays_data = true
    end
  end
end
