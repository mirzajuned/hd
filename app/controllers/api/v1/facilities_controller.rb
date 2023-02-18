module Api
  module V1
    class FacilitiesController < ApiApplicationController
      before_action :authorize_token
      api :GET, '/api/v1/facilities/list', 'Get facilities list of current hospital'
      formats ['json']
      description <<-EOS
          == Generate api key for mobile and tablet
             URL: /api/v1/facilities/list
             Type: GET
             Result: {facilities:{0:{id:'id',name:'full name'}},{1:{id:'id',name:'full name'}}}
      EOS
      def list
        @facilities = current_user.organisation.facilities.where(:is_active => true)
        respond_to do |format|
          format.json {}
        end
      end
    end
  end
end
