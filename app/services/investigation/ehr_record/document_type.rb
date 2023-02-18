module Investigation
  module EhrRecord
    class DocumentType
      def initialize(record_id)
        @record = Investigation::Record.find_by(id: record_id)
      end

      def get
        if @record._type.to_s == "LabRecord"
          @doc_type = "EhrInvestigation::LaboratoryRecord"
        elsif @record._type.to_s == "RadiologyRecord"
          @doc_type = "EhrInvestigation::RadiologyRecord"
        elsif @record._type.to_s == "OphthalmologyRecord"
          @doc_type = 'EhrInvestigation::OphthalmologyRecord'
        end
      end
    end
  end
end
