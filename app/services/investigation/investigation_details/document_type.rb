module Investigation
  module InvestigationDetails
    class DocumentType
      def initialize(investigation_id)
        @investigation = Investigation::InvestigationDetail.find(investigation_id)
      end

      def get
        if @investigation._type.to_s == "Investigation::Laboratory"
          @doc_type = "LabRecord"
        elsif @investigation._type.to_s == "Investigation::Radiology"
          @doc_type = "RadiologyRecord"
        elsif @investigation._type.to_s == "Investigation::Ophthal"
          @doc_type = 'OphthalmologyRecord'
        end
      end

      def get_ehr_investigation_type
        if @investigation._type.to_s == "Investigation::Laboratory"
          @doc_type = "EhrInvestigation::LaboratoryRecord"
        elsif @investigation._type.to_s == "Investigation::Radiology"
          @doc_type = "EhrInvestigation::RadiologyRecord"
        elsif @investigation._type.to_s == "Investigation::Ophthal"
          @doc_type = 'EhrInvestigation::OphthalmologyRecord'
        end
      end
    end
  end
end
