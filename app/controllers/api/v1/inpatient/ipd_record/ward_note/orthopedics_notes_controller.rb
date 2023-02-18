module Api
  module V1
    class Inpatient::IpdRecord::WardNote::OrthopedicsNotesController < Inpatient::IpdRecord::WardNotesController
      before_action :department, only: ['index', 'new', 'create', 'edit', 'update']

      def index
        super
      end

      def new
        @url_path = "inpatient_ipd_record_ward_note_orthopedics_notes_path"
        super
      end

      def create
        super
      end

      def edit
        @url_path = "inpatient_ipd_record_ward_note_orthopedics_note_path"
        super
      end

      def update
        super
      end

      private

      def department
        @department = "Orthopedics"
        @department_id = "309989009"
        @department_notes = "orthopedics_notes"
      end

      # super calls inpatient/ipd_record/ward_notes_controller.rb
    end
  end
end
