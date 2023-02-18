class PatientSelfHistoriesController < ApplicationController
  before_action :authorize
  before_action :find_patient_appointment, only: [:index, :template_filter, :last_history]
  def index
    @patient_self_histories = PatientSelfHistory.where(patient_id: @patient.id).order_by('created_at DESC')
  end

  def template_filter
  end

  def last_history
    @patient_self_histories = PatientSelfHistory.where(patient_id: @patient.id).order_by('created_at DESC').limit(1)
  end

  private

  def find_patient_template_summary_timeline
    # @patient_report = PatientSummaryTimeline.where(patient_id: @patient.id, :primary_model.in => ['OpdRecord','Inpatient::IpdRecord'], is_active: true).order(encounter_date: :desc)
    # @patient_timeline_dates = @patient_report.group_by(&:encounter_date)
  end

  def find_patient_appointment
    @patient = Patient.find(params[:patient_id])
    # @appointment = Appointment.find_by(patient_id: @patient.id)
  end
end
