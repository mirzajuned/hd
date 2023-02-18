module Errors
  class AbstractError < StandardError
    attr_reader :message
    attr_reader :status, :type, :date

    def initialize(message, status)
      @message = message
      @status = status
      super(message)
    end
  end

  ValidationError = Class.new(AbstractError)

  class NoParams < ValidationError
    def initialize(message = 'No Data Received', status = 'Failed')
      super(message, status)
    end
  end

  class FieldMissing < ValidationError
    def initialize(message, status = 'Failed')
      message += ' Not Found'
      super(message, status)
    end
  end

  class InvalidLength < ValidationError
    def initialize(message, max_length, min_length = nil, status = 'Failed')
      min_length = max_length if min_length.nil?
      message = if min_length == max_length
                  "#{message}: Length Invalid. Expected Length: #{max_length}"
                else
                  "#{message}: Length Invalid. Expected Length: between #{min_length}-#{max_length}"
                end
      super(message, status)
    end
  end

  class FindByNil < ValidationError
    def initialize(model, fields, status = 'Failed')
      message = "No #{model} Exists with this #{fields}"
      super(message, status)
    end
  end

  class HasRole < ValidationError
    def initialize(role, status = 'Failed')
      message = "User is not #{role}"
      super(message, status)
    end
  end

  class AppointmentAlreadyExists < ValidationError
    def initialize(message, mrno, status = 'Failed')
      message = "Appointment Already Exists on #{message} with MRNo: #{mrno}"
      super(message, status)
    end
  end

  class AdmissionAlreadyExists < ValidationError
    def initialize(message, mrno, status = 'Failed')
      message = "Admission Already Exists on #{message} with MRNo: #{mrno}"
      super(message, status)
    end
  end

  class AppointmentIdAlreadyExists < ValidationError
    def initialize(message, status = 'Failed')
      message = "Appointment Already Exists with ID: #{message}"
      super(message, status)
    end
  end

  # class InvalidAppointmentId < ValidationError
  #   def initialize(message, status = 'Failed')
  #     message += 'No Appointment Exists with this ID'
  #     super(message, status)
  #   end
  # end

  # class DateError < ValidationError
  #   def initialize(message, status = 'Failed')
  #     message = "Date Format Incorrect. Received as #{message}. Required Format dd/mm/yyyy(12/12/2017)"
  #     super(message, status)
  #   end
  # end

  # class TimeError < ValidationError
  #   def initialize(message, status = 'Failed')
  #     message = "Time Format Incorrect. Received as #{message}. Required Format hh:mm p(12:30 PM)"
  #     super(message, status)
  #   end
  # end

  # class AppointmentNotSaved < ValidationError
  #   def initialize(message = 'Appointment Failed to save', status = 'Failed')
  #     super(message, status)
  #   end
  # end

  # class AppointmentSaved < ValidationError
  #   def initialize(message = 'Appointment created', status = 'Success')
  #     super(message, status)
  #   end
  # end
end
