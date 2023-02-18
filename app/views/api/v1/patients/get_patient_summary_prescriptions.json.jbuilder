json.set! "patientprescriptions" do
  json.array!(1..5) do |prescription|
    json.set! "#{(Date.current - 2 - prescription).strftime('%d/%m/%Y')}" do
      json.array!(1..3) do |medication|
        json.medicinename "Pepraz #{medication}"
        json.medicinequantity "10 mg paracetamol"
        json.medicinefrequency "#{medication} times a day"
        json.medicineduration "#{medication} week"
        json.medicineinstructions "Take after meals"
        json.doctor "Dr Miten Sheth #{medication}"
      end
    end
  end
end
