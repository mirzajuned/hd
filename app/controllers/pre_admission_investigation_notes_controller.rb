class PreAdmissionInvestigationNotesController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :pre_admission_investigation_note, only: [:edit, :update, :destroy]
  before_action :find_specialties, only: [:new, :edit]

  def index
    @level = "organisation"
    respond_to do |format|
      format.js {}
    end
  end

  def new
    @pre_admission_investigation_note = PreAdmissionInvestigationNote.new
    @path = "New"
    @level = params[:level]
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @level = params[:level]
    find_specialties
    @pre_admission_investigation_note = PreAdmissionInvestigationNote.new(notes_params)

    if @pre_admission_investigation_note.save!
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "New"
      respond_to do |format|
        format.js { render :new }
        format.json { render json: @pre_admission_investigation_note.errors }
      end
    end
  end

  def edit
    @path = "Edit"
    @level = params[:level]
    respond_to do |format|
      format.js {}
    end
  end

  def update
    @level = params[:level]
    if @pre_admission_investigation_note.update_attributes(notes_params)
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "Edit"
      respond_to do |format|
        format.js { render :edit }
        format.json { render json: @pre_admission_investigation_note.errors }
      end
    end
  end

  def destroy
    @level = params[:level]
    @pre_admission_investigation_note.update_attributes(is_active: false)
    respond_to do |format|
      format.js { render "close" }
    end
  end

  def data
    @level = params[:level]
    if @level == "organisation"
      organisation_level_data
    elsif @level == "facility"
      facility_level_data
    else
      user_level_data
    end

    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def get_organisation_pre_admission_investigation_notes
    @level = "organisation"
  end

  def get_facility_pre_admission_investigation_notes
    @level = "facility"
  end

  private

  def notes_params
    params.require(:pre_admission_investigation_note).permit(:name, :text, :user_id, :facility_id, :specialty_id, :organisation_id, :level)
  end

  def pre_admission_investigation_note
    @pre_admission_investigation_note = PreAdmissionInvestigationNote.find_by(id: params[:id], level: params[:level])
  end

  def find_specialties
    if params[:level] == "user"
      @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
      @level_name = current_user.fullname

    elsif params[:level] == "organisation"
      @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])
      @level_name = current_organisation["name"]

    elsif params[:level] == "facility"
      @available_specialties = Specialty.where(:id.in => current_facility.specialty_ids)
      @level_name = current_facility.name
    end
  end

  def user_level_data
    @pre_admission_investigation_notes_count = PreAdmissionInvestigationNote.where(is_active: true, level: @level, user_id: current_user.id, :name => %r[#{params[:sSearch]}]).count
    @pre_admission_investigation_notes = PreAdmissionInvestigationNote.where(is_active: true, level: @level, user_id: current_user.id, :name => %r[#{params[:sSearch]}])
                                           .limit(params[:iDisplayLength])
                                           .offset(params[:iDisplayStart])
                                           .order(created_at: :desc)
    @total_pre_admission_investigation_note_count = PreAdmissionInvestigationNote.where(is_active: true, user_id: current_user.id, level: @level).count
  end

  def facility_level_data
    @pre_admission_investigation_notes_count = PreAdmissionInvestigationNote.where(is_active: true, level: @level, facility_id: current_facility.id, :name => %r[#{params[:sSearch]}]).count
    @pre_admission_investigation_notes = PreAdmissionInvestigationNote.where(is_active: true, level: @level, facility_id: current_facility.id, :name => %r[#{params[:sSearch]}])
                                           .limit(params[:iDisplayLength])
                                           .offset(params[:iDisplayStart])
                                           .order(created_at: :desc)
    @total_pre_admission_investigation_note_count = PreAdmissionInvestigationNote.where(is_active: true, facility_id: current_facility.id, level: @level).count
  end

  def organisation_level_data
    @pre_admission_investigation_notes_count = PreAdmissionInvestigationNote.where(is_active: true, level: @level, organisation_id: current_user.organisation_id, :name => %r[#{params[:sSearch]}]).count
    @pre_admission_investigation_notes = PreAdmissionInvestigationNote.where(is_active: true, level: @level, organisation_id: current_user.organisation_id, :name => %r[#{params[:sSearch]}])
                                           .limit(params[:iDisplayLength])
                                           .offset(params[:iDisplayStart])
                                           .order(created_at: :desc)
    @total_pre_admission_investigation_note_count = PreAdmissionInvestigationNote.where(is_active: true, organisation_id: current_user.organisation_id, level: @level).count
  end
end
