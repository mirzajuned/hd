module Api
  module V1
    class Inpatient::IpdRecord::OperativeNote::OrthopedicsNotesController < Inpatient::IpdRecord::OperativeNotesController
      before_action :department, only: [:new, :create, :show, :edit, :update, :print]

      def new
        @url_path = "inpatient_ipd_record_operative_note_orthopedics_notes_path"
        super
      end

      def create
        super
      end

      def show
        super
      end

      def edit
        @url_path = "inpatient_ipd_record_operative_note_orthopedics_note_path"
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
        @department = "Orthopedics"
        @department_id = "309989009"
        @department_notes = "orthopedics_notes"
      end

      # super calls inpatient/ipd_record/operative_notes_controller.rb
    end
  end
end
