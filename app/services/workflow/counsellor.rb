module Workflow
  class Counsellor
    def initialize(opd_workflow, patient, user, current_user)
      @opd_workflow = opd_workflow
      @patient = patient
      @user = user
      @current_user = current_user
    end

    def create
      counsellor_flow = CounsellorWorkflow.create(create_attributes)
    end

    private

    def create_attributes
      {
        :patient_id => @opd_workflow.patient_id,
        appointment_id: @opd_workflow.appointment_id.to_s,
        facility_id: @opd_workflow.facility_id,
        organisation_id: @current_user.organisation.id,
        user_id: @user.id,
        adviseddate: Date.current,
        patient_name: @patient.fullname,
        counsellingdate: @opd_workflow.appointmentdate,
        start_time: Time.current,
        appointmentdate: @opd_workflow.appointmentdate,
        patient_type: @opd_workflow.patient_type,
        patient_type_color: @opd_workflow.patient_type_color
      }
    end
  end
end
