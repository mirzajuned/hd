module Api
  module V1
    class DepartmentsController < ApiApplicationController
      before_action :authorize_token
      api :GET, '/api/v1/departments/list', 'Get departments list'
      formats ['json']
      description <<-EOS
          == Get departments list for mobile and tablet
             URL: /api/v1/departments/list
             Type: GET
             Result: {departments:{0:{id:'id',name:'full name'}},{1:{id:'id',name:'full name'}}}
      EOS
      def list
        @departments = Department.all
        respond_to do |format|
          format.json {}
        end
      end
    end
  end
end
