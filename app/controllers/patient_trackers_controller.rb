class PatientTrackersController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id])
    @patient_tracker = PatientTracker.new
    respond_to do |format|
      format.js { render 'form' }
    end
  end

  def create
    @patient_tracker = PatientTracker.new(patient_tracker_params)

    if @patient_tracker.save!
      if @patient_tracker.tracker_type == "Date"
        end_date_field
      elsif @patient_tracker.tracker_type == "Session"
        @new_array = @patient_tracker.session_dates << Date.current
        @patient_tracker.update(session_dates: @new_array)
      end
      respond_to do |format|
        format.js { render 'close' }
      end
    end
  end

  def edit
    @patient = Patient.find(params[:patient_id])
    @patient_tracker = PatientTracker.find(params[:id])
    respond_to do |format|
      format.js { render 'form' }
    end
  end

  def update
    @patient_tracker = PatientTracker.find(params[:id])

    if @patient_tracker.update_attributes(patient_tracker_params)
      if @patient_tracker.tracker_type == "Date"
        end_date_field
      elsif @patient_tracker.tracker_type == "Session"
        @new_array = @patient_tracker.session_dates << Date.current
        @patient_tracker.update(session_dates: @new_array)
      end
      respond_to do |format|
        format.js { render 'close' }
      end
    end
  end

  def destroy
    @patient_tracker = PatientTracker.find(params[:id])
    @patient_tracker.update(tracker_removed: true)
    respond_to do |format|
      format.js { render 'close' }
    end
  end

  private

  def patient_tracker_params
    params.require(:patient_tracker).permit(:description, :tracker_type, :start_date, :end_date, :count, :unit, :current_session, :patient_id, :user_id, :facility_id, :organisation_id)
  end

  def end_date_field
    @unit = @patient_tracker.unit
    @count = @patient_tracker.count
    @start_date = @patient_tracker.start_date
    if @unit == "Day"
      @end_date = @start_date + @count.days
    elsif @unit == "Week"
      @end_date = @start_date + @count.weeks
    elsif @unit == "Month"
      @end_date = @start_date + @count.months
    end
    @patient_tracker.update(end_date: @end_date)
  end
end
