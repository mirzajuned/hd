module Patients
  module Summary
    module Helpers
      module Other
        class CertificateService
          def self.call(params = {})
            Patients::Summary::TimelineService.call(params)
          end
        end
      end
    end
  end
end
