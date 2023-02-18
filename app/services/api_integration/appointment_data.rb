class ApiIntegration::AppointmentData
  def create(appointment_id, client)
    sleep 5

    @appointment = ::Appointment.find_by(id: appointment_id)
    @appointment_data = ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment.integration_identifier.to_s, status_code: 200, method_type: 'Create')
    @doctor_employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
    @employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
    @mr_no = @appointment.try(:patient).try(:patient_mrn)
    @appointment_date = @appointment.try(:appointmentdate).try(:strftime, '%d/%m/%Y')
    @appointment_time = @appointment.try(:start_time).try(:localtime).try(:strftime, '%I:%M %p')
    @appointment_datetime = "#{@appointment_date} #{@appointment_time}"
    @abbreviation = @appointment.facility.try(:abbreviation)
    @method_type = 'Create'

    LoggerService.new.integration(@appointment_data.to_json, 'integration', '@appointment_data')

    if @appointment.created_from != 'Integration'

      begin
        url = Global.send(client)[Rails.env]['url']
        auth_user = Global.send(client)[Rails.env]['user']
        password = Global.send(client)[Rails.env]['password']
        tokenlabel = 'Authorization'
        token = 'Basic ' + Base64.strict_encode64("#{auth_user}:#{password}")

        payload = {}

        payload['mr_no'] = @mr_no
        payload['created_by'] = @employee_id.to_s
        payload['doctor_employee_id'] = @doctor_employee_id.to_i
        payload['appointment_date'] = @appointment_datetime
        payload['branch'] = @abbreviation
        payload['id'] = @appointment.try(:integration_identifier).to_s
        puts '==============================================payload====================', payload.to_json

        response = send_appointment_request(url, token, tokenlabel, payload)

        puts '==============================================response====================', response.to_json

        @appointment_integration_identifier = response.try(:[], 'appointment_id')
        # @external_identifier = response.try(:[], "response").try(:[], "data").try(:[], "id") || user.try(:external_identifier)
        @status = response.try(:[], 'result')
        @status_code = 200
        @response_code = response.try(:[], 'responseCode')
        @message = response.try(:[], 'message') || 'Success'
        @response = response
      rescue StandardError
        @appointment_integration_identifier = nil
        @status = 'Failed'
        @status_code = 500
        @response_code = 500
        @message = 'No Response Received'
        @response = {}
      end

      @response_received = ApiIntegration::Appointment::ResponseReceived.new(status: @status, status_code: @status_code, message: @message, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @mr_no)
      @response_received.save!

      puts '==============================================@response_received====================', @response_received.to_json

      appointment_data = {
        mr_no: @mr_no,
        doctor_employee_id: @doctor_employee_id,
        appointment_date: @appointment_datetime,
        employee_id: @employee_id,
        first_name: @appointment.patient.firstname,
        middle_name: @appointment.patient.middlename,
        last_name: @appointment.patient.lastname,
        mobile_number: @appointment.patient.mobilenumber,
        age: @appointment.patient.age,
        organisation_id: @appointment.organisation_id.to_s,
        facility_id: @appointment.facility_id.to_s,
        age_month: @appointment.patient.age_month,
        gender: @appointment.patient.gender,
        abbreviation: @appointment.facility.abbreviation,
        appointment_integration_identifier: @appointment_integration_identifier,
        appointment_integration_identifier_bson: @appointment.integration_identifier,
        sent_date: Date.current,
        sent_time: Time.current,
        request_type: 'Sent',
        method_type: @method_type,
        status: @status,
        status_code: @status_code,
        message: @message,
        number_of_retries: 0
      }

      @new_appointment_data = ApiIntegration::Appointment::Data.new(appointment_data)
      @new_appointment_data.save!

      puts '==============================================@@new_appointment_data====================', @new_appointment_data.to_json

    end
  end

  def update(appointment_id, client)
    sleep 5

    @appointment = ::Appointment.find_by(id: appointment_id)
    @appointment_data = ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment.integration_identifier.to_s, status_code: 200, method_type: 'Update')
    @doctor_employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
    @employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
    @mr_no = @appointment.try(:patient).try(:patient_mrn)
    @appointment_date = @appointment.try(:appointmentdate).try(:strftime, '%d/%m/%Y')
    @appointment_time = @appointment.try(:start_time).try(:localtime).try(:strftime, '%I:%M %p')
    @appointment_datetime = "#{@appointment_date} #{@appointment_time}"
    @abbreviation = @appointment.facility.try(:abbreviation)
    @method_type = 'Update'

    puts '==============================================initial_params=appointment====================', @appointment.to_json
    puts '==============================================initial_params=@appointment_data====================', @appointment_data.to_json

    begin
      url = Global.send(client)[Rails.env]['url']
      auth_user = Global.send(client)[Rails.env]['user']
      password = Global.send(client)[Rails.env]['password']
      tokenlabel = 'Authorization'
      token = 'Basic ' + Base64.strict_encode64("#{auth_user}:#{password}")

      payload = {}

      payload['mr_no'] = @mr_no
      payload['created_by'] = @employee_id.to_s
      payload['doctor_employee_id'] = @doctor_employee_id.to_i
      payload['appointment_date'] = @appointment_datetime
      payload['branch'] = @abbreviation
      payload['id'] = @appointment.try(:integration_identifier).to_s

      puts '==============================================token====================', token
      puts '==============================================payload====================', payload.to_json

      response = send_appointment_request(url, token, tokenlabel, payload)

      puts '==============================================response====================', response.to_json

      @appointment_integration_identifier = response.try(:[], 'appointment_id')
      @status = response.try(:[], 'result')
      @status_code = 200
      @response_code = response.try(:[], 'responseCode')
      @message = response.try(:[], 'message') || 'Success'
      @response = response
    rescue StandardError
      @appointment_integration_identifier = nil
      @status = 'Failed'
      @status_code = 500
      @response_code = 500
      @message = 'No Response Received'
      @response = {}
    end

    @response_received = ApiIntegration::Appointment::ResponseReceived.new(status: @status, status_code: @status_code, message: @message, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @mr_no)
    @response_received.save!

    puts '==============================================@response_received====================', @response_received.to_json

    appointment_data = {
      mr_no: @mr_no,
      doctor_employee_id: @doctor_employee_id,
      appointment_date: @appointment_datetime,
      employee_id: @employee_id,
      first_name: @appointment.patient.firstname,
      middle_name: @appointment.patient.middlename,
      last_name: @appointment.patient.lastname,
      mobile_number: @appointment.patient.mobilenumber,
      age: @appointment.patient.age,
      age_month: @appointment.patient.age_month,
      gender: @appointment.patient.gender,
      abbreviation: @appointment.facility.abbreviation,
      appointment_integration_identifier: @appointment_integration_identifier,
      appointment_integration_identifier_bson: @appointment.integration_identifier,
      sent_date: Date.current,
      sent_time: Time.current,
      request_type: 'Sent',
      method_type: @method_type,
      status: @status,
      status_code: @status_code,
      message: @message,
      number_of_retries: 0
    }

    @new_appointment_data = ApiIntegration::Appointment::Data.new(appointment_data)
    @new_appointment_data.save!

    puts '==============================================@@new_appointment_data====================', @new_appointment_data.to_json
  end

  def create_agarwal_integration_appointment_data(appointment_id)
    sleep 5
    @appointment = Appointment.find_by(id: appointment_id)
    @appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment.integration_identifier.to_s, status_code: 200, method_type: 'Create')
    @doctor_employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
    @employee_id = User.find_by(id: @appointment.user_id).try(:employee_id)
    @mr_no = @appointment.try(:patient).try(:patient_mrn)
    @appointment_datetime = @appointment.try(:start_time).try(:strftime, '%d/%m/%Y %I:%M %p')
    @method_type = 'Create'

    if @appointment.created_from != 'Integration'
      begin
        # Params to Send
        url = Global.ideamed[Rails.env]['url']
        user = Global.ideamed[Rails.env]['user']
        password = Global.ideamed[Rails.env]['password']
        payload = '{"mr_no": "' + @mr_no + '",
                      "doctor_employee_id": "' + @doctor_employee_id + '",
                      "appointment_date": "' + @appointment_datetime + '",
                      "created_by": "' + @employee_id + '",
                      "id": "' + @appointment_data.try(:appointment_integration_identifier).to_s + '" }'

        # '{"mr_no": "WFD-123",
        # "doctor_employee_id": "deepika",
        # "appointment_date": "' + @appointment_datetime + '",
        # "created_by": "apitestuser" }'

        request = RestClient::Request.execute(method: :post, url: url,
                                              user: user,
                                              password: password,
                                              payload: payload,
                                              headers: { 'Content-Type' => 'application/json' })

        @response = JSON.parse(request)

        @mr_no = (@response['mr_no'] if @response['mr_no'].present?) || @mr_no
        @appointment_integration_identifier = @response['appointment_id']
        @status = @response['result']
        @status_code = 200
        @message = @response['message']
      rescue StandardError
        @mr_no = @mr_no
        @appointment_integration_identifier = nil
        @status = 'Failed'
        @status_code = 500
        @message = 'No Response Received'
      end

      @response_received = ApiIntegration::DrAgarwal::Appointment::ResponseReceived.new(status: @status, status_code: @status_code, message: @message, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @mr_no)
      @response_received.save!

      appointment_data = {
        mr_no: @mr_no,
        doctor_employee_id: @doctor_employee_id,
        appointment_date: @appointment_datetime,
        employee_id: @employee_id,
        first_name: @appointment.patient.firstname,
        middle_name: @appointment.patient.middlename,
        last_name: @appointment.patient.lastname,
        mobile_number: @appointment.patient.mobilenumber,
        age: @appointment.patient.age,
        age_month: @appointment.patient.age_month,
        gender: @appointment.patient.gender,
        abbreviation: @appointment.facility.abbreviation,
        appointment_integration_identifier: @appointment_integration_identifier,
        appointment_integration_identifier_bson: @appointment.integration_identifier,
        sent_date: Date.current,
        sent_time: Time.current,
        request_type: 'Sent',
        method_type: @method_type,
        status: @status,
        status_code: @status_code,
        message: @message,
        number_of_retries: 0
      }

      @new_appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.new(appointment_data)
      @new_appointment_data.save!
    end

    resend_agarwal_failed_appointment_data if @status_code != 500
  end

  def update_agarwal_integration_appointment_data(appointment_id)
    sleep 5
    @appointment = Appointment.find_by(id: appointment_id)
    @appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment.integration_identifier.to_s, status_code: 200, method_type: 'Create')
    @doctor_employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
    @employee_id = User.find_by(id: @appointment.user_id).try(:employee_id)
    @mr_no = @appointment.try(:patient).try(:patient_mrn)
    @appointment_datetime = @appointment.try(:start_time).try(:strftime, '%d/%m/%Y %I:%M %p')
    @method_type = 'Update'

    # if @appointment.created_from != 'Integration'
    begin
      # Params to Send
      url = Global.ideamed[Rails.env]['url']
      user = Global.ideamed[Rails.env]['user']
      password = Global.ideamed[Rails.env]['password']
      payload = '{"mr_no": "' + @mr_no + '",
                  "doctor_employee_id": "' + @doctor_employee_id + '",
                  "appointment_date": "' + @appointment_datetime + '",
                  "created_by": "' + @employee_id + '",
                  "id": "' + @appointment_data.try(:appointment_integration_identifier).to_s + '" }'

      request = RestClient::Request.execute(method: :post, url: url,
                                            user: user,
                                            password: password,
                                            payload: payload,
                                            headers: { 'Content-Type' => 'application/json' })

      @response = JSON.parse(request)

      @mr_no = (@response['mr_no'] if @response['mr_no'].present?) || @mr_no
      @appointment_integration_identifier = @response['appointment_id']
      @status = @response['result']
      @status_code = 200
      @message = @response['message']
    rescue StandardError
      @mr_no = @mr_no
      @appointment_integration_identifier = nil
      @status = 'Failed'
      @status_code = 500
      @message = 'No Response Received'
    end

    @response_received = ApiIntegration::DrAgarwal::Appointment::ResponseReceived.new(status: @status, status_code: @status_code, message: @message, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @mr_no)
    @response_received.save!

    appointment_data = {
      mr_no: @mr_no,
      doctor_employee_id: @doctor_employee_id,
      appointment_date: @appointment_datetime,
      employee_id: @employee_id,
      first_name: @appointment.patient.firstname,
      middle_name: @appointment.patient.middlename,
      last_name: @appointment.patient.lastname,
      mobile_number: @appointment.patient.mobilenumber,
      age: @appointment.patient.age,
      age_month: @appointment.patient.age_month,
      gender: @appointment.patient.gender,
      abbreviation: @appointment.facility.abbreviation,
      appointment_integration_identifier: @appointment_integration_identifier,
      appointment_integration_identifier_bson: @appointment.integration_identifier,
      sent_date: Date.current,
      sent_time: Time.current,
      request_type: 'Sent',
      method_type: @method_type,
      status: @status,
      status_code: @status_code,
      message: @message,
      number_of_retries: 0
    }

    @new_appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.new(appointment_data)
    @new_appointment_data.save!
    # end
  end

  private

  def send_appointment_request(url, token, tokenlabel, payload)
    request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })

    response = JSON.parse(request)

    response
  end

  def resend_agarwal_failed_appointment_data
    sleep 5
    @failed_appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.where(status_code: 500, :appointment_integration_identifier_bson.nin => [nil]).order(created_at: :asc)
    @failed_appointment_data.each do |failed_appointment_data|
      next unless failed_appointment_data.try(:number_of_retries).to_i <= 20

      @appointment = Appointment.find_by(integration_identifier: failed_appointment_data.appointment_integration_identifier_bson)
      @doctor_employee_id = User.find_by(id: @appointment.consultant_id).try(:employee_id)
      @employee_id = User.find_by(id: @appointment.user_id).try(:employee_id)
      @mr_no = @appointment.try(:patient).try(:patient_mrn)
      @appointment_datetime = @appointment.try(:start_time).try(:strftime, '%d/%m/%Y %I:%M %p')
      @method_type = failed_appointment_data.method_type
      @number_of_retries = failed_appointment_data.number_of_retries.to_i + 1

      # if @appointment.created_from != 'Integration'
      begin
        # Params to Send
        url = Global.ideamed[Rails.env]['url']
        user = Global.ideamed[Rails.env]['user']
        password = Global.ideamed[Rails.env]['password']
        payload = '{"mr_no": "' + @mr_no + '",
                    "doctor_employee_id": "' + @doctor_employee_id + '",
                    "appointment_date": "' + @appointment_datetime + '",
                    "created_by": "' + @employee_id + '",
                    "id": "' + failed_appointment_data.try(:appointment_integration_identifier).to_s + '" }'

        request = RestClient::Request.execute(method: :post, url: url,
                                              user: user,
                                              password: password,
                                              payload: payload,
                                              headers: { 'Content-Type' => 'application/json' })

        @response = JSON.parse(request)

        @mr_no = (@response['mr_no'] if @response['mr_no'].present?) || @mr_no
        @appointment_integration_identifier = @response['appointment_id']
        @status = @response['result']
        @status_code = 200
        @message = @response['message']
      rescue StandardError
        @mr_no = @mr_no
        @appointment_integration_identifier = nil
        @status = 'Failed'
        @status_code = 500
        @message = 'No Response Received'
      end

      @response_received = ApiIntegration::DrAgarwal::Appointment::ResponseReceived.new(status: @status, status_code: @status_code, message: @message, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @mr_no)
      @response_received.save!

      appointment_data = {
        mr_no: @mr_no,
        doctor_employee_id: @doctor_employee_id,
        appointment_date: @appointment_datetime,
        employee_id: @employee_id,
        first_name: @appointment.patient.firstname,
        middle_name: @appointment.patient.middlename,
        last_name: @appointment.patient.lastname,
        mobile_number: @appointment.patient.mobilenumber,
        age: @appointment.patient.age,
        age_month: @appointment.patient.age_month,
        gender: @appointment.patient.gender,
        abbreviation: @appointment.facility.abbreviation,
        appointment_integration_identifier: @appointment_integration_identifier,
        appointment_integration_identifier_bson: @appointment.integration_identifier,
        sent_date: Date.current,
        sent_time: Time.current,
        request_type: 'Sent',
        method_type: @method_type,
        status: @status,
        status_code: @status_code,
        message: @message,
        number_of_retries: @number_of_retries
      }

      failed_appointment_data.update!(appointment_data)
      # end
    end
  end
end
