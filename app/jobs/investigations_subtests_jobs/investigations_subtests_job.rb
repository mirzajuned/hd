class InvestigationsSubtestsJob < ActiveJob::Base
  queue_as :urgent

  def perform(params)
    @organisation_id = params[:organisation_id]
    @facilities = Facility.where(organisation_id: @organisation_id)

    @facilities.each do |fac|
      @custom_lab_inv = CustomLaboratoryInvestigation.new(custom_lab_params(params))
      @custom_lab_inv.panel_data = @panel_data
      @custom_lab_inv.facility_id = fac.id
      @custom_lab_inv.save
    end
  end

  private

  def custom_lab_params(params)
    params.permit(:investigation_name, :loinc_code, :organisation_id, :facility_id, :created_by, :normal_range, :loinc_class, :short_name, :test_type, :specialty_id, :investigation_id, :department_id, :add_subtests)
  end
end
