class PatientManagementController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout "loggedin"
  require 'spreadsheet'
  require 'fileutils'
  require 'will_paginate/array'

  def home
    @current_date = Date.parse("#{Date.current}", "%d-%B-%Y")
    @datepicker_date = "#{Date.parse("#{Date.current}", "%d-%B-%Y").strftime("%Y-%m-%d")}"
    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def add_excel_example
    respond_to do |format|
      format.js {}
    end
  end

  def download_excel
    send_file(
      "#{Rails.root}/public/Patient_Data.xls",
      filename: "Patient_Data.xls",
      type: "application/xls"
    )
  end

  def add_excel
    # respond_to do |format|
    #   format.js {}
    # end
  end

  def import_excel
    bulk_file_details = params[:bulk_file].tempfile
    Spreadsheet.client_encoding = 'UTF-8'
    bulk_file = Spreadsheet.open bulk_file_details.path
    uploaded_data = bulk_file.worksheet 0
    uploaded_data.each_with_index do |row, index|
      patient = Patient.new(:fullname => row[0], :mobilenumber => row[1], :gender => row[2], :age => row[3], :dob => row[4], :address_1 => row[5], :address_2 => row[6], :city => row[7], :state => row[8], :pincode => row[9], :email => row[10], :maritalstatus => row[11], :reg_date => row[12], :blood_group => row[13], :emergencycontactname => row[14], :emergencymobilenumber => row[15], :reg_hosp_ids => [current_user.organisation_id.to_s])
      if patient.save
        PatientIdentifier.create(:patient_id => patient.id, :organisation_id => current_user.organisation_id, :patient_org_id => CommonHelper::get_patient_org_identifier(current_user))
      end
      if @patient.dob.present?
        patient_birthday = PatientBirthday.find_by(patient_id: @patient.id)
        if patient_birthday
          patient_birthday.update(dob: @patient.dob.strftime("%d%m"))
        else
          PatientBirthday.create(patient_id: @patient.id, dob: @patient.dob.strftime("%d%m"))
        end
      end
    end
    FileUtils.rm bulk_file_details.path
    respond_to do |format|
      format.js {}
    end
  end

  def filter_patient_birthday
    @birthday_patients = []
    @upcoming_birthdays = []
    @patients = Patient.where(:reg_hosp_ids => [current_user.organisation_id.to_s])
    @patients.each do |patient|
      if !patient.dob.blank?
        if Date.parse(patient.dob.to_s).strftime("%d%m") ==  Date.current.strftime("%d%m")
          @birthday_patients << patient
        elsif Date.parse(patient.dob.to_s).strftime("%d") >= Date.current.strftime("%d") and Date.parse(patient.dob.to_s).strftime("%m") == Date.current.strftime("%m")
          @upcoming_birthdays << patient
        end
      end
    end

    respond_to do |format|
      format.js {}
    end
  end

  def patient_alphabetically
    @patients = Patient.where(:reg_hosp_ids => [current_user.organisation_id.to_s], :fullname => /^a/)
    if params["letter"] != ''
      letter = params["letter"]
      capital_letter = letter.try(:upcase)
      @patients = Patient.where(:reg_hosp_ids => [current_user.organisation_id.to_s], :fullname => /^#{letter}|#{capital_letter}/)
    end
    respond_to do |format|
      format.js {}
    end
  end

  def followup_patient
    @patient_followups = PatientManagementFollowup.where(user_id: current_user.id).order('followup_date ASC')
    @patient_followups = @patient_followups.paginate(:page => page, :per_page => per_page)
    @total_appointment_count = PatientManagementFollowup.where(user_id: current_user.id).count
    patients_list = @patient_followups.map(&:patient_id)
    @sEcho = params[:sEcho]
    if params[:sSearch] != ''
      @patients = Patient.where(:reg_hosp_ids => [current_user.organisation_id.to_s], :id.in => patients_list, :fullname => %r[#{params[:sSearch]}])
      @flag = 1
    end
    if params[:sSearch] != ''
      @appointment_list_count = @patients.count
    else
      @appointment_list_count = PatientManagementFollowup.where(user_id: current_user.id).count
    end
    respond_to do |format|
      format.js {}
    end
  end

  def followup_long_overdue
    @patients = PatientManagementFollowup.where(user_id: current_user.id)
    @patients_overdue = []

    @patients.each do |patient|
      start_time = Date.current
      end_time = patient.followup_date
      if start_time > end_time
        if TimeDifference.between(start_time, end_time).in_days >= 1
          @patients_overdue << patient
        end
      end
    end
    respond_to do |format|
      format.js {}
    end
  end

  private

  def page
    params[:iDisplayStart].to_i / per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 25
  end
end
################ REMOVE THE BELOW CODE AFTER YOU PERFECT DATA UPLOAD ######################
# org.users.first.fullname = row[0]
# @org.users.first.email = row[1]
# @org.users.first.username = row[3]
# @org.users.first.password = row[4]
# @org.users.first.department_id = row[5]
# params[:patient][:reg_hosp_ids] = [current_user.organisation_id.to_s]
#
# @patient = Patient.new(appointment_patient_create_params)
# if @patient.save!
#   PatientIdentifier.create(:patient_id => @patient.id,:organisation_id => current_user.organisation_id,:patient_org_id => CommonHelper::get_patient_org_identifier(current_user))
# end
# if params[:patient][:appointments_attributes]['0'][:ref_doc_name]!='' and !ReferringDoctor.where(name: params[:patient][:appointments_attributes]['0'][:ref_doc_name],place: params[:patient][:appointments_attributes]['0'][:ref_doc_place],user_id: current_user.id).exists?
#   @referring_doc = ReferringDoctor.new
#   @referring_doc[:name] = params[:patient][:appointments_attributes]['0'][:ref_doc_name]
#   @referring_doc[:place] = params[:patient][:appointments_attributes]['0'][:ref_doc_place]
#   @referring_doc[:user_id] = current_user.id
#   @referring_doc.save
# end
#
# def appointment_patient_create_params
#   params.require(:patient).permit(:fullname, :gender,:dob, :age, :mobilenumber,:email, :blood_group,:address_1,:address_2,:city,:state,:pincode,:emergencycontactname, :emergencymobilenumber, :maritalstatus, :specialstatus, :occupation, :reg_hosp_ids => [], appointments_attributes: [:appointment_type_id,:display_id, :appointmentdate, :start_time,:end_time,:departmenttype,:appointmentstatus, :user_id,:department_id, :facility_id,:doctor,:ref_doc_name,:ref_doc_place],patientassets_attributes: [:asset_path],patient_history_attributes: [ :patient_id, :patientid, :templatetype, :templateid, patientpersonalhistory_attributes: [problems: [] ], patientallergyhistory_attributes: [:others, antimicrobialagents: [], antifungalagents: [], antiviralagents: [], contact: [], food: [] ] ])
# end
