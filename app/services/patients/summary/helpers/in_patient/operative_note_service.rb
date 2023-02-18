module Patients
  module Summary
    module Helpers
      module InPatient
        class OperativeNoteService
          def self.call(params = {})
            Patients::Summary::TimelineService.call(params)
          end
        end
      end
    end
  end
end
