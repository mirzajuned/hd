json.sEcho @sEcho
json.iTotalRecords @total_admission_count
json.iTotalDisplayRecords @admission_list_count
count = 0
json.set! "aaData" do
  json.array!(@ot_list) do |ot|
    count += 1
    json.set! "0", count
    json.set! "1", '<span style="font-size:12px;">' + ot.admission.display_id + '</span>'
    json.set! "2", '<span style="font-size:12px;">' + ot.patient.patient_identifiers.where(:organisation_id => current_user.organisation_id).first.try(:patient_org_id) + '</span>'
    json.set! "3", ot.patient.fullname
    json.set! "4", ot.patient.gender
    json.set! "5", ot.patient.age
    json.set! "6", '<span style="font-size:12px;">' + "#{ot.otdate.strftime("%a, %d-%b-%Y")} #{ot.ottime.strftime("%I:%M %p")}" + '</span>'
    tpa = Inpatient::Insurance::Tpa.find_by(admission_id: ot.admission.id)
    json.set! "7", render('ipd_patients/partials/eachotlistcontrols.html', ot: ot, tpa: tpa)
  end
end
