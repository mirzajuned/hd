class Analytics::AnalyticsDataController < ApplicationController
  before_action :authorize
  before_action :set_user_facility
  before_action :set_analytics_filters
  before_action :date_query_creator
  before_action :set_params_hash
  before_action :set_service_details
  before_action :load_configuration
  layout 'loggedin'

  def show_modal
    loader = @analytics_config['default'][@partial_name]
    query_type_check = loader['exact_query']
    query_array = JSON.parse(query_type_check)
    query_array.each do |query|
      instance_eval(query)
    end
  end

  private

  def set_user_facility
    @current_facility = current_facility
    @current_user = current_user
  end

  def load_configuration
    @analytics_config = YAML.load_file('app/views/analytics/shared/analytics_config.yml')
  end

  def set_analytics_filters
    data_query = params['data_query']
    @facility_id = data_query[:filtered_facility].present? ? data_query[:filtered_facility] : current_facility.id
    @specialty_id = data_query[:filtered_specialty].present? ? data_query[:filtered_specialty] : 'all'
    @analytics_to_date = data_query[:analytics_to_date].present? ? data_query[:analytics_to_date] : Date.current
    @analytics_from_date = data_query[:analytics_from_date].present? ? data_query[:analytics_from_date] : (Date.current - 7)
    @facility = Facility.find_by(id: @facility_id) || current_facility
    @current_user = current_user
    @user_id = data_query['user_id']
    @data_type = params[:data_type].present? ? params[:data_type] : 'day'
  end

  def set_params_hash
    @params_hash = {
      'organisation_id' => @current_facility.organisation_id,
      'facility_id' => @facility_id,
      'specialty_id' => @specialty_id,
      'analytics_to_date' => @analytics_to_date,
      'analytics_from_date' => @analytics_from_date,
      'currency_id' => @currency_id || @facility.try(:currency_id) || current_facility.currency_id,
      'user_id' => @user_id,
      'data_type' => @data_type,
      'data_query' => @data_query,
      'label_on' => @label_on
    }
    # check if date is start and end dates are same

    @todays_data = true if @analytics_from_date == @analytics_to_date
  end

  def set_service_details
    service_query = params['service_query']
    @service_name = service_query['service_name']
    @action_name  = service_query['action_name']
    @partial_name = service_query['partial_name']
    @on_zoom      = service_query['on_zoom']
    @currency_id  = service_query['currency_id']
  end

  def date_query_creator
    from_date = @analytics_from_date
    to_date   = @analytics_to_date

    @data_query, @label_on = Analytics::AnalyticsDate::QueryGenerator.query_array_builder(to_date, from_date)
  end
end
