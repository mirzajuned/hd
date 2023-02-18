class AreaManager::AreaLocation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :type, type: String, default: 'Point'
  field :coordinates, type: Array

  embedded_in :area_manager, class_name: '::AreaManager'
end
