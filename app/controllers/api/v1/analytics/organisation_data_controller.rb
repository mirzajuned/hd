module Api::V1::Analytics
  class OrganisationDataController < ApiApplicationController
    before_action :authorize_token
    before_action :get_analytics_filters
    before_action :set_user_facility

    def index
      @organisation = current_user.try(:organisation)
      @organisation_name = @organisation.try(:name)
      @active_users = User.where(organisation_id: @organisation.try(:id), is_active: true).count
      @total_doctors = User.where(organisation_id: @organisation.try(:id), :role_ids.in => [158965000], is_active: true).count
      @total_centers = Facility.where(organisation_id: @organisation.try(:id), is_active: true).count
    end

    private

    def set_user_facility
      @current_facility = current_facility
      @current_user = current_user
    end

    def get_analytics_filters
      @facility_id = params[:filtered_facility].present? ? params[:filtered_facility] : current_facility
      @analytics_to_date = params[:analytics_to_date].present? ? params[:analytics_to_date] : Date.current
      @analytics_from_date = params[:analytics_from_date].present? ? params[:analytics_from_date] : Date.current
    end
  end
end
