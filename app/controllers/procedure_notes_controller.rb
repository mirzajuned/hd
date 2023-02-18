class ProcedureNotesController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :procedure_note, only: [:edit, :update, :destroy]
  before_action :find_specialties, only: [:new, :edit]

  def index
    @level = "user"
    respond_to do |format|
      format.js {}
    end
  end

  def new
    @procedure_note = ProcedureNote.new
    @path = "New"
    @level = params[:level]
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @level = params[:level]
    find_specialties
    @procedure_note = ProcedureNote.new(procedure_params)

    if @procedure_note.save!
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "New"
      respond_to do |format|
        format.js { render :new }
        format.json { render json: @procedure_note.errors }
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
    if @procedure_note.update_attributes(procedure_params)
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "Edit"
      respond_to do |format|
        format.js { render :edit }
        format.json { render json: @procedure_note.errors }
      end
    end
  end

  def destroy
    @level = params[:level]
    @procedure_note.update_attributes(is_active: false)
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

  def get_organisation_procedure_notes
    @level = "organisation"
  end

  def get_facility_procedure_notes
    @level = "facility"
  end

  private

  def procedure_params
    params.require(:procedure_note).permit(:name, :proceduretext, :user_id, :facility_id, :specialty_id, :organisation_id, :level)
  end

  def procedure_note
    @procedure_note = ProcedureNote.find_by(id: params[:id], level: params[:level])
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
    @procedure_notes_count = ProcedureNote.where(is_active: true, level: @level, user_id: current_user.id, :name => %r[#{params[:sSearch]}]).count
    @procedure_notes = ProcedureNote.where(is_active: true, level: @level, user_id: current_user.id, :name => %r[#{params[:sSearch]}])
                                    .limit(params[:iDisplayLength])
                                    .offset(params[:iDisplayStart])
                                    .order(created_at: :desc)
    @total_procedure_note_count = ProcedureNote.where(is_active: true, user_id: current_user.id, level: @level).count
  end

  def facility_level_data
    @procedure_notes_count = ProcedureNote.where(is_active: true, level: @level, facility_id: current_facility.id, :name => %r[#{params[:sSearch]}]).count
    @procedure_notes = ProcedureNote.where(is_active: true, level: @level, facility_id: current_facility.id, :name => %r[#{params[:sSearch]}])
                                    .limit(params[:iDisplayLength])
                                    .offset(params[:iDisplayStart])
                                    .order(created_at: :desc)
    @total_procedure_note_count = ProcedureNote.where(is_active: true, facility_id: current_facility.id, level: @level).count
  end

  def organisation_level_data
    @procedure_notes_count = ProcedureNote.where(is_active: true, level: @level, organisation_id: current_user.organisation_id, :name => %r[#{params[:sSearch]}]).count
    @procedure_notes = ProcedureNote.where(is_active: true, level: @level, organisation_id: current_user.organisation_id, :name => %r[#{params[:sSearch]}])
                                    .limit(params[:iDisplayLength])
                                    .offset(params[:iDisplayStart])
                                    .order(created_at: :desc)
    @total_procedure_note_count = ProcedureNote.where(is_active: true, organisation_id: current_user.organisation_id, level: @level).count
  end
end
