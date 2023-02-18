class Api::V1::LocationsController < ApiApplicationController
  before_action :authorize_token

  def search_state
    @final_states = country_constant.select { |country| country[:state].start_with?(term) }.pluck(:state).uniq
  end

  def search_city
    state = params[:state]

    if state&.length.to_i > 2 && country_constant.find { |country| country[:state] == state }
      states = country_constant.select { |country| country[:state].start_with?(state) }.uniq
      @final_cities = states.select { |country| country[:city].start_with?(term) }.pluck(:city, :state).uniq
    else
      @final_cities = country_constant.select { |country| country[:city].start_with?(term) }
                                      .pluck(:city, :state).uniq
    end
  end

  def search_district
    city = params[:city]

    if city&.length.to_i > 2 && country_constant.find { |country| country[:city] == city }
      cities = country_constant.select { |country| country[:city].start_with?(city) }.uniq
      @final_districts = cities.select { |country| country[:district].start_with?(term) }
                               .pluck(:district, :city).uniq
    else
      districts = country_constant.select { |country| country[:district].start_with?(term) }
      @final_districts = districts.pluck(:district, :city).uniq
    end
  end

  def search_commune
    city = params[:city]
    district = params[:district]

    if city.length > 2 && country_constant.find { |country| country[:city] == city }
      districts = country_constant.select { |country| country[:city].start_with?(city) }.pluck(:district).uniq
      cities = country_constant.select { |country| country[:city].start_with?(city) }.uniq
      if districts.include?(district)
        district_hash = cities.select { |country| country[:district].start_with?(district) }.uniq
        @final_communes = district_hash.select { |p| p[:commune].start_with?(term) }.uniq
      else
        @final_communes = cities.select { |country| country[:commune].start_with?(term) }.uniq
      end
    else
      @final_communes = country_constant.select { |country| country[:commune].start_with?(term) }.uniq
    end
  end

  def search_pincode
    state = params[:state]
    city = params[:city]

    if state.length > 2 && country_constant.find { |country| country[:state] == state }
      cities = country_constant.select { |country| country[:state].start_with?(state) }.pluck(:city).uniq
      states = country_constant.select { |country| country[:state].start_with?(state) }.uniq
      if cities.include?(city)
        city_hash = states.select { |country| country[:city].start_with?(city) }.uniq
        @final_pincodes = city_hash.select { |p| p[:pincode].start_with?(term) }.uniq
      else
        @final_pincodes = states.select { |country| country[:pincode].start_with?(term) }.uniq
      end
    else
      @final_pincodes = country_constant.select { |country| country[:pincode].start_with?(term) }.uniq
    end
  end

  def check_city
    city = params[:city]
    country_id = params[:country_id]
    @flag = true
    if country_id.eql?('IN') || country_id.eql?('IN_108') || (country_id.eql?('VN_254'))
      @flag = country_constant.select { |set| set[:city].eql?(city) }.count > 0
    end
    respond_to do |format|
      format.json { render json: { flag: @flag } }
    end
  end

  def check_state
    state = params[:state]
    country_id = params[:country_id]
    @flag = true
    if country_id.eql?('IN') || country_id.eql?('IN_108')
      @flag = country_constant.select { |set| set[:state].eql?(state) }.count > 0
    end
    respond_to do |format|
      format.json { render json: { flag: @flag } }
    end
  end

  def check_pincode
    pincode = params[:pincode]
    country_id = params[:country_id]
    @flag = true
    if country_id.eql?('IN') || country_id.eql?('IN_108')
      @flag = country_constant.select { |set| set[:pincode].eql?(pincode) }.count > 0
    end
    respond_to do |format|
      format.json { render json: { flag: @flag } }
    end
  end

  def check_commune
    commune = params[:commune]
    country_id = params[:country_id]
    @flag = true
    @flag = country_constant.select { |set| set[:commune].eql?(commune) }.count > 0 if country_id.eql?('VN_254')
    respond_to do |format|
      format.json { render json: { flag: @flag } }
    end
  end

  def check_district
    district = params[:district]
    country_id = params[:country_id]
    @flag = true
    @flag = country_constant.select { |set| set[:district].eql?(district) }.count > 0 if country_id.eql?('VN_254')
    respond_to do |format|
      format.json { render json: { flag: @flag } }
    end
  end

  private

  def term
    params[:q].to_s.titleize
  end

  def country_constant
    # if params[:country_id].present?
    #   # params[:country_id].upcase.constantize
    #   country_id = Facility.pluck(:country_id).uniq.reject{|c| c.class == BSON::ObjectId}.map(&:to_s).select{|c| c == params[:country_id]}.first
    #   country_id&.upcase&.constantize
    # elsif current_facility.present?
    #   current_facility.country_id.upcase.constantize
    # else
    #   'IN_108'.constantize
    # end
    if params[:country_id].present?
      params[:country_id].upcase.constantize
    elsif current_facility.present?
      current_facility.country_id.upcase.constantize
    else
      'IN_108'.constantize
    end
  end
end
