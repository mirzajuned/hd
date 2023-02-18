class IpdManagementController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout 'loggedin'
  require 'spreadsheet'
  before_action :admission_details, only: [:index, :filter_index, :search_patient]

  def index; end

  def ipd_details
    @admission = AdmissionListView.find_by(id: params[:admission_id], facility_id: current_facility_id)
    @patient = Patient.find_by(id: @admission&.patient_id)
    @patientid = @patient.id
    @current_date = params[:current_date]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @all_trays = Inventory::Transaction::Tray.where(patient_id: @patientid, admission_id: @admission.admission_id,
                                                    is_canceled: false).order_by(created_at: 'desc')
  end

  def filter_index; end

  def search_patient; end

  private

  def admission_details
    query = params[:q].to_s
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    end_of_day = @current_date.strftime('%d/%m/%Y') + ' 23:59:59'
    @admissions = if params[:action] == 'search_patient'
                    AdmissionListView.where(facility_id: current_facility_id, patient_name: /#{Regexp.escape(query)}/i)
                                     .order('created_at DESC')
                  else
                    AdmissionListView.where(admission_date: @current_date..Time.zone.parse(end_of_day),
                                            facility_id: current_facility_id).order('created_at DESC')
                  end
    @processed_admissions = @admissions.where(is_tray_created: true)
    @un_processed_admissions = @admissions.where(is_tray_created: false)
    get_patient_params(@admissions.pluck(:patient_id))
  end

  def get_patient_params(patient_ids)
    patients = Patient.where(:id.in => patient_ids)
    @patient_fields = patients.map do |patient|
      age_year, age_month = patient.calculate_age(true)
      title_content = ''
      title_content += 'One Eyed' if patient.one_eyed == 'Yes'
      age_in_months = (age_year.to_i * 12) + age_month.to_i
      if age_year.present? && (49...960).exclude?(age_in_months)
        title_content += ' | ' if patient.one_eyed == 'Yes'
        title_content += age_year < 4 ? 'Baby' : 'Old Age'
      end
      bang = !title_content.empty?
      { id: patient.id, bang: bang, title: title_content }
    end
  end
end
