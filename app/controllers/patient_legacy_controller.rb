require 'date'
require 'time'
class PatientLegacyController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def old_data_list
    @legacy_opd_clinical_note_id = params[:id]
    @legacy_patient_id = params[:legacy_patient_id]
    @new_patient_id = params[:new_patient_id]

    @legacy_opd_clinical_note = LegacyOpdClinicalNote.find(@legacy_opd_clinical_note_id)

    respond_to do |format|
      format.js { render "opd_data_list", layout: false }
    end
  end

  def old_prescription_list
    @legacy_prescription_id = params[:id]
    @legacy_patient_id = params[:legacy_patient_id]
    @new_patient_id = params[:new_patient_id]

    @legacy_prescription = LegacyPrescription.find(@legacy_prescription_id)

    respond_to do |format|
      format.js { render "prescription_data_list", layout: false }
    end
  end

  def old_surgery_list
    @legacy_opd_clinical_note_id = params[:id]
    @legacy_patient_id = params[:legacy_patient_id]
    @new_patient_id = params[:new_patient_id]

    @legacy_ipd_clinical_note = LegacyIpdClinicalNote.find(@legacy_opd_clinical_note_id)

    respond_to do |format|
      format.js { render "surgery_data_list", layout: false }
    end
  end

  def old_appointment_list
    @legacy_opd_clinical_note_id = params[:id]
    @legacy_patient_id = params[:legacy_patient_id]
    @new_patient_id = params[:new_patient_id]

    @legacy_ipd_clinical_note = LegacyApppointment.find(@legacy_opd_clinical_note_id)

    respond_to do |format|
      format.js { render "old_appointment_list", layout: false }
    end
  end
end
