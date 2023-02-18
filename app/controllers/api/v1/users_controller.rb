module Api
  module V1
    class UsersController < ApiApplicationController
      before_action :authorize_token
      api :GET, "/api/v1/users/current_user_details", "Get Current User details"
      formats ['json']
      description <<-EOS
          == Get Current User details for mobile and tablet
             URL: /api/v1/users/current_user_details
             Type: GET
             Result: {id:'id',fullname:'full name',email:'xyz@abc.com',alternate_email:'xyz@abc.com',gender:'male or female',dob:'yyyy-mm-dd',telephone:'9999999999','alternate_telephone':'9999999999',department_id:'dept id',licence_number:'xyz',facility_ids:[a,b],roles:[a,b]}
      EOS
      def current_user_details
        @user = current_user
        respond_to do |format|
          format.json {}
        end
      end

      api :GET, "/api/v1/users/list", "Get list of doctors for whom you can give appointment"
      formats ['json']
      description <<-EOS
          == Get list of doctors for whom you can give appointment for mobile and tablet
             URL: /api/v1/users/list
             Type: GET
             Result: {users:{0:{id:'id',fullname:'full name',department_id:'dept id',facility_ids:[a,b]}},{1:{id:'id',fullname:'full name',department_id:'dept id',facility_ids:[a,b]}}}
      EOS
      def list
        @users = current_user.organisation.users.where(:is_active => true).with_all_roles(:doctor)
        respond_to do |format|
          format.json {}
        end
      end
    end
  end
end
