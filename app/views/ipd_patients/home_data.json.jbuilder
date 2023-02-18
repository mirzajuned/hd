json.sEcho @sEcho
json.iTotalRecords @total_admission_count
json.iTotalDisplayRecords @admission_list_count
count = 0
json.set! "aaData" do
  json.array!(@admission_list) do |admission|
    count += 1
    json.set! "0", count
    json.set! "1", '<span style="font-size:12px;">' + admission.display_id + '</span>'
    json.set! "2", '<a id="patient_identifier" style="font-size:12px;" href="#" rel="popover" p_id="' + admission.patient.id.to_s + '">' + admission.patient.patient_identifiers.where(:organisation_id => current_user.organisation_id).first.try(:patient_org_id) + '</a>'
    json.set! "3", '<a class="patientsummary ps" style="font-size:12px;" id="patientsummary ps" data-remote="true" href="/patients/summary?admission_id=' + admission.id.to_s + '&amp;patientid=' + admission.patient.id.to_s + '&amp;opd=440654001">' + admission.patient.fullname + '</a>'
    admissiongender = ""
    if admission.patient.try(:gender)
      admissiongender = admission.patient.gender
    end
    admissionage = ""
    if admission.patient.try(:age)
      admissionage = admission.patient.age.to_s
    end
    slash = ''
    if !admission.patient.gender.nil? && !admission.patient.age.nil?
      slash = '/'
    elsif !admission.patient.gender.nil? && admission.patient.age.nil? || admission.patient.gender.nil? && !admission.patient.age.nil?
      slash = ''
    end
    json.set! "4", '<span style="font-size:12px;">' + "#{admissiongender}#{slash}#{admissionage}" + '</span>'

    admissionreason = ""
    if admission.try(:admissionreason)
      admissionreason = admission.admissionreason
    end
    json.set! "5", '<span style="font-size:12px;">' + admissionreason + '</span>'
    if Date.current.strftime("%d-%b-%y") == admission.admissiondate.strftime("%d-%b-%y")
      json.set! "6", '<span style="font-size:12px;">Today, ' + admission.admissiontime.strftime("%I:%M %p") + '</span>'
    else
      json.set! "6", '<span style="font-size:12px;">' + "#{admission.admissiondate.strftime("%d-%b")},#{admission.admissiontime.strftime("%I:%M %p")}" + '</span>'
    end
    tpa = Inpatient::Insurance::Tpa.find_by(admission_id: admission.id)
    json.set! "7", render('inpatient/insurance/eachinsureddetails.html', tpa: tpa)
    json.set! "8", render('ipd_patients/eachadmissioncontrols.html', admission: admission, tpa: tpa)
  end
end
