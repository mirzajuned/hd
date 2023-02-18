class PracticeMedicationListsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout 'loggedin'

  def new
    @level = params[:level].present? ? params[:level] : 'user'
    @medication_list = MyPracticeMedicationList.new
    find_specialties
    @selected_specialty = @available_specialties.first.id
  end

  def create
    @medication_list = MyPracticeMedicationList.new(practice_medication_list_params)
    @medication_list.save!
    respond_to do |format|
      format.js do
        params[:level] = @medication_list.level
        new
      end
    end
  end

  def edit_name
    @medication_list = MyPracticeMedicationList.find_by(id: params[:id])
    @level = params[:level]
    find_specialties
    @selected_specialty = @medication_list.specialty_id   
    respond_to do |format|
      format.js { render 'edit_medication_name', layout: false }
    end
  end

  def update
    @medication_list = MyPracticeMedicationList.find_by(id: params[:id])
    @medication_list.generic_names.delete_all
    @medication_list.medicine_class_name.delete_all
    @medication_list.update(practice_medication_list_params)
  end

  def add_excel_example
    respond_to do |format|
      format.js {}
    end
  end

  def download_excel
    send_file(
      "#{Rails.root}/public/Medication.xls",
      filename: 'Medication.xls',
      type: 'application/xls'
    )
  end

  def destroy
    medication_list = MyPracticeMedicationList.find_by(id: params[:id])
    medication_list.delete if medication_list.present?
    @level = params[:level]
  end

  def import_excel
    if params[:bulk_file].present?
      bulk_file_details = params[:bulk_file].tempfile
      @level = params[:level]
      Spreadsheet.client_encoding = 'UTF-8'
      if File.extname(bulk_file_details) == '.xls'
        bulk_file = Spreadsheet.open bulk_file_details.path
        uploaded_data = bulk_file.worksheet 0
        uploaded_data.each_with_index do |row, _index|
          if row[0].present?
            MyPracticeMedicationList.create!(name: row[0], contents: row[1], med_type: row[2], level: @level, organisation_id: current_user.organisation_id, facility_id: current_facility.id, user_id: current_user.id)
          end
        end
      end
      FileUtils.rm bulk_file_details.path
    end

    respond_to do |format|
      format.js {}
    end
  end

  def upload_medication_excel
    @level = params[:level].present? ? params[:level] : level
  end

  def add_medication_list
    @level = params[:level].present? ? params[:level] : 'user'
    @medication_list = MyPracticeMedicationList.new

    find_specialties
    @selected_specialty = @available_specialties.first.id
  end

  def save_medication_list
    @level           = params[:level]
    medication_lists = params[:my_practice_medication_list]
    organisation_id  = current_user.organisation_id
    facility_id      = current_facility.id
    user_id = current_user.id
    medication_lists.each do |_index, med_list|
      if med_list[:name].present?
        med_list_params = { name: med_list[:name], contents: med_list[:contents], med_type: med_list[:med_type], organisation_id: organisation_id, facility_id: facility_id, user_id: user_id, level: @level, specialty_id: med_list[:specialty_id] }
        medication_list = MyPracticeMedicationList.create!(med_list_params)
      end
    end
  end

  # def get_organisation_medication_list
  #   @level = "organisation"
  #   @medication_lists = MyPracticeMedicationList.where(:organisation_id => current_user.organisation_id,level: "organisation")
  # end

  private

  def practice_medication_list_params
    params.require(:my_practice_medication_list).permit(
      :name, :contents, :med_type, :organisation_id, :facility_id, :user_id, :level, :specialty_id,
      generic_names_attributes: [:name, :quantity, :unit, :generic_id],
      medicine_class_name_attributes: [:medicine_class, :medicine_class_id]
    )    
  end

  def add_medication_lists_params
    params.require(:my_practice_medication).permit(my_practice_medication_lists_attributes: [:name, :user_id])
  end

  def update_medication_name
    params.require(:my_practice_medication_list).permit(:name, :user_id, :id, :contents, :med_type)
  end

  def find_specialties
    if params[:level] == 'user'
      @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
      @level_name = current_user.fullname

    elsif params[:level] == 'organisation'
      @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
      @level_name = current_organisation['name']

    elsif params[:level] == 'facility'
      @available_specialties = Specialty.where(:id.in => current_facility.specialty_ids)
      @level_name = current_facility.name
    end
  end

  def medication_lists_data(level)
    if level == 'user'
      MyPracticeMedicationList.where(user_id: current_user.id, level: 'user', is_deleted: false)
    elsif level == 'organisation'
      MyPracticeMedicationList.where(organisation_id: current_user.organisation_id, level: 'organisation', is_deleted: false)
    elsif level == 'facility'
      MyPracticeMedicationList.where(facility_id: current_facility.id, level: 'facility', is_deleted: false)
    end
  end
end
