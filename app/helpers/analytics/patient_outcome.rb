module Analytics
  module PatientOutcome
    class LogmarValues
      def logmar_values_far
        log_mar_far = {
          "PL+" => "1.7781512503836",
          "PL-" => "1.7781512503836",
          "FL" => "1.7781512503836",
          "HM" => "1.7781512503836",
          "CFCF" => "1.7781512503836",
          "FC" => "1.7781512503836",
          "1/60" => "1.7781512503836",
          '2/60' => "1.4771212547197",
          "3/60" => "1.301029995664",
          "4/60" => "1.1760912590557",
          "5/60" => "1.0791812460476",
          "6/60" => "1",
          "6/36" => "0.77815125038364",
          "6/24" => "0.60205999132796",
          "6/18" => "0.47712125471966",
          "6/12" => "0.30102999566398",
          "6/9" => "0.17609125905568",
          "6/6" => "0",
        }
        return log_mar_far
      end

      def logmar_values_near
        log_mar_near = {
          "N5" => "0.17609125905568",
          "N6" => "0.30102999566398",
          "N8" => "0",
          "N10" => "0.47712125471966",
          "N12" => "0.60205999132796",
          "N14" => "0.69897000433602",
          "N18" => "0.47712125471966",
          "N24" => "0.60205999132796",
          "N36" => "0.77815125038364",
          "<N36" => "1",
          "<6/60" => "1.7781512503836",
          "6/60" => "1",
          "6/36" => "0.77815125038364",
          "6/24" => "0.60205999132796",
          "6/18" => "0.47712125471966",
          "6/12" => "0.30102999566398",
          "6/9" => "0.17609125905568",
          "6/6" => "0",
        }
        return log_mar_near
      end

      def percentage_change_in_vision(before, after)
        ((before.to_f - after.to_f) / before.to_f) * 100
      end

      def cornea_procedures
        cornea_procedures = {
          "312965008" => "LASIK",
          "312965008B" => "Femto-LASIK",
          "312965008C" => "ReLex SMILE",
          "415839004" => "LASIK with wavefront",
          "397516006" => "PRK",
          "414540003" => "Phakic ICL",
          "415282007" => "Clear lens Extraction",
          "415146006" => "Phakic IOL Implant",
        }
      end

      def cataract_procedures
        cataract_procedures = {
          "84149000A" => "Phaco with foldable IOL implant",
          "84149000B" => "Phaco with PMMA IOL implant",
          "84149000C" => "Phaco without IOL implant",
          "419767009" => "Micro Phaco with fold IOL implant",
          "417493007A" => "SICS with PMMA IOL implant",
          "417493007B" => "SICS with foldable IOL implant",
          "417493007C" => "SICS without IOL implant",
          "13793006" => "ECCE with IOL implant",
          "397558009" => "Phaco with Multifocal IOL implant",
          "415730006" => "Phaco with Toric IOL implant",
          "65171000119107" => "Secondary IOL implant",
        }
      end
    end
  end
end
