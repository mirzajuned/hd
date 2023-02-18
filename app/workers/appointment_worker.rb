class AppointmentWorker
  def initialize(type, appointment_id)
    @appointment = Appointment.find_by(id: appointment_id)
    @type = type
  end

  def call
    # Workflow Jobs
    create_workflow if @type == "create_workflow"
    update_workflow if @type == "update_workflow"
    # Non Workflow jobs
    create_non_workflow if @type == "create_non_workflow"
    update_non_workflow if @type == "update_non_workflow"
  end

  private

  def create_workflow
    Appointment::WorkflowOpd.new(@appointment).create
  end

  def update_workflow
    Appointment::WorkflowOpd.new(@appointment).update
  end

  def create_non_workflow
    Appointment::NonWorkflowOpd.new(@appointment).create
  end

  def update_non_workflow
    Appointment::NonWorkflowOpd.new(@appointment).update
  end
end
