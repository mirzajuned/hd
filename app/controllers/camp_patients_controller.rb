class CampPatientsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html

  def search_patient_name
    r_query = params[:search]
    facility_id = params[:facility_id]
    camp_name = params[:camp_name]
    if camp_name.blank?
      @patientlist = CampPatient.where(organisation_id: current_user.organisation_id.to_s, facility_id: facility_id, fullname: /#{Regexp.escape(r_query)}/i).limit(8)
    else
      @patientlist = CampPatient.where(organisation_id: current_user.organisation_id.to_s, facility_id: facility_id, camp_username: camp_name, fullname: /#{Regexp.escape(r_query)}/i).limit(8)
    end
    render :json => @patientlist.pluck(:id, :fullname, :phone_number, :camp_patient_identifier, :camp_name, :patient_id, :sub_referral_type_id).to_json
    @facility = Facility.find_by(id: current_facility.id)
    @facility.update(search_type: params[:search_type])
  rescue => e
    render :json => [].to_json
  end

  def search_patient_mobile_no
    r_query = params[:search].delete(' ')
    facility_id = params[:facility_id]
    camp_name = params[:camp_name]
    if camp_name.blank?
      @patientlist = CampPatient.where(organisation_id: current_user.organisation_id.to_s, facility_id: facility_id, phone_number: /#{Regexp.escape(r_query)}/i).limit(8)
    else
      @patientlist = CampPatient.where(organisation_id: current_user.organisation_id.to_s, facility_id: facility_id, camp_username: camp_name, phone_number: /#{Regexp.escape(r_query)}/i).limit(8)
    end
    render :json => @patientlist.pluck(:id, :fullname, :phone_number, :camp_patient_identifier, :camp_name, :patient_id, :sub_referral_type_id).to_json
  end

  def search_patient_camp_id
    r_query = params[:search].delete(' ')
    facility_id = params[:facility_id]
    camp_name = params[:camp_name]
    if camp_name.blank?
      @patientlist = CampPatient.where(organisation_id: current_user.organisation_id.to_s, facility_id: facility_id, camp_patient_identifier: /#{Regexp.escape(r_query)}/i).limit(8)
    else
      @patientlist = CampPatient.where(organisation_id: current_user.organisation_id.to_s, facility_id: facility_id, camp_username: camp_name, camp_patient_identifier: /#{Regexp.escape(r_query)}/i).limit(8)
    end
    render json: @patientlist.pluck(:id, :fullname, :phone_number, :camp_patient_identifier, :camp_name, :patient_id,
                                    :sub_referral_type_id).to_json
  end

  def populate_facility_camps
    @camp = Camp.where(facility_id: params[:facility_id])
    render json: @camp.uniq.pluck(:username, :camp_name).to_json
  end
end
