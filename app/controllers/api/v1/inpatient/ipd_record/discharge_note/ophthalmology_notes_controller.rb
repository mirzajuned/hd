module Api
  module V1
    class Inpatient::IpdRecord::DischargeNote::OphthalmologyNotesController < Inpatient::IpdRecord::DischargeNotesController
      before_action :department, only: [:new, :create, :show, :edit, :update, :print]

      def new
        @url_path = "inpatient_ipd_record_discharge_note_ophthalmology_notes_path"
        super
      end

      def create
        super
      end

      def show
        super
      end

      def edit
        @url_path = "inpatient_ipd_record_discharge_note_ophthalmology_note_path"
        super
      end

      def update
        super
      end

      def print
        super
      end

      def print_medications
        super
      end

      private

      def department
        @department = "Ophthalmology"
        @department_id = "309988001"
        @department_notes = "ophthalmology_notes"
      end

      # super calls inpatient/ipd_record/discharge_notes_controller.rb
    end
  end
end
