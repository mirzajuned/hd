# rubocop:disable all
module Mis::ClinicalService
  class AppointmentReportConverter
    class << self
      def get_total_time(appointment_id)
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s)
        workflow.try(:state) == 'not_arrived' || workflow.try(:state) == 'cancelled' ? 'NA' : workflow.try(:total_transition_time_in_org)
      end

      def get_total_time_epoch(appointment_id)
        workflows = OpdClinicalWorkflow.where(appointment_id: appointment_id.to_s)
        total = workflows.map do |wf|
           wf.state == 'not_arrived' || wf.state == 'cancelled' ? 0 : wf.total_transition_time_in_epoch
        end
        total.sum
      end

      def get_avg_engaged_time_epoc(app_id)
        workflow = OpdClinicalWorkflow.find_by(appointment_id: app_id.to_s).id
        engaged_time_in_epoch = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow,
                                                                         :from.nin => ['not_arrived', 'cancelled'],
                                                                         :to.nin => ['complete']).to_a
                                                                  .map { |t| [(t.transition_end || DateTime.current.utc) - t.transition_start] }

        engaged_time_in_epoch.sum[0].to_i
      end

      def get_engaged_time(appointment_id)
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s)
        engaged_time_in_epoch = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: workflow,
                                                                         :from.nin => ['not_arrived', 'cancelled'],
                                                                         :to.nin => ['complete']).to_a
                                                                  .map do |t|
          [
            (t.transition_end || DateTime.current.utc) - t.transition_start
          ]
        end
        convert_time(engaged_time_in_epoch.sum[0].to_i)
      end

      def get_doctor_ids(appointment_id)
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s)
        workflow.try(:consultant_ids)
      end

      def get_waiting_time(appointment_id)
        # TODO: -> no waiting time has been defined yet
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s)
        time = workflow.opd_clinical_workflow_state_transitions.where(from: 'not_arrived').to_a.map do |a|
          [a.transition_start, a.transition_end]
        end.flatten
        time_difference = time[1] - time[0]
        (time_difference / (1000 * 60)) % 60
      end

      def get_other_doctors(appointment_id)
        appointment = Appointment.find_by(id: appointment_id.to_s)
        user = User.find_by(id: appointment.try(:consultant_id).to_s)
        consultant_id_role_ids = user.present? ? user.role_ids : []
        workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s)
        if consultant_id_role_ids.include? 158965000
          workflow.consultant_ids.map { |doc| User.find_by(id: doc).try(:fullname) }.join(', ') rescue ''
        end
      end

      def get_other_users(appointment_id)
        counsellor_ids = CounsellorWorkflow.where(appointment_id: appointment_id.to_s).pluck(:id)
        optometrist_ids = OpdClinicalWorkflow.find_by(appointment_id: appointment_id.to_s).try(:optometrist_ids) || []
        user_ids = counsellor_ids + optometrist_ids
        user_ids.map { |user| User.find_by(id: user).try(:fullname) }.join(', ')  rescue ''
      end

      def convert_time(sec)
        "%02d:%02d:%02d" % [sec / 3600, sec / 60 % 60, sec % 60]
      end
    end
  end
end
