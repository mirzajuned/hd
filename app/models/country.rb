class Country
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :abbreviation1, type: String
  field :abbreviation2, type: String
  field :currencies, type: String
  field :languages, type: String
  field :minimum_phone_no_length, type: Integer
  field :maximum_phone_no_length, type: Integer
  field :is_active, type: Boolean, default: false
  field :address_label_format, type: Array
  field :time_zones, type: Array

  has_and_belongs_to_many :languages

  def get_time_zones
    time_zones = self.time_zones
    @zones_array = []

    unless time_zones.nil?
      time_zones.each do |zone|
        view_time = zone.split("/")
        view_time.shift
        view_time = view_time.join("-")

        time_abbreviation = TZInfo::Timezone.get(zone).now.in_time_zone(zone).strftime('%:z %Z')
        @zones_array << [time_abbreviation.to_s + " " + view_time.to_s, zone]
      end
    end

    return @zones_array
  end
end
