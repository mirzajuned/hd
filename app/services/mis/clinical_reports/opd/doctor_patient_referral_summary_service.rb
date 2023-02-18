module Mis::ClinicalReports::Opd
  class DoctorPatientReferralSummaryService
    class << self
      def format_data_before_save(record_id)
        primary_model_name = 'OpdRecord'
        opd_record = OpdRecord.find_by(id: record_id)
        extract_referral_data(opd_record, record_id, primary_model_name)
      end

      def process_and_save(options_array)
        options_array.each do |option|
          if option[:referral_type_id] == 272441002
            referral_id_find_or_create_by(option, 272441002)
          elsif option[:referral_type_id] == 272440001
            referral_id_find_or_create_by(option, 272440001)
          elsif option[:referral_type_id] == 261074009
            referral_id_find_or_create_by(option, 261074009)
          end
        end
      end

      private

      def referral_id_find_or_create_by(option, referral_type_id)
        m_doc_pat_referral_summary_report = MisClinical::Opd::DoctorPatientReferralSummaryReport.find_or_create_by(
          facility_id: option[:facility_id], from_specialty_id: option[:from_specialty_id], 
          referral_id: option[:referral_id], referral_type_id: referral_type_id
        )
        m_doc_pat_referral_summary_report.update_attributes(option)
      end

      def get_patient_data(patient_id)
        patient = Patient.find_by(id: patient_id)
        patient_name = patient.fullname
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        age = patient.age.present? && patient.age > 0 ? patient.age : patient.exact_age
        exact_age = patient.try(:exact_age)
        {
          patient_id: patient_id, patient_name: patient_name, age: age, gender: patient.gender,
          patient_identifier_id: patient.patient_identifier_id, patient_mrn: patient.patient_mrn, 
          mobilenumber: patient.mobilenumber, commune: patient.commune, district: patient.district,
          state: patient.state, pincode: patient.pincode, city: patient.city, exact_age: exact_age,
          location_id: location_id, area_manager_id: area_manager_id, 
          area_manager_name: area_manager_name
        }
      end

      def extract_referral_data(record, record_id, _primary_model_name)
        options_array = []
        patient_display_fields = {}
        patient_display_fields = get_patient_data(record[:patientid]) if record.present? && record[:patientid].present?
        from_specialty_id = (record[:specalityid]).to_s # record[:specalityid] without underscore "-" in name.
        from_specialty_name = (record[:specalityname]).to_s # record[:specalityname] without underscore "-" in name.
        appointment_id = (record[:appointmentid]).to_s # record[:appointmentid] without underscore "-" in name.
        organisation_id = (record[:organisation_id]).to_s
        global_data_attr = {
          from_specialty_id: from_specialty_id, from_specialty_name: from_specialty_name,
          appointment_id: appointment_id.to_s, organisation_id: organisation_id.to_s, primary_model_id: record_id,
          primary_model_name: 'OpdRecord'
        }
        # Diagnoses method
        diagnoses = get_diagnosis_data_from_record(record)

        # Intra Facility method
        options_array = get_intra_facility_attributes(
          record, global_data_attr, patient_display_fields, diagnoses, options_array
        )
        # Inter Facility method
        options_array = get_inter_facility_attributes(
          record, global_data_attr, patient_display_fields, diagnoses, options_array
        )
        # Outside Organisation method
        options_array = get_outside_organisation_attributes(
          record, global_data_attr, patient_display_fields, diagnoses, options_array
        )
        options_array
      end

      def get_doctor_name(user_id)
        User.find_by(id: user_id).try(:fullname)
      end

      def get_facility_name(facility_id)
        Facility.find_by(id: facility_id).try(:name)
      end

      def get_diagnosis_data_from_record(record)
        extracted_diagnoses = []
        record.diagnosislist.each do |diagnosis|
          extracted_diagnoses << {
            diagnosis_name: diagnosis[:diagnosisname].titleize,
            original_name: diagnosis[:diagnosisoriginalname].titleize,
            diagnosis_code: diagnosis[:icddiagnosiscode],
            icddiagnosis_fullcode: diagnosis[:icddiagnosisfullcode]
          }
        end
        extracted_diagnoses
      end

      def get_intra_facility_attributes(record, global_data_attr, patient_display_fields, diagnoses, options_array)
        record_created_at = record.created_at
        record.intra_facility_referral.each do |referral|
          from_specialty_name = TemplatesHelper.get_speciality_name((referral[:specialty_id]).to_s)
          to_specialty_name = from_specialty_name # intra facility specialty will be same.
          from_facility_name = get_facility_name((referral[:facility_id]).to_s)
          to_facility_name = from_facility_name # intra facility from_facility_name will be same.
          facility_name = from_facility_name # intra facility from_facility_name will be same.
          from_doctor_name = get_doctor_name((referral[:from_user]).to_s)
          to_doctor_name = get_doctor_name((referral[:to_user]).to_s)
          referral_date = referral.try(:referraldate).to_date
          referral_time = ''
          if referral.try(:referraltime).present?
            referral_time = referral.try(:referraltime).strftime('%A %b %d, %Y at %H:%M %p')
          end
          referral_details = "To: #{to_doctor_name}, \n Location: #{to_facility_name}, \n Date: #{referral_time}"
          final_data_attr = {}
          referral_data_attr = {
            referral_id: referral[:id], referral_type_id: Global.ehrcommon.intra_facility.id,
            referral_type_name: Global.ehrcommon.intra_facility.displayname.to_s,
            from_specialty_id: referral[:specialty_id], from_specialty_name: from_specialty_name,
            to_specialty_id: referral[:specialty_id], to_specialty_name: to_specialty_name,
            referral_date: referral_date, referral_date_time: referral.try(:referraltime),
            referral_details: referral_details, referral_notes: referral[:referralnote],
            from_doctor_id: referral[:from_user], from_doctor_name: from_doctor_name,
            to_doctor_id: referral[:to_user], to_doctor_name: to_doctor_name,
            from_facility_id: referral[:facility_id], from_facility_name: from_facility_name,
            to_facility_id: referral[:facility_id], to_facility_name: to_facility_name,
            facility_id: referral[:facility_id], facility_name: facility_name,
            referred_on_date: record_created_at.to_date, referred_on_date_time: record_created_at
          }
          final_data_attr = global_data_attr.merge(final_data_attr)
          final_data_attr['patient_display_fields'] = patient_display_fields
          final_data_attr['diagnoses'] = diagnoses
          final_data_attr = referral_data_attr.merge(final_data_attr)
          options_array.push(final_data_attr)
        end
        options_array
      end

      def get_inter_facility_attributes(record, global_data_attr, patient_display_fields, diagnoses, options_array)
        record_created_at = record.created_at
        record.inter_facility_referral.each do |referral|
          from_specialty_name = TemplatesHelper.get_speciality_name((referral[:from_facility_specialty]).to_s)
          to_specialty_name = TemplatesHelper.get_speciality_name((referral[:to_facility_specialty]).to_s)
          from_facility_name = get_facility_name((referral[:from_facility]).to_s)
          to_facility_name = get_facility_name((referral[:to_facility]).to_s)
          facility_name = from_facility_name # inter facility from_facility_name will be same.
          from_doctor_name = get_doctor_name((referral[:from_user]).to_s)
          to_doctor_name = get_doctor_name((referral[:to_user]).to_s)
          referral_date = referral.try(:referraldate).to_date
          referral_time = ''
          if referral.try(:referraltime).present?
            referral_time = referral.try(:referraltime).strftime('%A %b %d, %Y at %H:%M %p')
          end
          referral_details = "To: #{to_doctor_name}, \n Location: #{to_facility_name}, \n Date: #{referral_time}"
          final_data_attr = {}
          referral_data_attr = {
            referral_id: referral[:id], referral_type_id: Global.ehrcommon.inter_facility.id,
            referral_type_name: Global.ehrcommon.inter_facility.displayname.to_s,
            from_specialty_id: referral[:from_facility_specialty], from_specialty_name: from_specialty_name,
            to_specialty_id: referral[:to_facility_specialty], to_specialty_name: to_specialty_name,
            referral_date: referral_date, referral_date_time: referral.try(:referraltime),
            referral_details: referral_details, referral_notes: referral[:referralnote],
            from_doctor_id: referral[:from_user], from_doctor_name: from_doctor_name, to_doctor_id: referral[:to_user],
            to_doctor_name: to_doctor_name, from_facility_id: referral[:from_facility],
            from_facility_name: from_facility_name, to_facility_id: referral[:to_facility],
            to_facility_name: to_facility_name, facility_id: referral[:from_facility], facility_name: facility_name,
            referred_on_date: record_created_at.to_date, referred_on_date_time: record_created_at
          }
          final_data_attr = global_data_attr.merge(final_data_attr)
          final_data_attr['patient_display_fields'] = patient_display_fields
          final_data_attr['diagnoses'] = diagnoses
          final_data_attr = referral_data_attr.merge(final_data_attr)
          options_array.push(final_data_attr)
        end
        options_array
      end

      def get_outside_organisation_attributes(record, global_data_attr, patient_display_fields, diagnoses, options_array)
        record_created_at = record.created_at
        record.outside_organisation_referral.each do |referral|
          from_specialty_name = record[:specalityname]
          from_facility_name = get_facility_name(record[:facility_id])
          to_facility_name = referral[:referred_facility_name]
          facility_name = from_facility_name # outside org facility from_facility_name will be same.
          from_doctor_name = get_doctor_name(record[:userid])
          to_doctor_name = referral[:referred_doctor_name]
          referral_date = (referral.try(:referraldate).present?) ? referral.try(:referraldate).to_date : record_created_at.to_date
          # referral_date_time = referral.try(:referraltime)
          referral_date_time = (referral.try(:referraldate).present?) ? referral.try(:referraldate) : record_created_at
          if referral_date_time.present?
            # referral_time = referral.try(:referraltime).strftime('%A %b %d, %Y at %H:%M %p')
            referral_time = referral_date_time.strftime('%A %b %d, %Y')
          else
            referral_time = referral_date.strftime('%A %b %d, %Y at %H:%M %p')
            referral_date_time = record_created_at
          end
          referral_details = "To: #{to_doctor_name}, \n Location: #{to_facility_name}, \n Date: #{referral_time}"
          final_data_attr = {}
          referral_data_attr = {
            referral_id: referral[:id], referral_type_id: Global.ehrcommon.outside_referral.id,
            referral_type_name: Global.ehrcommon.outside_referral.displayname,
            from_specialty_id: (record[:specalityid]).to_s, from_specialty_name: from_specialty_name,
            to_specialty_id: '', to_specialty_name: '', referral_date: referral_date,
            referral_date_time: referral_date_time, referral_details: referral_details,
            referral_notes: (referral[:referralnote]), from_doctor_id: record[:userid], to_doctor_id: '',
            from_doctor_name: from_doctor_name, to_doctor_name: to_doctor_name,
            from_facility_id: record[:facility_id], from_facility_name: from_facility_name,
            to_facility_name: to_facility_name, facility_id: record[:facility_id],
            facility_name: facility_name, to_facility_id: '',
            referred_on_date: record_created_at.to_date, referred_on_date_time: record_created_at
          }
          final_data_attr = global_data_attr.merge(final_data_attr)
          final_data_attr['patient_display_fields'] = patient_display_fields
          final_data_attr['diagnoses'] = diagnoses
          final_data_attr = referral_data_attr.merge(final_data_attr)
          options_array.push(final_data_attr)
        end
        options_array
      end
    end
  end
end
