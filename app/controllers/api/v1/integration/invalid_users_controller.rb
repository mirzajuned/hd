module Api
  module V1
    module Integration
      class InvalidUsersController < ApiApplicationController
        def failure_response
          @message = { status: 'Failed', message: 'Invalid Username/Password' }
        end
      end
    end
  end
end
