json.set! "dashboard" do
  json.set! "opd" do
    json.array!(0..4) do |opd|
      json.date "#{(Date.current + opd).strftime('%d/%m/%Y')}"
      json.istoday "Y"
      json.appointmentcount "30"
      json.sequencenumber "#{opd + 1}"
      json.set! "upcomingappointments" do
        json.array!(1..3) do |patient|
          json.patientinfo "Mohit Maniar - 23/M"
          json.appointmenttime "12:00 PM"
          json.appointmenttype "Fr"
        end
      end
    end
  end
  json.set! "ot" do
    json.array!(0..4) do |ot|
      json.date "#{(Date.current + ot).strftime('%d/%m/%Y')}"
      json.istoday "Y"
      json.otcount "2"
      json.sequencenumber "#{ot + 1}"
    end
  end
  json.set! "admission" do
    json.array!(0..4) do |admission|
      json.date "#{(Date.current + admission).strftime('%d/%m/%Y')}"
      json.istoday "Y"
      json.admissioncount "2"
      json.sequencenumber "#{admission + 1}"
    end
  end
  json.set! "discharge" do
    json.array!(0..4) do |discharge|
      json.date "#{(Date.current + discharge).strftime('%d/%m/%Y')}"
      json.istoday "Y"
      json.dischargecount "2"
      json.sequencenumber "#{discharge + 1}"
    end
  end
end
