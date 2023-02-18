json.action "view"
json.opdrecord @opdrecord
json.patient_self_history @patient_self_history
json.optometrist_record @optometrist_record
json.facility_id @facility_id

json.patient_history @patient.patient_history
json.set! "record_histories" do
  json.array!(@opdrecord.record_histories) do |list|
    json.action list.action
    json.actiontime list.actiontime
    json.created_at list.created_at
    json.template_type list.template_type
    json.updated_at list.updated_at
    json.user_fullname User.find_by(id: list.user_id.to_s).try(:fullname)
  end
end
