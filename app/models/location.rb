class Location
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  searchkick word_middle: [:state, :city, :district, :commune]

  def search_data
    {
      state: state.try(:downcase).to_s,
      city: city.try(:downcase).to_s,
      pincode: pincode.try(:downcase).to_s,
      country_id: country_id.try(:downcase).to_s,
      district: district.try(:downcase).to_s,
      commune: commune.try(:downcase).to_s
    }
  end

  field :country_id, type: String
  field :state, type: String
  field :city,  type: String
  field :pincode, type: String
  field :gst_state_code, type: String
  field :alpha_code, type: String
  field :is_union_territory, type: Boolean
  field :is_utgst_applicable, type: Boolean

  field :district, type: String
  field :commune, type: String
  field :is_migrated, type: Boolean, default: false

  embeds_many :area_managers, class_name: "::AreaManager"
  accepts_nested_attributes_for :area_managers, allow_destroy: true

  def selected_area_name(area_id)
    area_managers.find_by(id: area_id)
  end

  # field :taluk, type: String
  # field :circlename, type: String
  # field :regionname, type: String
end
