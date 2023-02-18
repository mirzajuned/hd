class TaxCalculationWorker
  def initialize(invoice_id, type)
    @invoice = Invoice.find_by(id: invoice_id)
    @type = type
  end

  def call
    Reports::TaxCalculation.new(@invoice).tax_collected_details if @type == "tax_collected_details"
    Reports::TaxCalculation.new(@invoice).tax_recollected_details if @type == "tax_recollected_details"
  end

  private

  def update_admission_list
    Patients::UpdateDetails::AdmissionListViewService.new(@patient).call
  end

  def update_ot_list
    Patients::UpdateDetails::OtListViewService.new(@patient).call
  end

  def update_workflow_view
    Patients::UpdateDetails::OpdWorkflowViews.new(self).call
  end

  def update_non_workflow_view
    Patients::UpdateDetails::AppointmentListViewService.new(self).call
  end

  def update_counsellor_view
    Patients::UpdateDetails::CounsellorWorkflowViews.new(self).call
  end
end
