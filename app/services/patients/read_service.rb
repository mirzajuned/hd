module Patients
  class ReadService
    def self.call(params)
      @patient = Patient.find_by(id: params) || Patient.new

      return @patient
    end
  end
end
