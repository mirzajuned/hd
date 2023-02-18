json.array!(@startdate..@enddate) do |appointmentdate|
  json.set! "#{appointmentdate.strftime('%d/%m/%Y')}" do
    json.array!(1..rand(5)) do |appointmentcount|
      json.patient_id Faker::Number.number(10)
      json.patientname Faker::Name.name
      json.patientmobilenumber Faker::PhoneNumber.cell_phone
      json.patientpicthumb Faker::Avatar.image("my-own-slug", "50x50")
      json.patientpicactual Faker::Avatar.image("my-own-slug", "200x200")
      json.patientage rand(100)
      json.patientgender "M"
      json.appointmentid Faker::Number.number(10)
      json.start_time "#{(Time.current + rand(1200) + 600).strftime('%I:%M %p')}"
      json.appointmenttype @appointmenttypearray[appointmentcount]
    end
  end
end
