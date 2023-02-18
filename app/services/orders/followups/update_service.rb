class Orders::Followups::UpdateService
  def self.call(appointment_id, followup_params, facility_id)
    date = followup_params[:followup_date]
    time = followup_params[:followup_time]
    followup = Order::Followup.find_by(id: followup_params[:id])
    con_workflow = CounsellorWorkflow.find_by(id: followup.counsellor_workflow_id)
    followups = Order::Followup.where(appointment_id: appointment_id)
    followupdates = followups.map(&:followup_date)
    if followup.update(followup_params)
      if con_workflow.update(followupdates: followupdates, start_time: time, facility_id: facility_id, counsellingdate: Date.parse(date))
        con_workflow.arrived
        con_workflow.arrived_to_counselling_done
        con_workflow.followup
      end
    end
  end
end