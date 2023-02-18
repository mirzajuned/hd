module Patients
  module Summary
    class TimelineService
      def self.call(params = {})
        pst = PatientSummaryTimeline.create(params)
      end
    end
  end
end
