class OpdRecordWorker
  def initialize(record_id)
    @record_id = record_id
  end

  def call
    opdrecord = OpdRecord.find_by(:id => "#{@record_id}")

    # Create PatientTimeline
    @patient_timeline = PatientTimelines::CreateService.call(opdrecord)

    # Create OpdReferral
    @opd_record_referal = OpdRecords::ReferralService.call(opdrecord) if opdrecord.has_intra_facility_referral? || opdrecord.has_inter_facility_referral?

    # Create PatientPrescription
    @pharmacy_prescription = PatientPrescriptions::CreateService.call(opdrecord) # if opdrecord.has_treatmentmedication?

    # Create PatientOpticalPrescription
    @patient_optical_prescription = PatientOpticalPrescriptions::CreateService.call(opdrecord)

    # Create PatientIntermediateOpticalPrescription
    @patient_optical_prescription = PatientIntermediateOpticalPrescriptions::CreateService.call(opdrecord)

    # Create PatientManagementFollowup
    # @patient_management_followups = PatientManagementFollowups::CreateService.call(opdrecord) if opdrecord.has_advice?

    # Create AppointmentRecords
    # @appointment_records = AppointmentRecords::OpdCreateService.call(opdrecord)

    # CaseSheet Data
    @case_sheet_data = CaseSheet::CreateOpdRecordService.call(opdrecord)

    # Create analytics data
    # Analytics::CreateService.call(@analytics_params, opdrecord.consultant_id ,opdrecord.facility_id, "opd_record")

    # Create Laboratory Content
    laboratory_content(opdrecord)

    # Create PatientDiagnosis
    @patient_diagnosis = PatientDiagnoses::CreateService.call(opdrecord, 'opd')

    # Create PatientProcedure
    @patient_procedure = PatientProcedures::CreateService.call(opdrecord, 'opd')

    @generic_composition = GenericComposition::CreateService.call(opdrecord)

    if opdrecord.organisation_id.to_s == "5e21ffd6cd29ba0ce0bf5a1e" # need to update for sankara medics
      ApiJobs::OrderStatusJob.perform_later('appointment', opdrecord.appointmentid.to_s, 'medics', opdrecord.facility_id.to_s)
    end
  end

  private

  def laboratory_content(opdrecord)
    if (opdrecord.has_ophthalinvestigationlist? || opdrecord.has_addedlaboratoryinvestigationlist? || opdrecord.has_investigationlist?)
      # Create Investigations PatientTests
      if opdrecord.has_ophthalinvestigationlist?
        @patient_investigations = Investigation::InvestigationDetails::CreateService.call(opdrecord, "ophthal")
      else
        @queue = Investigation::Queue.find_by(appointment_id: opdrecord.appointmentid.to_s, investigation_type: "ophthal")
        @ophthal = Investigation::Ophthal.where(opd_record_id: opdrecord.id.to_s)
        delete_investigations(@ophthal, @queue)
      end

      if opdrecord.has_addedlaboratoryinvestigationlist?
        @patient_investigations = Investigation::InvestigationDetails::CreateService.call(opdrecord, "laboratory")
      else
        @queue = Investigation::Queue.find_by(appointment_id: opdrecord.appointmentid.to_s, investigation_type: "laboratory")
        @laboratory = Investigation::Laboratory.where(opd_record_id: opdrecord.id.to_s)
        delete_investigations(@laboratory, @queue)
      end

      if opdrecord.has_investigationlist?
        @patient_investigations = Investigation::InvestigationDetails::CreateService.call(opdrecord, "radiology")
      else
        @queue = Investigation::Queue.find_by(appointment_id: opdrecord.appointmentid.to_s, investigation_type: "radiology")
        @radiology = Investigation::Radiology.where(opd_record_id: opdrecord.id.to_s)
        delete_investigations(@radiology, @queue)
      end
    else
      @queue = Investigation::Queue.where(apppointment_id: opdrecord.appointmentid.to_s)
      if @queue.count > 0
        @queue.each do |q|
          q.update(is_deleted: true)
        end
      end
      @investigations = Investigation::InvestigationDetail.where(opd_record_id: opdrecord.id.to_s)
      @investigations.try(:each) do |inv|
        inv.update(is_deleted: true)
      end
    end
  end

  def delete_investigations(investigation, queue)
    investigation.try(:each) do |inv|
      inv.update(is_deleted: true)
    end

    # Update Investigation::Queue
    queue.update(is_deleted: true) if queue.present?
  end
end
