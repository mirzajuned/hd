module Mis::NewClinicalReports::Opd
  class UserRoleWiseTatReportRake
    class << self

      def call(start_date, end_date, organisation_ids)
        mis_logger = Logger.new("#{Rails.root}/log/mis_opd_logger.log")
        @start_date = start_date
        @end_date = end_date
        @organisation_ids = organisation_ids
        list_view = OpdClinicalWorkflow.collection.aggregate(query).to_a
      end


      private

      def query

      end


    end
  end
end