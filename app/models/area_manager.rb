class AreaManager
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :area_name, type: String
  # field :latitude, type: String
  # field :longitude, type: String
  
  embeds_one :area_location, class_name: '::AreaManager::AreaLocation'
  embedded_in :location, class_name: '::Location'

  accepts_nested_attributes_for :area_location, allow_destroy: true

  def lat_long
    area_location.coordinates
  end
end
