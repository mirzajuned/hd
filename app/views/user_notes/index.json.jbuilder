json.array!(@medical_certificates) do |medical_certificate|
  json.extract! medical_certificate, :id
  json.url medical_certificate_url(medical_certificate, format: :json)
end
