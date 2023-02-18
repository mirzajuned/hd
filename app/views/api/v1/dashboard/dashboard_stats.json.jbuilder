json.set! "dashboard" do
  json.set! "opd" do
    json.scheduled (@scheduled_patient_doctor.to_i > 0) ? "#{@scheduled_patient_doctor}" : "0"
    json.arrived (@patient_arrived_doctor.to_i > 0) ? "#{@patient_arrived_doctor}" : "0"
    json.seen (@patient_seen_doctor.to_i > 0) ? "#{@patient_seen_doctor}" : "0"
    json.cancelled (@cancelled_patient_doctor.to_i > 0) ? "#{@cancelled_patient_doctor}" : "0"
  end
  json.set! "ipd" do
    json.admissions (@admission_today_doctor.to_i > 0) ? "#{@admission_today_doctor}" : "0"
    json.ot (@patients_ot_doctor.to_i > 0) ? "#{@patients_ot_doctor}" : "0"
    json.totaladmissions (@admitted_patient_doctor.to_i > 0) ? "#{@admitted_patient_doctor}" : "0"
    json.discharged (@discharged_today_doctor.to_i > 0) ? "#{@discharged_today_doctor}" : "0"
  end
end
