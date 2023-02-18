module Mis::NewClinicalReports::Ipd
  class StructureProcedureDetails
    class << self
      def call(list, facility_id, admission_id)
        procedures = list[:procedures].select do |prcedures| 
          prcedures['admission_id'].in?([admission_id, BSON::ObjectId(admission_id)])
        end
        procedures.each do |pl|
          patient_id = list[:patient_id]
          patient = Patient.find_by(id: patient_id)
          patient_name = patient.fullname
          patient_display_id = patient.patient_identifier_id
          patient_mr_no = patient.patient_mrn
          patient_age = patient.exact_age
          age = (patient.age.to_i == 0 && patient.dob_year.present?) ? (Date.current.year - patient.dob_year.to_i) : patient.age
          patient_gender = patient.gender
          patient_mobilenumber = patient.mobilenumber
          commune = patient.commune
          district = patient.district
          state = patient.state
          pincode = patient.pincode
          city = patient.city
          patient_type = patient.patient_type.id rescue nil
          dob_year = patient.dob_year
          procedurename = pl[:procedurename]
          patient_details = { patient_name: patient_name, patient_display_id: patient_display_id,
                              patient_mr_no: patient_mr_no, patient_age: patient_age, age: age,
                              patient_gender: patient_gender, patient_type: patient_type,
                              patient_mobilenumber: patient_mobilenumber, commune: commune, district: district,
                              state: state, pincode: pincode, city: city, patient_id: patient_id, dob_year: dob_year }

          procedure_details = MisClinical::Ipd::PatientProcedureWise.find_or_create_by(
            organisation_id: list[:organisation_id], facility_id: facility_id,
            admission_id: admission_id, procedure_id: pl[:procedure_id],
            procedureside: pl[:procedureside] , case_sheet_id: list[:_id]
          )
          
          procedure_details.patient_details = patient_details
          procedure_details.procedurename = procedurename
          procedure_details.procedurestage = pl[:procedurestage]
          procedure_details.procedureregion = pl[:procedureregion]
          procedure_details.procedurestatus = pl[:procedurestatus]
          procedure_details.procedureapproach = pl[:procedureapproach]
          procedure_details.proceduretype = pl[:proceduretype]
          procedure_details.procedurequalifier = pl[:procedurequalifier]
          procedure_details.proceduresubqualifier = pl[:proceduresubqualifier]
          procedure_details.counselling = pl[:counselling]
          procedure_details.billing = pl[:billing]
          procedure_details.surgerydate = pl[:surgerydate]
          procedure_details.procedure_type = pl[:procedure_type]
          procedure_details.ot_checklist = pl[:ot_checklist]
          procedure_details.procedure_cnt = pl[:procedure_cnt]
          procedure_details.has_complications = pl[:has_complications]
          procedure_details.is_advised = pl[:is_advised]
          procedure_details.advised_by_id = pl[:advised_by_id]
          procedure_details.advised_by = nil
          procedure_details.advised_by = (pl[:advised_by].present?) ? pl[:advised_by] : User.find_by(id: pl[:advised_by_id]).fullname if pl[:advised_by_id].present?
          procedure_details.advised_at_facility = pl[:advised_at_facility]
          procedure_details.advised_at_facility_id = pl[:advised_at_facility_id]
          procedure_details.advised_datetime = pl[:advised_datetime]
          procedure_details.has_agreed = pl[:has_agreed]
          procedure_details.agreed_from = pl[:agreed_from]
          procedure_details.agreed_by = pl[:agreed_by]
          procedure_details.agreed_by_id = pl[:agreed_by_id]
          procedure_details.agreed_at_facility = pl[:agreed_at_facility]
          procedure_details.agreed_at_facility_id = pl[:agreed_at_facility_id]
          procedure_details.agreed_datetime = pl[:agreed_datetime]
          procedure_details.has_declined = pl[:has_declined]
          procedure_details.declined_from = pl[:declined_from]
          procedure_details.declined_by = pl[:declined_by]
          procedure_details.declined_by_id = pl[:declined_by_id]
          procedure_details.declined_at_facility = pl[:declined_at_facility]
          procedure_details.declined_at_facility_id = pl[:declined_at_facility_id]
          procedure_details.declined_datetime = pl[:declined_datetime]
          procedure_details.payment_taken = pl[:payment_taken]
          procedure_details.payment_taken_from = pl[:payment_taken_from]
          procedure_details.payment_taken_by = pl[:payment_taken_by]
          procedure_details.payment_taken_by_id = pl[:payment_taken_by_id]
          procedure_details.payment_taken_at_facility = pl[:payment_taken_at_facility]
          procedure_details.payment_taken_at_facility_id = pl[:payment_taken_at_facility_id]
          procedure_details.payment_taken_datetime = pl[:payment_taken_datetime]
          procedure_details.is_converted = pl[:is_converted]
          procedure_details.converted_from = pl[:converted_from]
          procedure_details.converted_by = pl[:converted_by]
          procedure_details.converted_by_id = pl[:converted_by_id]
          procedure_details.converted_at_facility = pl[:converted_at_facility]
          procedure_details.converted_at_facility_id = pl[:converted_at_facility_id]
          procedure_details.converted_datetime = pl[:converted_datetime]
          procedure_details.in_admission = pl[:in_admission]
          procedure_details.is_performed = pl[:is_performed]
          procedure_details.performed_by = pl[:performed_by]
          procedure_details.performed_by_id = pl[:performed_by_id]
          procedure_details.performed_from = pl[:performed_from]
          procedure_details.performed_at_facility = pl[:performed_at_facility]
          procedure_details.performed_at_facility_id = pl[:performed_at_facility_id]
          procedure_details.performed_datetime = pl[:performed_datetime]
          procedure_details.performed_comment = pl[:performed_comment]
          procedure_details.performed_note_id = pl[:performed_note_id]
          procedure_details.users_comment = pl[:users_comment]
          procedure_details.conversion_time_days = conversion_time(pl[:advised_datetime], pl[:performed_datetime])

          procedure_details.save!
        end
      rescue StandardError => e
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        mis_logger.info(" === Error in StructureProcedureDetails while importing procedure details data: #{e.inspect}")
      end

      def conversion_time(advised_dt, performed_dt)
        if advised_dt.present? && performed_dt.present?
          (performed_dt.to_date - advised_dt.to_date).to_i
        else
          ''
        end
      end
    end
  end
end
