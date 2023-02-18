module Investigation
  module PatientOpd
    module CreateService
      def self.call(investigation, flag)
        # it saves investigation in patient-opd created from investigation section
        patient_opd = ::PatientOpd.find_by(id: investigation.patient_id)

        if patient_opd
          if patient_opd.records.count > 0

            record = patient_opd.records.where(appointment_id: investigation.appointment_id).order(created_at: :desc)[0]

            if record.present?

              if flag == 'ophthal'
                record.ophthal_investigations_list.create!(billing: false, counselling: false, investigation_id: investigation.investigation_id, investigation_performed: investigation.try(:investigation_performed), investigationadviseddate: investigation.created_at.strftime("%d/%m/%Y"), investigationfullcode: investigation.investigation_full_code, investigationname: investigation.name, investigationside: investigation.investigation_side, investigationstage: "A", created_from_template: false, record_id: nil, investigation_detail_id: investigation.id, investigation_comment: "", investigation_val: "", doctors_remark: "")

              elsif flag == 'radiology'
                record.radiology_investigations_list.create!(billing: false, counselling: false, investigation_id: investigation.investigation_id, investigation_performed: investigation.try(:investigation_performed), investigationadviseddate: investigation.created_at.strftime("%d/%m/%Y"), investigationfullcode: investigation.investigation_full_code, radiologyoptions: investigation.try(:radiology_options), investigationname: investigation.name, investigationside: investigation.laterality, investigationstage: "A", loinccode: investigation.loinc_code, created_from_template: false, record_id: nil, investigation_detail_id: investigation.id, haslaterality: investigation.has_laterality, is_spine: investigation.is_spine, investigation_comment: "", investigation_val: "", doctors_remark: "")

              elsif flag == 'laboratory'
                record.laboratory_investigations_list.create!(billing: false, counselling: false, investigation_id: investigation.investigation_id, investigation_performed: investigation.try(:investigation_performed), investigationadviseddate: investigation.created_at.strftime("%d/%m/%Y"), loinc_class: investigation.loinc_class, loinc_code: investigation.loinc_code, investigationfullcode: investigation.investigation_full_code, investigationname: investigation.name, investigationside: investigation.try(:investigation_side), investigationstage: "A", created_from_template: false, record_id: nil, investigation_detail_id: investigation.id, doctors_remark: "", investigation_val: "", specimen_type: "", investigation_comment: "", normal_range: "")
              end
              investigation.update(investigation_patient_opd_record_id: record.id)
            end
          end
        end
      end
    end
  end
end
