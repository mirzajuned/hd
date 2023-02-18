json.array!(@prescriptions) do |prescription|
  json.l_glassesprescriptions_distant_axis prescription.l_glassesprescriptions_distant_axis
  json.l_glassesprescriptions_distant_cyl prescription.l_glassesprescriptions_distant_cyl
  json.l_glassesprescriptions_distant_sph prescription.l_glassesprescriptions_distant_sph
  json.l_glassesprescriptions_distant_vision prescription.l_glassesprescriptions_distant_vision
  json.l_glassesprescriptions_near_axis prescription.l_glassesprescriptions_near_axis
  json.l_glassesprescriptions_near_cyl prescription.l_glassesprescriptions_near_cyl
  json.l_glassesprescriptions_near_sph prescription.l_glassesprescriptions_near_sph
  json.l_glassesprescriptions_near_vision prescription.l_glassesprescriptions_near_vision
  json.r_glassesprescriptions_distant_axis prescription.r_glassesprescriptions_distant_axis
  json.r_glassesprescriptions_distant_cyl prescription.r_glassesprescriptions_distant_cyl
  json.r_glassesprescriptions_distant_sph prescription.r_glassesprescriptions_distant_sph
  json.r_glassesprescriptions_distant_vision prescription.r_glassesprescriptions_distant_vision
  json.r_glassesprescriptions_near_axis prescription.r_glassesprescriptions_near_axis
  json.r_glassesprescriptions_near_cyl prescription.r_glassesprescriptions_near_cyl
  json.r_glassesprescriptions_near_sph prescription.r_glassesprescriptions_near_sph
  json.r_glassesprescriptions_near_vision prescription.r_glassesprescriptions_near_vision

  json.l_acceptance_framematerial prescription.l_acceptance_framematerial
  json.l_acceptance_ipd prescription.l_acceptance_ipd
  json.l_acceptance_lensmaterial prescription.l_acceptance_lensmaterial
  json.l_acceptance_lenstint prescription.l_acceptance_lenstint
  json.l_acceptance_typeoflens prescription.l_acceptance_typeoflens
  json.r_acceptance_framematerial prescription.r_acceptance_framematerial
  json.r_acceptance_ipd prescription.r_acceptance_ipd
  json.r_acceptance_lensmaterial prescription.r_acceptance_lensmaterial
  json.r_acceptance_lenstint prescription.r_acceptance_lenstint
  json.r_acceptance_typeoflens prescription.r_acceptance_typeoflens

  json.department "50121007"
  json.id prescription._id
  if prescription.patient

    json.patientname prescription.patient.fullname || 'NA'
    json.patient_id PatientIdentifier.find_by(patient_id: prescription.patient_id).try(:patient_org_id) || 'NA'
    json.mobilenumber prescription.patient.mobilenumber || 'NA'
    mr_no = PatientOtherIdentifier.find_by(patient_id: prescription.patient_id).try(:mr_no)
    if mr_no.present?
      json.mr_no PatientOtherIdentifier.find_by(patient_id: prescription.patient_id).mr_no
    end
  end
  json.doctor_name prescription.doctor_name
  json.created_at prescription.encounterdate.strftime("%d %b %Y")
  json.created_at_time prescription.encounterdate.strftime("%I:%M %p")
  json.dispatched_from_optical prescription.dispatched_from_optical
  json.display_id prescription.display_id
  if prescription.advance_amount
    json.advance_amount prescription.advance_amount.compact.sum
  end
  if prescription.advance_reason
    json.advance_reason prescription.advance_reason
  end
end
