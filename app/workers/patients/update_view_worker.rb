class UpdateViewWorker
  def initialize(type, patient_id)
    @type = type
    @patient = Patient.find_by(id: patient_id)
  end

  def call
    update_ot_list if @type == "ot_list"
    update_admission_list if @type == "admission_list"
    update_workflow_view if @type == "workflow_list"
    update_non_workflow_view if @type == "non_workflow_list"
    update_counsellor_view if @type == "counsellor_list"
  end

  private

  def update_admission_list
    Patients::UpdateDetails::AdmissionListViewService.new(@patient).call
  end

  def update_ot_list
    Patients::UpdateDetails::OtListViewService.new(@patient).call
  end

  def update_workflow_view
    Patients::UpdateDetails::OpdWorkflowViews.new(@patient).call
  end

  def update_non_workflow_view
    Patients::UpdateDetails::AppointmentListViewService.new(@patient).call
  end

  def update_counsellor_view
    Patients::UpdateDetails::CounsellorWorkflowViews.new(@patient).call
  end
end
