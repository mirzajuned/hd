module Api
  module V1
    class Inpatient::IpdRecord::ClinicalNote::OphthalmologyNotesController < Inpatient::IpdRecord::ClinicalNotesController
      before_action :department, only: [:new, :create, :show, :edit, :update, :print]

      def new
        @opd_records = PatientTimeline.where(patient_id: @patient.id, specalityname: 'ophthalmology', encountertype: 'OPD', :templatetype.nin => ["optometrist", "freeform"]).order('encounterdate DESC')
        @current_department = current_user.department.name.downcase
        @url = "/inpatient/ipd_record/clinical_note/#{@current_department}_notes"
        @method = "POST"
        super
      end

      def create
        super
      end

      def show
        super
      end

      def edit
        @opd_records = PatientTimeline.where(patient_id: @patient.id, specalityname: 'ophthalmology', encountertype: 'OPD', :templatetype.nin => ["optometrist", "freeform"]).order('encounterdate DESC')
        @current_department = current_user.department.name.downcase
        @url = "/inpatient/ipd_record/clinical_note/#{@current_department}_notes/#{@ipdrecord.id}"
        @method = "PATCH"
        super
      end

      def update
        super
      end

      def print
        super
      end

      private

      def department
        @current_user = current_user
        @current_facility = current_facility
        @department = "Ophthalmology"
        @department_id = "309988001"
        @department_notes = "ophthalmology_notes"
      end

      # super calls inpatient/ipd_record/clinical_notes_controller.rb
    end
  end
end
