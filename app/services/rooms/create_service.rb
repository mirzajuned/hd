module Rooms
  class CreateService
    def self.call(params, ward)
      params.to_unsafe_h.each do |i, rooms_attributes|
        room = ward.rooms.new(rooms_attributes)
        if room.save!
          Beds::CreateService.call(params[i]["beds_attributes"], room)
        end
      end
    end
  end
end
