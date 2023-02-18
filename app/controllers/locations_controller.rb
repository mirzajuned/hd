# 4  Metrics/AbcSize
# 1  Metrics/ClassLength
# 1  Metrics/CyclomaticComplexity
# --
# 6  Total
class LocationsController < ApplicationController
  # skip_before_action :authorize
  # skip_before_action :require_login, :only => [:landing, :connect, :create]
  before_action :data_params, only: [:check_city, :check_state, :check_pincode, :check_commune, :check_district]

  def search_state
    # @final_states = country_constant.select { |country| country[:state].start_with?(term) }.pluck(:state).uniq

    states_result = Location.search r_query, fields: [:state], match: :word_middle, operator: 'or',
                                             limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                             where: { country_id: country_id.to_s.downcase }
    @final_states = states_result.pluck(:state).uniq
  end

  def search_city
    state = params[:state].try(:downcase)

    # if state&.length.to_i > 2 && country_constant.find { |country| country[:state] == state }
    #   states = country_constant.select { |country| country[:state].start_with?(state) }.uniq
    #   @final_cities = states.select { |country| country[:city].start_with?(term) }.pluck(:city, :state).uniq
    # else
    #   @final_cities = country_constant.select { |country| country[:city].start_with?(term) }.pluck(:city, :state).uniq
    # end

    states_result = Location.search state, fields: [:state], match: :word_middle, operator: 'or',
                                           limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                           where: { country_id: country_id.to_s.downcase }

    if state&.length.to_i > 2 && !states_result.empty?

      cities_result = Location.search r_query, fields: [:city], match: :word_middle, operator: 'or',
                                               limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                               where: { country_id: country_id.to_s.downcase, state: state }
    else
      cities_result = Location.search r_query, fields: [:city], match: :word_middle, operator: 'or',
                                               limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                               where: { country_id: country_id.to_s.downcase }
    end
    @final_cities = cities_result.pluck(:city, :state).uniq
  end

  def search_district
    city = params[:city].try(:downcase)

    # if city&.length.to_i > 2 && country_constant.find { |country| country[:city] == city }
    #   cities = country_constant.select { |country| country[:city].start_with?(city) }.uniq
    #   @final_districts = cities.select { |country| country[:district].start_with?(term) }.pluck(:district, :city).uniq
    # else
    #   districts = country_constant.select { |country| country[:district].start_with?(term) }
    #   @final_districts = districts.pluck(:district, :city).uniq
    # end

    cities_result = Location.search city, fields: [:city], match: :word_middle, operator: 'or',
                                          limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                          where: { country_id: country_id.to_s.downcase }

    if city&.length.to_i > 2 && !cities_result.empty?

      districts_result = Location.search r_query, fields: [:district], match: :word_middle, operator: 'or',
                                                  limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                  where: { country_id: country_id.to_s.downcase, city: city }
    else
      districts_result = Location.search r_query, fields: [:district], match: :word_middle, operator: 'or',
                                                  limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                  where: { country_id: country_id.to_s.downcase }
    end
    if params[:country_id] == "KH_039"
      @final_districts = districts_result.pluck(:country_id, :district).uniq
    else
      @final_districts = districts_result.pluck(:country_id, :district, :city).uniq
    end
  end

  def search_commune
    city = params[:city].try(:downcase)
    district = params[:district].try(:downcase)
    state = params[:state].try(:downcase)
    # if city.length > 2 && country_constant.find { |country| country[:city] == city }
    #   districts = country_constant.select { |country| country[:city].start_with?(city) }.pluck(:district).uniq
    #   cities = country_constant.select { |country| country[:city].start_with?(city) }.uniq
    #   if districts.include?(district)
    #     district_hash = cities.select { |country| country[:district].start_with?(district) }.uniq
    #     @final_communes = district_hash.select { |p| p[:commune].start_with?(term) }.uniq
    #   else
    #     @final_communes = cities.select { |country| country[:commune].start_with?(term) }.uniq
    #   end
    # else
    #   @final_communes = country_constant.select { |country| country[:commune].start_with?(term) }.uniq
    # end

    cities_result = Location.search city, fields: [:city], match: :word_middle, operator: 'or',
                                          limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                          where: { country_id: country_id.to_s.downcase }
    states_result = Location.search state, fields: [:state], match: :word_middle, operator: 'or',
                                          limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                          where: { country_id: country_id.to_s.downcase }
    if params[:country_id] == "KH_039"
      if state&.length.to_i > 2 && !states_result.empty?
        districts_result = Location.search district, fields: [:district], match: :word_middle, operator: 'or',
                                                    limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                    where: { country_id: country_id.to_s.downcase, state: state }
        if !districts_result.empty?
          communes_result = Location.search r_query, fields: [:commune], match: :word_middle, operator: 'or',
                                                    limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                    where: { country_id: country_id.to_s.downcase, state: state, district: district }
        else
          communes_result = Location.search r_query, fields: [:commune], match: :word_middle, operator: 'or',
                                                    limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                    where: { country_id: country_id.to_s.downcase, state: state }
        end
      else
        communes_result = Location.search r_query, fields: [:commune], match: :word_middle, operator: 'or',
                                                  limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                  where: { country_id: country_id.to_s.downcase }
      end
      @final_communes = communes_result.pluck(:country_id, :district, :commune, :state).uniq
    else
      if city&.length.to_i > 2 && !cities_result.empty?
        districts_result = Location.search district, fields: [:district], match: :word_middle, operator: 'or',
                                                    limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                    where: { country_id: country_id.to_s.downcase, city: city }
        if !districts_result.empty?
          communes_result = Location.search r_query, fields: [:commune], match: :word_middle, operator: 'or',
                                                    limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                    where: { country_id: country_id.to_s.downcase, city: city, district: district }
        else
          communes_result = Location.search r_query, fields: [:commune], match: :word_middle, operator: 'or',
                                                    limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                    where: { country_id: country_id.to_s.downcase, city: city }
        end
      else
        communes_result = Location.search r_query, fields: [:commune], match: :word_middle, operator: 'or',
                                                  limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                  where: { country_id: country_id.to_s.downcase }
      end
      @final_communes = communes_result.pluck(:country_id, :district, :commune, :city).uniq
    end
  end

  def search_pincode
    state = params[:state].try(:downcase)
    city = params[:city].try(:downcase)

    # if state.length > 2 && country_constant.find { |country| country[:state] == state }
    #   cities = country_constant.select { |country| country[:state].start_with?(state) }.pluck(:city).uniq
    #   states = country_constant.select { |country| country[:state].start_with?(state) }.uniq
    #   if cities.include?(city)
    #     city_hash = states.select { |country| country[:city].start_with?(city) }.uniq
    #     @final_pincodes = city_hash.select { |p| p[:pincode].start_with?(term) }.uniq
    #   else
    #     @final_pincodes = states.select { |country| country[:pincode].start_with?(term) }.uniq
    #   end
    # else
    #   @final_pincodes = country_constant.select { |country| country[:pincode].start_with?(term) }.uniq
    # end

    states_result = Location.search state, fields: [:state], match: :word_middle, operator: 'or',
                                           limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                           where: { country_id: country_id.to_s.downcase }

    if state&.length.to_i > 2 && !states_result.empty?
      cities_result = Location.search city, fields: [:city], match: :word_middle, operator: 'or',
                                            limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                            where: { country_id: country_id.to_s.downcase, state: state }
      if !cities_result.empty?
        pincodes_result = Location.search r_query, fields: [:pincode], operator: 'or',
                                                   limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                   where: { country_id: country_id.to_s.downcase, city: city, state: state }
      else
        pincodes_result = Location.search r_query, fields: [:pincode], operator: 'or',
                                                   limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                   where: { country_id: country_id.to_s.downcase, state: state }
      end
    else
      pincodes_result = Location.search r_query, fields: [:pincode], operator: 'or',
                                                 limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                                 where: { country_id: country_id.to_s.downcase }
    end
    if params[:country_id] == "KH_039"
      @final_pincodes = pincodes_result.pluck(:country_id, :state, :pincode, :district, :commune).uniq
    else
      if country_id.to_s == 'IN_108'
        @final_pincodes = pincodes_result.pluck(:country_id, :state, :pincode, :city, :area_managers, :_id, 
          :gst_state_code, :alpha_code, :is_union_territory, :is_utgst_applicable).uniq
      else
        @final_pincodes = pincodes_result.pluck(:country_id, :state, :pincode, :city).uniq
      end
    end
  end

  def check_city
    # city = @data[:city].try(:downcase)
    city = @data[:city].nil? ? @data[:billing_city].try(:downcase) : @data[:city].try(:downcase)
    country_id = params[:country_id]
    @flag = true
    if country_id.eql?('IN') || country_id.eql?('IN_108') || (country_id.eql?('VN_254') && @data == params[:patient])
      cities_result = Location.search city, fields: [:city], match: :word_middle, operator: 'or',
                                            limit: 25, misspellings: { below: 5 }, order: { _score: :desc },
                                            where: { country_id: country_id.to_s.downcase }
      @flag = !cities_result.empty?
      # @flag = country_constant.select { |set| set[:city].eql?(city) }.count > 0
    end
    respond_to do |format|
      format.json { render json: @flag }
    end
  end

  def check_state
    # state = @data[:state].try(:downcase)
    state = @data[:state].nil? ? @data[:billing_state].try(:downcase) :  @data[:state].try(:downcase)
    country_id = params[:country_id]
    @flag = true
    if country_id.eql?('IN') || country_id.eql?('IN_108') || country_id.eql?('KH') || country_id.eql?('KH_039')
      states_result = Location.search state, fields: [:state], match: :word_middle, operator: 'or',
                                             limit: 25, misspellings: false, order: { _score: :desc },
                                             where: { country_id: country_id.to_s.downcase }
      @flag = !states_result.empty?
      # @flag = country_constant.select { |set| set[:state].eql?(state) }.count > 0
    end
    respond_to do |format|
      format.json { render json: @flag }
    end
  end

  def check_pincode
    # pincode = @data[:pincode]
    pincode = @data[:pincode].nil? ? @data[:billing_pincode] : @data[:pincode]
    country_id = params[:country_id]
    @flag = true
    if country_id.eql?('IN') || country_id.eql?('IN_108') || country_id.eql?('KH') || country_id.eql?('KH_039')
      pincodes_result = Location.search pincode, fields: [:pincode], operator: 'or',
                                                 limit: 25, misspellings: false, order: { _score: :desc },
                                                 where: { country_id: country_id.to_s.downcase }
      @flag = !pincodes_result.empty?
      # @flag = country_constant.select { |set| set[:pincode].eql?(pincode) }.count > 0
    end
    respond_to do |format|
      format.json { render json: @flag }
    end
  end

  def check_commune
    # commune = @data[:commune].try(:downcase)
    commune = @data[:commune].nil? ? @data[:billing_commune].try(:downcase) : @data[:commune].try(:downcase)
    country_id = params[:country_id]
    @flag = true
    communes_result = Location.search commune, fields: [:commune], match: :word_middle, operator: 'or',
                                               limit: 25, misspellings: false, order: { _score: :desc },
                                               where: { country_id: country_id.to_s.downcase }
    @flag = !communes_result.empty?
    # @flag = country_constant.select { |set| set[:commune].eql?(commune) }.count > 0 if country_id.eql?('VN_254')
    respond_to do |format|
      format.json { render json: @flag }
    end
  end

  def check_district
    # district = @data[:district].try(:downcase)
    district =  @data[:district].nil? ? @data[:billing_district].try(:downcase) : @data[:district].try(:downcase)
    country_id = params[:country_id]
    @flag = true
    districts_result = Location.search district, fields: [:district], match: :word_middle, operator: 'or',
                                                 limit: 25, misspellings: false, order: { _score: :desc },
                                                 where: { country_id: country_id.to_s.downcase }
    @flag = !districts_result.empty?
    # @flag = country_constant.select { |set| set[:district].eql?(district) }.count > 0 if country_id.eql?('VN_254')
    respond_to do |format|
      format.json { render json: @flag }
    end
  end

  private

  def r_query
    params[:q].to_s.downcase
  end

  def term
    params[:q].to_s.titleize
  end

  def country_id
    if params[:country_id].present?
      params[:country_id].upcase
    elsif current_facility.present?
      current_facility.country_id.upcase
    else
      'IN_108'
    end
  end

  def country_constant
    if params[:country_id].present?
      # params[:country_id].upcase.constantize
      country_id = Facility.pluck(:country_id).uniq.reject{|c| c.class == BSON::ObjectId}.map(&:to_s).select{|c| c == params[:country_id]}.first
      country_id&.upcase&.constantize
    elsif current_facility.present?
      current_facility.country_id.upcase.constantize
    else
      'IN_108'.constantize
    end
  end

  def data_params
    @data = params[:patient] || params[:facility] || params[:facility_contact] || params[:contact] || params[:user] || params[:organisation] || params[:inventory_store] || params[:entity_group] || params[:camp] || params[:inpatient_ipd_record][:patient_attributes]
  end
end
