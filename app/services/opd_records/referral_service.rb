module OpdRecords
  module ReferralService
    def self.call(opdrecord)
      if opdrecord.has_intra_facility_referral?
        intra_facility_referral_data = opdrecord.intra_facility_referral
        intra_facility_referral_data.each_with_index do |referral, i|
          if referral[:bookreferredappointment] == true
            @referralappointment = Appointment.find_by(:intra_referral_id => referral.id)

            if @referralappointment.present?
              @past_appointment_type_id = @referralappointment.appointment_type_id
              @past_appointment_category_type_id = @referralappointment.appointment_category_id
              @past_appointment_facility = @referralappointment.facility_id
              @past_appointment_specialty = @referralappointment.specialty_id
              @past_appointment_date = @referralappointment.appointmentdate

              @referralappointment.update(:referral_created_on => Time.current, :appointmentdate => referral[:referraldate], :start_time => referral[:referraltime], :end_time => referral[:referraltime] + 10.minutes, :facility_id => referral[:facility_id], :appointment_type_id => referral[:referral_appointment_type_id], :consultant_id => referral[:to_user], :appointmentstatus => 416774000, appointment_category_id: referral[:referral_appointment_category_id], specialty_id: referral[:specialty_id], department_id: '485396012')

              # call appointment_type service update for analytics
              Analytics::Appointment::UpdateService.update_appointment_type_count(@referralappointment.id, @past_appointment_type_id, @past_appointment_facility, @past_appointment_specialty, @past_appointment_date)

              # call appointment_category_type service update for analytics
              Analytics::Appointment::UpdateService.update_appointment_category_type_count(@referralappointment.id, @past_appointment_category_type_id, @past_appointment_facility, @past_appointment_specialty, @past_appointment_date)

              Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "RESCHEDULED", appointment_id: @referralappointment.id.to_s, user_id: opdrecord.record_histories[0].user_id.to_s, user_name: User.find_by(id: opdrecord.record_histories[0].user_id).try(:fullname), workflow: Facility.find_by(id: @referralappointment.facility_id).clinical_workflow })
            else
              ref = intra_facility_referral_data.find_by(id: referral.id)
              referring_doctor = User.find_by(id: ref.from_user).fullname
              referee_doctor = User.find_by(id: ref.to_user).fullname
              referral_note = ref.referralnote
              @user = User.find(referral[:to_user])

              new_appointment = Appointment.new.tap do |appointment|
                appointment.referral_created_on = Time.current
                appointment.appointmentdate = referral[:referraldate]
                appointment.start_time = referral[:referraltime]
                appointment.patient_id = opdrecord.patientid
                appointment.appointment_type_id = referral[:referral_appointment_type_id]
                appointment.consultant_id = referral[:to_user]
                appointment.user_id = opdrecord.userid
                appointment.facility_id = referral[:facility_id]
                appointment.department_id = '485396012'
                appointment.departmenttype = opdrecord.encountertypeid
                appointment.appointmentstatus = 416774000
                appointment.display_id = CommonHelper::get_opd_record_identifier(@user)
                appointment.intra_referral_id = referral.id
                appointment.referral = true
                appointment.referral_type = "intra_facility"
                appointment.referral_opd_record = opdrecord.id
                appointment.end_time = referral[:referraltime] + 10.minutes
                appointment.referring_doctor = referring_doctor
                appointment.referee_doctor = referee_doctor
                appointment.referral_note = referral_note
                appointment.case_sheet_id = opdrecord.try(:case_sheet_id)
                appointment.organisation_id = opdrecord.organisation_id
                appointment.appointment_category_id = referral[:referral_appointment_category_id]
                appointment.specialty_id = referral[:specialty_id]
                appointment.save!
              end

              if new_appointment
                @referralappointment_id = new_appointment.id
                @temp_appointment = new_appointment
                Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: new_appointment.id.to_s, user_id: opdrecord.record_histories[0].user_id.to_s, user_name: User.find_by(id: opdrecord.record_histories[0].user_id).try(:fullname), workflow: Facility.find_by(id: referral[:facility_id]).clinical_workflow })
              else
                @referralappointment_id = ""
              end
            end
          else
            @referralappointment = Appointment.find_by(:intra_referral_id => referral.id)
            if @referralappointment.present?
              @referralappointment.update(appointmentstatus: 89925002)
              Analytics::Appointment::UpdateService.decrement_appointment_type_count(@referralappointment.id.to_s)
              Analytics::Appointment::UpdateService.decrement_appointment_category_type_count(@referralappointment.id.to_s)
            end
          end
        end
      end

      if opdrecord.has_inter_facility_referral?
        opdrecord.inter_facility_referral.each_with_index do |referral, i|
          patient = Patient.find_by(id: opdrecord.patientid)

          referral_date_time = referral.referraldate

          referred_to_facility_id = referral[:to_facility]
          referred_to_facility_name = Facility.find_by(id: referral[:to_facility]).name

          referred_from_facility_id = referral[:from_facility]
          referred_from_facility_name = Facility.find_by(id: referral[:from_facility]).name

          referred_to_doctor = referral[:to_user]
          referred_to_doctor_name = User.find_by(id: referral[:to_user]).try(:fullname)

          referred_from_doctor = referral[:from_user]
          referred_from_doctor_name = User.find_by(id: referral[:from_user]).try(:fullname)

          saved_opd_referral = OpdReferral.find_by(inter_facility_referral_id: referral.id)

          if saved_opd_referral.present?
            saved_opd_referral.update(referral_date: referral_date_time, created_on: referral_date_time, to_facility: referred_to_facility_id, to_facility_name: referred_to_facility_name, from_facility: referred_from_facility_id, from_facility_name: referred_from_facility_name, to_doctor: referred_to_doctor, to_doctor_name: referred_to_doctor_name, from_doctor: referred_from_doctor, from_doctor_name: referred_from_doctor_name, referring_note: referral[:referralnote], is_deleted: false)
          else

            new_opd_referral = OpdReferral.new.tap do |opd_referral|
              opd_referral.organisation_id = opdrecord.organisation_id
              opd_referral.referral_date = referral_date_time
              opd_referral.created_on = Time.current
              opd_referral.patient_id = patient.id
              opd_referral.patient_name = patient.fullname
              opd_referral.from_facility = referred_from_facility_id
              opd_referral.from_facility_name = referred_from_facility_name
              opd_referral.from_facility_specialty = referral[:from_facility_specialty]
              opd_referral.from_doctor = referred_from_doctor
              opd_referral.from_doctor_name = referred_from_doctor_name
              opd_referral.to_facility = referred_to_facility_id
              opd_referral.to_facility_name = referred_to_facility_name
              opd_referral.to_facility_specialty = referral[:to_facility_specialty]
              opd_referral.to_doctor = referred_to_doctor
              opd_referral.to_doctor_name = referred_to_doctor_name
              opd_referral.referring_note = referral[:referralnote]
              opd_referral.inter_facility_referral_id = referral.id
              opd_referral.save!
            end
          end
        end
      end
    end
  end
end
