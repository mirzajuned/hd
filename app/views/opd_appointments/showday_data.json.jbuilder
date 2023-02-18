# json.sEcho @sEcho
# json.iTotalRecords @total_appointment_count
# json.iTotalDisplayRecords @appointment_list_count
# json.set! "aaData" do
#   json.array!(@appointment_list) do |appointment|
#     badge_color = ""
#     if appointment.seen
#       appointment_status = 'Completed'
#       badge_color = 'success'
#     elsif appointment.engaged == true
#       appointment_status = 'Engaged'
#       badge_color = 'info'
#     elsif appointment.seen == false and appointment.arrived == true
#       appointment_status = 'Waiting'
#       badge_color = 'danger'
#     else
#       appointment_status = 'Scheduled'
#       badge_color = 'default'
#     end

#     slash = ''
#     if !appointment.patient.gender.nil? && !appointment.patient.age.nil?
#       slash='/'
#     elsif !appointment.patient.gender.nil? && appointment.patient.age.nil? || appointment.patient.gender.nil? && !appointment.patient.age.nil?
#       slash=''
#     end

#     json.set! "0",'<input class="appointment-list-checkbox" id="appointment-list-checkbox" name="appointment-list-checkbox" type="checkbox" value="'+appointment.id.to_s+'">'
#     json.set! "1",'<span class="badge" style="background-color:'+appointment.appointment_type.background+';">'+appointment.appointment_type.label+'</span>'
#     json.set! "2",'<span class="badge badge-'+badge_color+'">'+appointment_status+'</span>'
#     json.set! "3",'<a id="patient_identifier" href="#" style="font-size:12px;" rel="popover" p_id="'+appointment.patient.id.to_s+'">'+appointment.patient.patient_identifiers.where(:organisation_id => current_user.organisation_id).first.try(:patient_org_id)+'</a>'
#     json.set! "4",'<a class="patientsummary ps" style="font-size:12px;" id="patientsummary ps" data-remote="true" href="/patients/summary?appointment_id='+appointment.id.to_s+'&amp;patientid='+appointment.patient.id.to_s+'&amp;opd=440655000">'+appointment.patient.fullname+'</a>'
#     json.set! "5",'<span style="font-size:12px;">'+"#{appointment.patient.gender}#{slash}#{appointment.patient.age}"+'</span>'
#     json.set! "6",'<span style="font-size:12px;">'+"#{Time.strptime("#{appointment.start_time}", "%Y-%m-%d %H:%M:%S").strftime("%I:%M %p")}"+'</span>'
#     json.set! "7",render('opd_appointments/eachappointmenttimedata.html',appointment: appointment )
#     json.set! "8",render('opd_appointments/eachappointmentdaycontrols.html',appointment: appointment )
#   end
# end

json.array!(@appointment_list) do |appointment|
  json.extract! appointment, :id, :appointmentdate, :appointmentstatus, :arrived, :arrived_time, :current_state, :department_id, :departmenttype, :display_id, :doctor, :end_time, :engaged, :engage_time, :engaged_time_min, :facility_id, :patient_id, :ref_doc_name, :seen, :start_time, :total_time_min, :user_id, :waiting_time_min, :dilation_start_time, :dilation_end_time

  json.borderColor appointment.appointment_type.background
  json.appointment_booked_type appointment.appointment_type.label
  json.backgroundColor appointment.appointment_type.background
  json.title appointment.patient.fullname
  if appointment.dilation_start_time != nil
    json.difference TimeDifference.between(appointment.dilation_start_time, Time.current).in_seconds.to_i
  end
  if appointment.dilation_start_time != nil && appointment.dilation_end_time != nil
    json.end_difference Time.at(TimeDifference.between(appointment.dilation_start_time, appointment.dilation_end_time).in_seconds.to_i).utc.strftime("%M:%S")
  end
end

# CHANGES CAME WITH FACILITYSESSCION BRANCH
# =======
#     json.set! "0",'<input class="appointment-list-checkbox" id="appointment-list-checkbox" name="appointment-list-checkbox" type="checkbox" value="'+appointment.id.to_s+'">'
#     json.set! "1",'<span class="badge" style="background-color:'+appointment.appointment_type.background+';">'+appointment.appointment_type.label+'</span>'
#     json.set! "2",'<span class="badge badge-'+badge_color+'">'+appointment_status+'</span>'
#     json.set! "3",'<a id="patient_identifier" href="#" style="font-size:12px;" rel="popover" p_id="'+appointment.patient.id.to_s+'">'+appointment.patient.patient_identifiers.where(:organisation_id => current_user.organisation_id).first.try(:patient_org_id)+'</a>'
#     json.set! "4",'<a class="patientsummary ps" style="font-size:12px;" id="patientsummary ps" data-remote="true" href="/patients/summary?appointment_id='+appointment.id.to_s+'&amp;patientid='+appointment.patient.id.to_s+'&amp;opd=440655000">'+appointment.patient.fullname+'</a>'
#     json.set! "5",'<span style="font-size:12px;">'+"#{appointment.patient.gender}#{slash}#{appointment.patient.age}"+'</span>'
#     if appointment.dilation_start_time != nil && appointment.dilation_end_time == nil
#     json.set! "6", render('opd_appointments/dilation_check.html', appointment: appointment)
#   else
#     json.set! "6",'<span style="font-size:12px;">'+" #{Time.strptime("#{appointment.start_time}", "%Y-%m-%d %H:%M:%S").strftime("%I:%M %p")}" +'</span>'
#     end
#     json.set! "7",render('opd_appointments/eachappointmenttimedata.html',appointment: appointment )
#     json.set! "8",render('opd_appointments/eachappointmentdaycontrols.html',appointment: appointment )
#   end
# end
# >>>>>>> FacilitySession
