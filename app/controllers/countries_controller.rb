class CountriesController < ApplicationController
  def populate_country_timezones
    country = Country.find_by(id: params[:country_id])
    if country.present?
      @zones_array = country.get_time_zones

      currency_id = country.currencies.split(",")[0].to_s + "001"
      currency = Currency.find_by(id: currency_id)

      if current_user.present?
        r_masters = RegionMaster.where(
                    organisation_id: current_organisation['_id'],
                    country_id: country.id
                  )
      else
        r_masters = []
      end
      if r_masters.count > 0
        region_masters = r_masters.uniq.map{|rm| ["#{rm.name} - #{rm.abbreviation}", rm.id]}
        render json: { "zone_array": @zones_array, "currency": currency, "regions": region_masters }
      else
        render json: { "zone_array": @zones_array, "currency": currency }
      end
    else
      render json: { "message": "country not found" }, status: :ok
    end
  end

  def get_time_zone_time
    if params[:time_zone].present?
      @time = TZInfo::Timezone.get(params[:time_zone]).now.in_time_zone.strftime("%I:%M %p, %d %b %Y")
      render json: { "date_time": @time }
    else
      render json: { "message": "zone not found" }, status: :ok
    end
  end
end
