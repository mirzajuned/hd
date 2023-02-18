module Mis::NewClinicalReports::Ipd
  class StructureAdmissionDetails
    class << self
      def call(list)
        alv = AdmissionListView.find(list[:_id])
        # note - writting to fetch embedded data as embedded ones as data is being strutured in hash here
        admission_id = list[:admission_id]
        patient_id = list[:patient_id]
        patient = Patient.find_by(id: patient_id)
        patient_name = list[:patient_name]
        patient_display_id = list[:patient_display_id]
        patient_mr_no = list[:patient_mr_no]
        patient_age = list[:patient_age]
        age = list[:patient_age].present? ? (list[:age] || list[:patient_age].to_i) : nil
        patient_gender = list[:patient_gender]
        patient_mobilenumber = list[:patient_mobilenumber]
        commune = list[:commune]
        district = list[:district]
        state = list[:state]
        pincode = list[:pincode]
        city = list[:city]
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        patient_type = list[:patient_type]
        patient_details = { patient_name: patient_name, patient_display_id: patient_display_id,
                            patient_mr_no: patient_mr_no, patient_age: patient_age, age: age,
                            patient_gender: patient_gender, patient_type: patient_type,
                            patient_mobilenumber: patient_mobilenumber, commune: commune, 
                            district: district, state: state, pincode: pincode, city: city,
                            location_id: location_id, area_manager_id: area_manager_id,
                            area_manager_name: area_manager_name }
        admitting_doctor = list[:admitting_doctor]
        admitting_doctor_id = list[:admitting_doctor_id]
        admission_display_id = list[:admission_display_id]
        admission_date = list[:admission_date]
        admission_time = list[:admission_time]
        discharge_date = list[:discharge_date]
        discharge_time = list[:discharge_time]
        admission_type = list[:admission_type]
        reason_for_admission = list[:reason_for_admission]
        operative_date = list[:operative_date]
        operative_time = list[:operative_time]
        surgery_advised_date = list[:surgery_advised_date]
        surgery_advised_time = list[:surgery_advised_time]

        daycare = list[:daycare]
        ward_name = list[:ward_name]
        ward_code = list[:ward_code]
        room_name = list[:room_name]
        room_code = list[:room_code]
        bed_name = list[:bed_name]
        bed_code = list[:bed_code]

        current_state = list[:current_state]

        admission_stage = list[:admission_stage]

        user_id = list[:user_id]
        department_id = list[:department_id]
        start_time = list[:start_time]
        end_time = list[:end_time]
        message = list[:message]
        admission = Admission.find_by(id: list[:admission_id])

        scheduled_date = admission.scheduled_date
        scheduled_time = admission.scheduled_time
        mode_of_hospitalization = admission.is_insured == 'No' ? 'Cash' : 'Insured'
        insurance_details = {}
        insurance_name = admission.insurance_name
        insurance_status = admission.insurance_status rescue nil
        insurance_state = admission.insurance_state rescue nil
        insurance_policy_no = admission.insurance_policy_no
        insurance_policy_expiry_date = admission.insurance_policy_expiry_date
        insurance_comments = admission.insurance_comments
        tpa_contact_id = admission.tpa_contact_id
        insurance_contact_id = admission.insurance_contact_id
        patient_insurance_id = admission.patient_insurance_id
        document_insurancecard = admission.document_insurancecard
        insurance_address = admission.insurance_address rescue nil
        insurance_contact_person = admission.insurance_contact_person rescue nil
        insurance_type = admission.insurance_type rescue nil
        sum_insured = admission.sum_insured rescue nil

        if admission.is_insured == 'Yes'
          insurance_details = { insurance_name: insurance_name, insurance_status: insurance_status,
                                insurance_policy_no: insurance_policy_no, insurance_state: insurance_state,
                                insurance_policy_expiry_date: insurance_policy_expiry_date,
                                insurance_comments: insurance_comments,
                                tpa_contact_id: tpa_contact_id,
                                insurance_contact_id: insurance_contact_id,
                                patient_insurance_id: patient_insurance_id,
                                document_insurancecard: document_insurancecard,
                                insurance_address: insurance_address,
                                insurance_contact_person: insurance_contact_person,
                                insurance_type: insurance_type,
                                sum_insured: sum_insured }
        end
        specialty_id = list[:specialty_id]
        specialty_name = list[:specialty_name]

        facility_id = list[:facility_id]
        organisation_id = list[:organisation_id]
        # <li><%= link_to consolidate_reports_index_path(patient_id: @patient.id, specialty_id: specialty.id), :data => {:remote => true, 'toggle' =>  "modal", 'target' => '#templates-modal'} do %> <i class="fa fa-file-text"></i>&nbsp;&nbsp;<%= specialty.name.capitalize %> <% end %></li>
        # <%= link_to inpatient_ipd_records_show_all_notes_path(admission_id: @admission.id, patient_id: @admission.patient.id), id: "show-all-notes-btn", class: "btn btn-primary btn-primary-transparent btn-xs", data: { remote: true, toggle:  "modal", target: '#templates-modal' } do %>All Notes <% end %>
        casesheet = CaseSheet.where(:admission_ids.in => [list[:admission_id].to_s])[0]

        admission_details = MisClinical::Ipd::ClinicalReportIpd.find_or_create_by(
          organisation_id: list[:organisation_id], facility_id: list[:facility_id],
          admission_id: list[:admission_id]
        )
        inpatient_record = Inpatient::IpdRecord.find_by(admission_id: admission_id)
        complications = inpatient_record&.complications&.pluck(:complication_name)
        comments = inpatient_record&.procedure&.pluck(:procedurename, :complication_comment)
        complication_comment = inpatient_record&.operative_notes&.pluck(:complication_comment)&.join(',')
        intra_op_comlications = { complications: complications, comments: comments, complication_comment: complication_comment }
        # embedding
        # note - need to update embedding if already there else create new embedded data
        admission_details.admission_state_transitions = alv&.admission_state_transitions
        admission_details.admission_milestones = alv&.admission_milestones
        admission_details.chief_complaints = casesheet&.chief_complaints
        admission_details.diagnoses  = casesheet&.diagnoses
        admission_details.procedures = casesheet&.procedures
        admission_details.complications = casesheet&.complications
        admission_details.ophthal_investigations = casesheet&.ophthal_investigations
        admission_details.laboratory_investigations = casesheet&.laboratory_investigations
        admission_details.laboratory_investigations = casesheet&.laboratory_investigations
        admission_details.radiology_investigations = casesheet&.radiology_investigations

        admission_details.operative_notes = inpatient_record&.operative_notes
        admission_details.complications = inpatient_record&.complications
        admission_details.intra_op_comlications = intra_op_comlications

        admission_details.admission_id = admission_id
        admission_details.patient_id = patient_id
        admission_details.patient_details = patient_details
        admission_details.admitting_doctor = admitting_doctor
        admission_details.admitting_doctor_id = admitting_doctor_id
        admission_details.admission_display_id = admission_display_id
        admission_details.admission_date = admission_date
        admission_details.admission_time = admission_time
        admission_details.discharge_date = discharge_date
        admission_details.discharge_time = discharge_time
        admission_details.admission_type = admission_type
        admission_details.scheduled_date = scheduled_date
        admission_details.scheduled_time = scheduled_time
        admission_details.reason_for_admission = reason_for_admission
        admission_details.operative_date = operative_date
        admission_details.operative_time = operative_time
        admission_details.surgery_advised_date = surgery_advised_date
        admission_details.surgery_advised_time = surgery_advised_time
        admission_details.daycare = daycare
        admission_details.ward_name = ward_name
        admission_details.ward_code = ward_code
        admission_details.room_name = room_name
        admission_details.room_code = room_code
        admission_details.bed_name = bed_name
        admission_details.bed_code = bed_code
        admission_details.current_state = current_state
        admission_details.admission_stage = admission_stage
        admission_details.user_id = user_id
        admission_details.department_id = department_id
        admission_details.start_time = start_time
        admission_details.end_time = end_time
        admission_details.message = message
        admission_details.mode_of_hospitalization = mode_of_hospitalization
        admission_details.insurance_details = insurance_details
        admission_details.specialty_id = specialty_id
        admission_details.specialty_name = specialty_name
        admission_details.facility_id = facility_id
        admission_details.organisation_id = organisation_id
        admission_details.is_migrated = true
        admission_details.save!
      end
    end
  end
end
