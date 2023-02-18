module Mis::NewClinicalReports
  class StructureProcedureDetails
    class << self
      def call(list, record_id=nil, record_type=nil)
        list = CaseSheet.find_by(id: list)

        # remove deleted procedures
        casesheet_procedures = list.procedures.pluck(:_id)
        MisClinical::Common::PatientProcedureWise.where(case_sheet_id: list.id, :case_sheet_procedure_id.nin => casesheet_procedures).destroy_all
        # EOF remove deleted procedures

        list.procedures.each do |pl|
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
          location_id = patient&.location_id
          area_manager_id = patient&.area_manager_id
          area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
          patient_type = patient.patient_type.id rescue nil
          dob_year = patient.dob_year
          address_1 = patient.address_1
          address_2 = patient.address_2
          procedurename = pl[:procedurename]
          patient_details = { patient_name: patient_name, patient_display_id: patient_display_id,
                              patient_mr_no: patient_mr_no, patient_age: patient_age, age: age,
                              patient_gender: patient_gender, patient_type: patient_type,
                              patient_mobilenumber: patient_mobilenumber, commune: commune, 
                              district: district, state: state, pincode: pincode, city: city,
                              location_id: location_id, area_manager_id: area_manager_id,
                              area_manager_name: area_manager_name, 
                              patient_id: patient_id, dob_year: dob_year, address_1: address_1,
                              address_2: address_2 }

          procedure_details = MisClinical::Common::PatientProcedureWise.find_or_create_by(
            case_sheet_procedure_id: pl[:_id], case_sheet_id: list[:_id], 
            facility_id: pl[:advised_at_facility_id]
          )
          procedure_details.procedure_id = pl[:procedure_id]
          procedure_details.order_advised_id =  pl[:order_advised_id]
          procedure_details.procedureside = pl[:procedureside]
          procedure_details.entered_from = list[:entered_from]
          procedure_details.advised_from = list[:advised_from]
          procedure_details.record_id = pl[:record_id]
          procedure_details.order_item_advised_id =  pl[:order_item_advised_id].to_s
          procedure_details.ipd_record_id = pl[:ipd_record_id]
          procedure_details.organisation_id = list[:organisation_id]
          procedure_details.advised_at_facility = pl[:advised_at_facility]
          procedure_details.advised_at_facility_id = pl[:advised_at_facility_id]
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
          procedure_details.advised_by = (pl[:advised_by].present?) ? pl[:advised_by] : User.find_by(id: pl[:advised_by_id]).try(:fullname)
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
          performed_date = performed_time = nil
          if pl[:performed_datetime].present?
            facility_timezone = Facility.find_by(id: pl[:advised_at_facility_id]).try(:time_zone)
            converted_performed = pl[:performed_datetime].in_time_zone(facility_timezone)
            performed_date = if pl[:performed_date].present? 
                                pl[:performed_date] 
                              elsif converted_performed.present?
                                converted_performed.to_date
                              end
            performed_time = if pl[:performed_time].present? 
                                pl[:performed_time] 
                              elsif performed_date.present?
                                performed_date.in_time_zone(facility_timezone).noon
                              end
          end
          procedure_details.performed_date = performed_date
          procedure_details.performed_time = performed_time
          procedure_details.performed_comment = pl[:performed_comment]
          procedure_details.performed_note_id = pl[:performed_note_id]
          procedure_details.users_comment = pl[:users_comment]
          procedure_details.previous_stage = pl[:previous_stage]
          procedure_details.conversion_time_days = conversion_time(pl[:advised_datetime], performed_time)
          procedure_details.save!
        end
      rescue StandardError => e
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        mis_logger.info(" === Error in import procedure level 2 data: #{e.inspect}")
      end

      def conversion_time(advised_dt, performed_dt)
        if advised_dt.present? && performed_dt.present?
          (performed_dt.to_date - advised_dt.to_date).to_i
        else
          ''
        end
      end
      # EOF conversion_time
    end
  end
end
