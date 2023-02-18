module Api
  module V1
    class ApiKeyController < ApiApplicationController
      api :POST, "/api/v1/api_key/generate", "Generate api key for mobile and tablet"
      formats ['json']
      description <<-EOS
          == Generate api key for mobile and tablet
             URL: /api/v1/api_key/generate
             Parameters: {username:'abc',password:'xyz'}
             Type: POST
             Result: authorized =>{access_token:'access_token'}, unauthorized status will be 401
      EOS
      def generate
        @user = User.authenticate(params[:username], params[:password])
        if @user
          begin
            @api_key = ApiKey.new
            @api_key.user = @user
            @api_key.access_token = generate_key
            @api_key.expiry_time = DateTime.current + 90 # New code, expiry time for 90 days from current time.
            # @api_key.expiry_time = 24.hours.from_now  # Commented by mohit, now we are passing expiry time for 90 days.
          end while !@api_key.save
          @appointment_types = AppointmentType.where(:user_id => @api_key.user.id, :is_active => true)
          respond_to do |format|
            format.json {}
          end
        else
          head 403
        end
      end

      api :POST, "/api/v1/api_key/logout", "Signout the user session from mobile and tablet"
      formats ['json']
      description <<-EOS
          == Generate api key for mobile and tablet
             URL: /api/v1/api_key/logout
             Parameters: {access_token:'access_token'}
             Type: POST
             Result: {'status'=> 'true or false'}
      EOS
      def logout
        @api_key = ApiKey.find_by(:access_token => params[:access_token])
        if @api_key.destroy
          @status_flag = true
        else
          @status_flag = false
        end
      end

      api :GET, "/api/v1/api_key/initial_download", "Api to download patients, appointments and other details."
      formats ['json']
      description <<-EOS
          == Generate api key for mobile and tablet
             URL: /api/v1/api_key/initial_download
             Parameters: {user_id:'11111111', role:'doctor or receptionist etc', department_id:'2222222'}
             Type: GET
             Result: patients, appointments, appointmenttypes for each doctor
      EOS
      def initial_download
        # Read request params
        @today_date = Date.current.strftime("%Y-%m-%d")
        @user = User.find_by(:id => params[:user_id])
        @organisation = @user.organisation
        @facilities = @user.facilities
        @department_id = params[:department_id]

        # Get Patients
        @patients = Patient.where(:reg_hosp_ids => [@organisation.id.to_s])

        # Get Appointments
        @appointment_list = []
        @facilities.each do |facility|
          options = { :appointmentdate.gte => @today_date, :facility_id => facility.id, :department_id => @department_id, :appointmentstatus.in => [416774000, 58334001] }
          appointments = Appointment.where(options).order_by(appointmentdate: :asc, start_time: :asc)
          (@appointment_list << appointments).flatten!
        end
        @appointments_count = @appointment_list.count > 0 ? @appointment_list.count : 0

        # Get Appointment Types
        # Done in json file. Check json response.

        respond_to do |format|
          format.json {}
        end
      end

      api :GET, "/api/v1/api_key/reg_mobile_device", "API to register mobile and tablet devices"
      formats ['json']
      description <<-EOS
          == Generate api key for mobile and tablet
             URL: /api/v1/api_key/initial_download
             Parameters: {user_id:'11111111', device_id:'111111'}
             Type: GET
             Result: patients, appointments, appointmenttypes for each doctor
      EOS
      def reg_mobile_device
        @user = User.find_by(:id => params[:user_id])
        @organisation = @user.organisation
        @device_id = params[:device_id]
        reg_status = GoogleCloudMessaging.register_device({ :user_id => @user.id, :organisation_id => @organisation.id, :device_id => @device_id })
        respond_to do |format|
          format.json {}
        end
      end

      private

      def generate_key
        SecureRandom.hex
      end
    end
  end
end
