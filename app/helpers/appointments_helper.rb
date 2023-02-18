module AppointmentsHelper
  def past_visit(appointment)
    td = TimeDifference.between(appointment[:appointment_date], Date.today).in_general
    td = td.delete_if { |k, v| (v == 0 || ['hours', 'minutes', 'seconds'].include?(k.to_s)) }

    duration_array = []
    td.first(2).each { |component, value| duration_array << "#{value} #{component}".titleize }

    "#{duration_array.join(' ')} ago" # return
  end

  def hex_code(color_code)
    color = if !color_code.blank?
              (color_code.include? 'rgb') ? convert_to_hex(color_code) : color_code
            else
              '#000000'
            end
  end

  def convert_to_hex(color_code)
    @color_as_hex = ''
    arr = []
    split1 = color_code.split(',')
    if split1.size > 1
      split1_first_val = split1[0].split('(')[1]
      arr << split1_first_val.to_i
      arr << split1[1].strip.to_i
      arr << split1[2].strip.to_i
      arr.each do |component|
        hex = component.to_s(16)
        @color_as_hex << if component < 10
                           "0#{hex}"
                         else
                           hex
                         end
      end
      @with_hash = "##{@color_as_hex}"
    else
      @with_hash = '#000000'
    end
    @with_hash
  end

  def self.find_default_appointment_tab(current_user)
    {"HGP-102-104-104" => "appointment-overview", "HGP-102-104-105" => "bills", "HGP-102-104-106" => "diagnoses", "HGP-102-104-107" => "investigations", "HGP-102-104-108" => "procedures", "HGP-102-104-109" => "prescriptions", "HGP-102-104-110" => "glasses"}.each do |k,v|
      if Authorization::PolicyHelper.verification(current_user.id, k)
        return "#{v}-tab"
      end
    end
  end
  
end
