json.array!(@appointment_types) do |appointment_type|
  json.id appointment_type.id
  json.label appointment_type.label
  json.duration appointment_type.duration
  json.background appointment_type.background
  json.is_default appointment_type.is_default
end
