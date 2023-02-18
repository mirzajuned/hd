class Orders::Followups::CreateService
  def self.call(appointment_id, followup_params, facility_id)
    date = followup_params[:followup_date]
    time = followup_params[:followup_time]
    appointment = Appointment.find_by(id: appointment_id)
    con_workflow = CounsellorWorkflow.find_by(appointment_id: appointment_id)
    followups = Order::Followup.where(appointment_id: appointment_id)
    followup = Order::Followup.new(followup_params)
    if followup.save
      appointment.update(state: 'followup')
      if followups.count > 0
        con_workflow = CounsellorWorkflow.create(con_workflow.attributes.except(:_id, :followupdates, :created_at, :updated_at))
      end
      followupdates = con_workflow.followupdates << Date.parse(date)
      if con_workflow.update(followupdates: followupdates, start_time: time, facility_id: facility_id, counsellingdate: Date.parse(date))
        con_workflow.arrived
        con_workflow.arrived_to_counselling_done
        con_workflow.followup
        followup.update(counsellor_workflow_id: con_workflow.id.to_s)
      end
    end
  end
end