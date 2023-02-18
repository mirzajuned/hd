json.set! "patientsummary" do
  json.set! "patient" do
    json.fullname "Mohit Maniar"
    json.age "21"
    json.dob "29/12/1981"
    json.sex "Male"
    json.address "Sector 4 HSR Layout Bangalore 560037"
    json.profilethumbnailpic "http://placehold.it/150x150"
    json.profileactualpic "http://placehold.it/300x300"
  end

  json.set! "diangosis" do
    json.array!(1..5) do |diagnosis|
      json.diagnosisname "Medial Minuscus Tear #{diagnosis}"
      json.side "R"
      json.manifestation "Bucket Handle #{diagnosis}"
      json.diagnoiseddate "#{(Date.current - diagnosis).strftime('%d/%m/%Y')}"
      json.doctor "Dr Miten Sheth #{diagnosis}"
    end
  end

  json.set! "medications" do
    json.array!(1..10) do |medication|
      json.medicationname "Pepraz #{medication}"
      json.contents "10 mg paracetamol"
      json.duration "11"
      json.frequency "1-0-1"
      json.instruction "Take after meals"
      json.doctor "Dr Miten Sheth #{medication}"
      json.adviseddate "#{(Date.current - 2 - medication).strftime('%d/%m/%Y')}"
    end
  end

  json.set! "investigations" do
    json.array!(1..5) do |investigation|
      json.investigationname "XR, Knee AP & Lateral #{investigation}"
      json.investigationtype "X-Ray"
      json.doctor "Dr Miten Sheth #{investigation}"
      json.adviseddate "#{(Date.current - 2 - investigation).strftime('%d/%m/%Y')}"
    end
  end

  json.set! "admissions" do
  end

  json.set! "scans" do
    json.array!(1..15) do |scan|
      json.scanname "XR, Knee AP & Lateral #{scan}"
      json.thumbnail "http://placehold.it/150x150"
      json.actual "http://placehold.it/500x500"
    end
  end

  json.set! "reports" do
  end
end
