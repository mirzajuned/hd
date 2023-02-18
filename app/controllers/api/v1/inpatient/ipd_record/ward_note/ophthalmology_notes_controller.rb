module Api
  module V1
    class Inpatient::IpdRecord::WardNote::OphthalmologyNotesController < Inpatient::IpdRecord::WardNotesController
      before_action :department, only: ['index', 'new', 'create', 'edit', 'update']

      def index
        super
      end

      def new
        @url_path = "inpatient_ipd_record_ward_note_ophthalmology_notes_path"
        super
      end

      def create
        super
      end

      def edit
        @url_path = "inpatient_ipd_record_ward_note_ophthalmology_note_path"
        super
      end

      def update
        super
      end

      private

      def department
        @department = "Ophthalmology"
        @department_id = "309988001"
        @department_notes = "ophthalmology_notes"
      end

      # super calls inpatient/ipd_record/ward_notes_controller.rb
    end
  end
end