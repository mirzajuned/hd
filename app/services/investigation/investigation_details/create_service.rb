module Investigation
  module InvestigationDetails
    module CreateService
      def self.call(opdrecord, flag)
        appointment = Appointment.find_by(id: opdrecord.appointmentid)
        user = User.find(opdrecord.record_histories[0].user_id)
        facility = Facility.find_by(id: appointment.facility_id)
        case_sheet = CaseSheet.find_by(id: opdrecord.case_sheet_id)

        if flag == 'laboratory'
          @queue = Investigation::Queues::CreateService.call(appointment.id, appointment.patient, flag, user, facility, appointment.start_time)
          if @queue.present?
            @all_laboratory = Investigation::Laboratory.where(opd_record_id: opdrecord.id.to_s)
            @all_laboratory.try(:each) do |laboratory|
              laboratory.update(is_deleted: true)
            end

            opdrecord.addedlaboratoryinvestigationlist.each do |laboratory|
              if Date.parse(laboratory.investigationadviseddate) == Date.current
                datetime = Time.current
              else
                datetime = laboratory.investigationadviseddate + " " + Time.current.strftime('%I:%M %p')
              end
              @laboratory_investigation = @all_laboratory.find_by(opd_investigation_id: laboratory.id.to_s)
              if @laboratory_investigation.nil?
                @laboratory_investigation = Investigation::Laboratory.new
                @laboratory_investigation['name'] = laboratory.investigationname
                @laboratory_investigation['loinc_class'] = laboratory.loinc_class
                @laboratory_investigation['loinc_code'] = laboratory.loinc_code
                @laboratory_investigation['investigation_id'] = laboratory.investigation_id
                @laboratory_investigation['opd_investigation_id'] = laboratory.id
                @laboratory_investigation['investigation_full_code'] = laboratory.investigationfullcode
                @laboratory_investigation['investigation_type'] = laboratory.investigation_type
                @laboratory_investigation['requested_by'] = opdrecord.userid
                @laboratory_investigation['entered_by'] = laboratory.entered_by_id
                @laboratory_investigation['order_item_advised_id'] = laboratory.order_item_advised_id.to_s
                @laboratory_investigation['entered_by_username'] = laboratory.entered_by
                @laboratory_investigation['entered_at'] = laboratory.entered_datetime
                @laboratory_investigation['entered_at_facility_id'] = laboratory.entered_at_facility_id
                @laboratory_investigation['entered_at_facility_name'] = laboratory.entered_at_facility
                @laboratory_investigation['advised_by'] = laboratory.advised_by_id
                @laboratory_investigation['advised_by_username'] = laboratory.advised_by
                @laboratory_investigation['advised_at'] = laboratory.advised_datetime
                @laboratory_investigation['advised_at_facility_id'] = laboratory.advised_at_facility_id
                @laboratory_investigation['advised_at_facility_name'] = laboratory.advised_at_facility
                @laboratory_investigation['opd_record_id'] = opdrecord.id
                @laboratory_investigation['facility_id'] = appointment.facility_id
                @laboratory_investigation['organisation_id'] = appointment.organisation_id
                @laboratory_investigation['patient_id'] = appointment.patient_id
                @laboratory_investigation['appointment_id'] = appointment.id
                @laboratory_investigation['queue_id'] = @queue.id
                @laboratory_investigation['case_sheet_id'] = opdrecord.case_sheet_id
                if laboratory.investigationstage == 'P'
                  @laboratory_investigation['performed_by'] = laboratory.performed_by_id
                  @laboratory_investigation['performed_by_username'] = laboratory.performed_by
                  @laboratory_investigation['performed_at'] = laboratory.performed_datetime
                  @laboratory_investigation['date_performed_at'] = laboratory.performed_datetime
                  @laboratory_investigation['performed_at_facility_id'] = laboratory.performed_at_facility_id
                  @laboratory_investigation['performed_at_facility_name'] = laboratory.performed_at_facility
                  @laboratory_investigation['performed_from'] = "opd_record"
                end
                @laboratory_investigation = self.update_patient_details(@laboratory_investigation)
                @laboratory_investigation.save

                case_sheet_investigation = case_sheet.laboratory_investigations.find_by(opd_investigation_id: laboratory.id)
                case_sheet_investigation.update(detail_investigation_id: @laboratory_investigation.id) if case_sheet_investigation.present?

                @laboratory_investigation.performed if laboratory.investigationstage == 'P'
                @queue.update(appointment_date: @laboratory_investigation.advised_at, appointment_time: @laboratory_investigation.advised_at) if @laboratory_investigation.advised_at > @queue.appointment_time
              else
                @laboratory_investigation['name'] = laboratory.investigationname
                @laboratory_investigation['loinc_class'] = laboratory.loinc_class
                @laboratory_investigation['loinc_code'] = laboratory.loinc_code
                @laboratory_investigation['investigation_id'] = laboratory.investigation_id
                @laboratory_investigation['opd_investigation_id'] = laboratory.id
                @laboratory_investigation['investigation_full_code'] = laboratory.investigationfullcode
                @laboratory_investigation['investigation_type'] = laboratory.investigation_type
                @laboratory_investigation['order_item_advised_id'] = laboratory.order_item_advised_id.to_s
                @laboratory_investigation['is_deleted'] = false
                if @laboratory_investigation.performed_from.to_s == "" || @laboratory_investigation.performed_from == "opd_record"
                  if laboratory.investigationstage == 'P'
                    @laboratory_investigation['performed_by'] = laboratory.performed_by_id
                    @laboratory_investigation['performed_by_username'] = laboratory.performed_by
                    @laboratory_investigation['performed_at'] = laboratory.performed_datetime
                    @laboratory_investigation['date_performed_at'] = laboratory.performed_datetime
                    @laboratory_investigation['performed_at_facility_id'] = laboratory.performed_at_facility_id
                    @laboratory_investigation['performed_at_facility_name'] = laboratory.performed_at_facility
                    @laboratory_investigation['performed_from'] = "opd_record"
                  else
                    @laboratory_investigation['performed_by'] = ""
                    @laboratory_investigation['performed_by_username'] = ""
                    @laboratory_investigation['performed_at'] = ""
                    @laboratory_investigation['date_performed_at'] = ""
                    @laboratory_investigation['performed_at_facility_id'] = ""
                    @laboratory_investigation['performed_at_facility_name'] = ""
                    @laboratory_investigation['performed_from'] = ""
                    state =  if laboratory.investigationstage == 'A' && @laboratory_investigation.try(:state) == 'performed'
                                 "advised"
                              else
                                @laboratory_investigation.try(:state) || "advised"
                              end
                    @laboratory_investigation['state'] = state
                    @laboratory_investigation['previous_state'] = @laboratory_investigation.try(:previous_state) || []
                  end
                end
                @laboratory_investigation = self.update_patient_details(@laboratory_investigation)
                @laboratory_investigation.update
                @laboratory_investigation.performed if laboratory.investigationstage == 'P'

                if @queue.appointment_time.present?
                  @queue.update(appointment_date: @laboratory_investigation.advised_at, appointment_time: @laboratory_investigation.advised_at) if @laboratory_investigation.advised_at > @queue.appointment_time
                end
              end
            end
          end
        end

        if flag == 'ophthal'
          @queue = Investigation::Queues::CreateService.call(appointment.id, appointment.patient, flag, user, facility, appointment.start_time)
          if @queue.present?
            @all_ophthal = Investigation::Ophthal.where(opd_record_id: opdrecord.id.to_s)
            @all_ophthal.try(:each) do |ophthal|
              ophthal.update(is_deleted: true)
            end

            opdrecord.ophthalinvestigationlist.each do |ophthal|
              if Date.parse(ophthal.investigationadviseddate) == Date.current
                datetime = Time.current
              else
                datetime = ophthal.investigationadviseddate + " " + Time.current.strftime('%I:%M %p')
              end
              ophthal_investigation_side_array = [ophthal.investigationside.to_s]
              ophthal_investigation_side_array.each_with_index do |side, i|
                @ophthal_investigations = @all_ophthal.where(opd_investigation_id: ophthal.id.to_s)
                if ophthal_investigation_side_array.count > 1 && @ophthal_investigations.count == 1
                  @ophthal_investigation = @ophthal_investigations.find_by(investigation_side: side)
                elsif ophthal_investigation_side_array.count < 2 && @ophthal_investigations.count > 1
                  @ophthal_investigation = @ophthal_investigations.find_by(investigation_side: side)
                  @ophthal_investigations.not.where(investigation_side: side).destroy
                else
                  @ophthal_investigation = @ophthal_investigations.find_by(investigation_side: side)
                end

                if @ophthal_investigation.nil?
                  @ophthal_investigation = Investigation::Ophthal.new
                  @ophthal_investigation['name'] = ophthal.investigationname
                  @ophthal_investigation['investigation_side'] = side
                  @ophthal_investigation['investigation_id'] = ophthal.investigation_id
                  @ophthal_investigation['opd_investigation_id'] = ophthal.id
                  @ophthal_investigation['investigation_full_code'] = ophthal.investigationfullcode
                  @ophthal_investigation['investigation_type'] = ophthal.investigation_type
                  @ophthal_investigation['is_deleted'] = false
                  @ophthal_investigation['requested_by'] = opdrecord.userid
                  @ophthal_investigation['order_item_advised_id'] = ophthal.order_item_advised_id.to_s
                  @ophthal_investigation['entered_by'] = ophthal.entered_by_id
                  @ophthal_investigation['entered_by_username'] = ophthal.entered_by
                  @ophthal_investigation['entered_at'] = ophthal.entered_datetime
                  @ophthal_investigation['entered_at_facility_id'] = ophthal.entered_at_facility_id
                  @ophthal_investigation['entered_at_facility_name'] = ophthal.entered_at_facility
                  @ophthal_investigation['advised_by'] = ophthal.advised_by_id
                  @ophthal_investigation['advised_by_username'] = ophthal.advised_by
                  @ophthal_investigation['advised_at'] = ophthal.advised_datetime
                  @ophthal_investigation['advised_at_facility_id'] = ophthal.advised_at_facility_id
                  @ophthal_investigation['advised_at_facility_name'] = ophthal.advised_at_facility
                  @ophthal_investigation['opd_record_id'] = opdrecord.id
                  @ophthal_investigation['facility_id'] = appointment.facility_id
                  @ophthal_investigation['organisation_id'] = appointment.organisation_id
                  @ophthal_investigation['patient_id'] = appointment.patient_id
                  @ophthal_investigation['appointment_id'] = appointment.id
                  @ophthal_investigation['queue_id'] = @queue.id
                  @ophthal_investigation['case_sheet_id'] = opdrecord.case_sheet_id
                  if ophthal.investigationstage == 'P'
                    @ophthal_investigation['performed_by'] = ophthal.performed_by_id
                    @ophthal_investigation['performed_by_username'] = ophthal.performed_by
                    @ophthal_investigation['performed_at'] = ophthal.performed_datetime
                    @ophthal_investigation['date_performed_at'] = ophthal.performed_datetime
                    @ophthal_investigation['performed_at_facility_id'] = ophthal.performed_at_facility_id
                    @ophthal_investigation['performed_at_facility_name'] = ophthal.performed_at_facility
                    @ophthal_investigation['performed_from'] = "opd_record"
                  end
                  @ophthal_investigation = self.update_patient_details(@ophthal_investigation)
                  @ophthal_investigation['specialization'] = self.ophtal_specialization(side)
                  @ophthal_investigation.save

                  case_sheet_investigation = case_sheet.ophthal_investigations.find_by(opd_investigation_id: ophthal.id, investigationside: side)
                  case_sheet_investigation.update(detail_investigation_id: @ophthal_investigation.id) if case_sheet_investigation.present?

                  @ophthal_investigation.performed if ophthal.investigationstage == 'P'
                  @queue.update(appointment_date: @ophthal_investigation.advised_at, appointment_time: @ophthal_investigation.advised_at) if @ophthal_investigation.advised_at > @queue.appointment_time
                else
                  @ophthal_investigation['name'] = ophthal.investigationname
                  @ophthal_investigation['investigation_side'] = side
                  @ophthal_investigation['investigation_id'] = ophthal.investigation_id
                  @ophthal_investigation['opd_investigation_id'] = ophthal.id
                  @ophthal_investigation['investigation_full_code'] = ophthal.investigationfullcode
                  @ophthal_investigation['investigation_type'] = ophthal.investigation_type
                  @ophthal_investigation['order_item_advised_id'] = ophthal.order_item_advised_id.to_s
                  @ophthal_investigation['is_deleted'] = false
                  if @ophthal_investigation.performed_from.to_s == "" || @ophthal_investigation.performed_from == "opd_record"
                    if ophthal.investigationstage == 'P'
                      @ophthal_investigation['performed_by'] = ophthal.performed_by_id
                      @ophthal_investigation['performed_by_username'] = ophthal.performed_by
                      @ophthal_investigation['performed_at'] = ophthal.performed_datetime
                      @ophthal_investigation['date_performed_at'] = ophthal.performed_datetime
                      @ophthal_investigation['performed_at_facility_id'] = ophthal.performed_at_facility_id
                      @ophthal_investigation['performed_at_facility_name'] = ophthal.performed_at_facility
                      @ophthal_investigation['performed_from'] = "opd_record"
                    else
                      @ophthal_investigation['performed_by'] = ""
                      @ophthal_investigation['performed_by_username'] = ""
                      @ophthal_investigation['performed_at'] = ""
                      @ophthal_investigation['date_performed_at'] = ""
                      @ophthal_investigation['performed_at_facility_id'] = ""
                      @ophthal_investigation['performed_at_facility_name'] = ""
                      @ophthal_investigation['performed_from'] = ""
                      state =  if ophthal.investigationstage == 'A' && @ophthal_investigation.try(:state) == 'performed'
                                 "advised"
                              else
                                @ophthal_investigation.try(:state) || "advised"
                              end
                      @ophthal_investigation['state'] = state
                      @ophthal_investigation['previous_state'] = @ophthal_investigation.try(:previous_state) || []
                    end
                  end
                  @ophthal_investigation = self.update_patient_details(@ophthal_investigation)
                  @ophthal_investigation['specialization'] = self.ophtal_specialization(side)
                  @ophthal_investigation.update
                  @ophthal_investigation.performed if ophthal.investigationstage == 'P'
                  if @queue.appointment_time.present?
                    @queue.update(appointment_date: @ophthal_investigation.advised_at, appointment_time: @ophthal_investigation.advised_at) if @ophthal_investigation.advised_at > @queue.appointment_time
                  end
                end
              end
            end
          end
        end

        if flag == 'radiology'
          @queue = Investigation::Queues::CreateService.call(appointment.id, appointment.patient, flag, user, facility, appointment.start_time)
          if @queue.present?
            @all_radiology = Investigation::Radiology.where(opd_record_id: opdrecord.id.to_s)
            @all_radiology.try(:each) do |radiology|
              radiology.update(is_deleted: true)
            end

            opdrecord.investigationlist.each do |radiology|
              if Date.parse(radiology.investigationadviseddate) == Date.current
                datetime = Time.current
              else
                datetime = radiology.investigationadviseddate + " " + Time.current.strftime('%I:%M %p')
              end
              @radiology_investigation = @all_radiology.find_by(opd_investigation_id: radiology.id.to_s)
              if @radiology_investigation.nil?
                @radiology_investigation = Investigation::Radiology.new
                @radiology_investigation['name'] = radiology.investigationname
                @radiology_investigation['investigation_id'] = radiology.investigation_id
                @radiology_investigation['opd_investigation_id'] = radiology.id
                @radiology_investigation['investigation_full_code'] = radiology.investigationfullcode
                @radiology_investigation['investigation_type'] = radiology.investigation_type
                @radiology_investigation['has_laterality'] = radiology.haslaterality
                @radiology_investigation['laterality'] = radiology.laterality
                @radiology_investigation['is_spine'] = radiology.is_spine
                @radiology_investigation['loinc_code'] = radiology.loinccode
                @radiology_investigation['radiology_options'] = radiology.radiologyoptions
                @radiology_investigation['order_item_advised_id'] = radiology.order_item_advised_id.to_s
                @radiology_investigation['requested_by'] = opdrecord.userid
                @radiology_investigation['entered_by'] = radiology.entered_by_id
                @radiology_investigation['entered_by_username'] = radiology.entered_by
                @radiology_investigation['entered_at'] = radiology.entered_datetime
                @radiology_investigation['entered_at_facility_id'] = radiology.entered_at_facility_id
                @radiology_investigation['entered_at_facility_name'] = radiology.entered_at_facility
                @radiology_investigation['advised_by'] = radiology.advised_by_id
                @radiology_investigation['advised_by_username'] = radiology.advised_by
                @radiology_investigation['advised_at'] = radiology.advised_datetime
                @radiology_investigation['advised_at_facility_id'] = radiology.advised_at_facility_id
                @radiology_investigation['advised_at_facility_name'] = radiology.advised_at_facility
                @radiology_investigation['opd_record_id'] = opdrecord.id
                @radiology_investigation['facility_id'] = appointment.facility_id
                @radiology_investigation['organisation_id'] = appointment.organisation_id
                @radiology_investigation['patient_id'] = appointment.patient_id
                @radiology_investigation['appointment_id'] = appointment.id
                @radiology_investigation['queue_id'] = @queue.id
                @radiology_investigation['case_sheet_id'] = opdrecord.case_sheet_id
                if radiology.investigationstage == 'P'
                  @radiology_investigation['performed_by'] = radiology.performed_by_id
                  @radiology_investigation['performed_by_username'] = radiology.performed_by
                  @radiology_investigation['performed_at'] = radiology.performed_datetime
                  @radiology_investigation['date_performed_at'] = radiology.performed_datetime
                  @radiology_investigation['performed_at_facility_id'] = radiology.performed_at_facility_id
                  @radiology_investigation['performed_at_facility_name'] = radiology.performed_at_facility
                  @radiology_investigation['performed_from'] = "opd_record"
                end
                @radiology_investigation = self.update_patient_details(@radiology_investigation)
                @radiology_investigation['specialization'] = self.radiology_specialization(@radiology_investigation.radiology_options)
                @radiology_investigation.save

                case_sheet_investigation = case_sheet.radiology_investigations.find_by(opd_investigation_id: radiology.id)
                case_sheet_investigation.update(detail_investigation_id: @radiology_investigation.id) if case_sheet_investigation.present?

                @radiology_investigation.performed if radiology.investigationstage == 'P'
                @queue.update(appointment_date: @radiology_investigation.advised_at, appointment_time: @radiology_investigation.advised_at) if @radiology_investigation.advised_at > @queue.appointment_time
              else
                @radiology_investigation['name'] = radiology.investigationname
                @radiology_investigation['investigation_id'] = radiology.investigation_id
                @radiology_investigation['opd_investigation_id'] = radiology.id
                @radiology_investigation['investigation_full_code'] = radiology.investigationfullcode
                @radiology_investigation['investigation_type'] = radiology.investigation_type
                @radiology_investigation['has_laterality'] = radiology.haslaterality
                @radiology_investigation['laterality'] = radiology.laterality
                @radiology_investigation['is_spine'] = radiology.is_spine
                @radiology_investigation['order_item_advised_id'] = radiology.order_item_advised_id.to_s
                @radiology_investigation['loinc_code'] = radiology.loinccode
                @radiology_investigation['radiology_options'] = radiology.radiologyoptions
                @radiology_investigation['is_deleted'] = false
                if @radiology_investigation.performed_from.to_s == "" || @radiology_investigation.performed_from == "opd_record"
                  if radiology.investigationstage == 'P'
                    @radiology_investigation['performed_by'] = radiology.performed_by_id
                    @radiology_investigation['performed_by_username'] = radiology.performed_by
                    @radiology_investigation['performed_at'] = radiology.performed_datetime
                    @radiology_investigation['date_performed_at'] = radiology.performed_datetime
                    @radiology_investigation['performed_at_facility_id'] = radiology.performed_at_facility_id
                    @radiology_investigation['performed_at_facility_name'] = radiology.performed_at_facility
                    @radiology_investigation['performed_from'] = "opd_record"
                  else
                    @radiology_investigation['performed_by'] = ""
                    @radiology_investigation['performed_by_username'] = ""
                    @radiology_investigation['performed_at'] = ""
                    @radiology_investigation['date_performed_at'] = ""
                    @radiology_investigation['performed_at_facility_id'] = ""
                    @radiology_investigation['performed_at_facility_name'] = ""
                    @radiology_investigation['performed_from'] = ""
                    state =  if radiology.investigationstage == 'A' && @radiology_investigation.try(:state) == 'performed'
                                 "advised"
                              else
                                @radiology_investigation.try(:state) || "advised"
                              end
                    @radiology_investigation['state'] = state
                    @radiology_investigation['previous_state'] = @radiology_investigation.try(:previous_state) || []
                  end
                end
                @radiology_investigation = self.update_patient_details(@radiology_investigation)
                @radiology_investigation['specialization'] = self.radiology_specialization(@radiology_investigation.radiology_options)
                @radiology_investigation.update
                @radiology_investigation.performed if radiology.investigationstage == 'P'
                if @queue.appointment_time.present?
                  @queue.update(appointment_date: @radiology_investigation.advised_at, appointment_time: @radiology_investigation.advised_at) if @radiology_investigation.advised_at > @queue.appointment_time
                end
              end
            end
          end
        end
      end

      def self.ophtal_specialization(side)
        if side == '40638003'
          '(B/E)'
        elsif side == '18944008'
          '(R)'
        elsif side == '8966001'
          '(L)'
        else
          ''
        end
      end

      def self.radiology_specialization(options)
        if options == '90084008'
         'w/o contrast'
        elsif options == '51619007'
         'with contrast'
        elsif options == '429859008'
         'with complete screening'
        elsif options == '431985004'
         'screening of other region'
        elsif options == '22400007'
         '3D-reconstruction'
        else
         ''
        end
      end

      def self.update_patient_details(investigation)
        patient = investigation.patient
        location_id = patient&.location_id
        area_manager_id = patient&.area_manager_id
        area_manager_name = (location_id.present? && area_manager_id.present? && (patient&.area_manager_name.to_s == '')) ? Location.find_by(id: location_id).selected_area_name(area_manager_id) : patient&.area_manager_name
        investigation.patient_fullname = patient.fullname
        investigation.patient_mobilenumber = patient.mobilenumber
        investigation.patient_display_id = patient.patient_identifier_id
        investigation.patient_mrno = patient.patient_mrn
        investigation.patient_location = patient.patient_full_address
        investigation.patient_gender = patient.gender
        investigation.patient_age = patient.age
        investigation.patient_exact_age = patient.exact_age
        investigation.patient_district = patient.district
        investigation.patient_commune = patient.commune
        investigation.patient_city = patient.city
        investigation.patient_state = patient.state
        investigation.patient_pincode = patient.pincode
        investigation.patient_location_id = location_id
        investigation.patient_area_manager_id = area_manager_id
        investigation.patient_area_manager_name = area_manager_name
        investigation
      end

    end
  end
end
