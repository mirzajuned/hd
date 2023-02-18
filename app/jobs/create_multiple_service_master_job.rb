class CreateMultipleServiceMasterJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    user = User.find_by(id: args[1])
    service_masters = args[0]
    @service_master_ids = []
    specialty_id = args[2]
    sub_specialty_id = args[3]

    service_masters.each do |service_master|
      service_id = service_master[1][:id]
      is_updated = service_master[1][:is_updated]
      next unless is_updated == 'true'

      @service_master = (ServiceMaster.find_by(id: service_id.to_s) if service_id.present?) || ServiceMaster.new

      @service_master.is_active = service_master[1][:is_active].present? ? service_master[1][:is_active] : true
      @service_master.service_type = service_master[1][:service_type]
      @service_master.service_type_code = service_master[1][:service_type_code]
      @service_master.service_type_code_name = service_master[1][:service_type_code_name]
      @service_master.service_type_code_type = service_master[1][:service_type_code_type]
      @service_master.service_group_id = service_master[1][:service_group_id]
      @service_master.service_sub_group_id = service_master[1][:service_sub_group_id]
      @service_master.service_name = service_master[1][:service_name]
      @service_master.organisation_service_code = service_master[1][:organisation_service_code]
      @service_master.service_amount = service_master[1][:service_amount]
      @service_master.specialty_id = specialty_id
      @service_master.sub_specialty_id = sub_specialty_id
      @service_master.department_ids = if service_master[1][:department_ids].is_a?(Array)
                                         service_master[1][:department_ids]
                                       elsif service_master[1][:department_ids].present?
                                         service_master[1][:department_ids].split(',')
                                       else
                                         []
                                       end
      @service_master.activity_log = {}
      @service_master.activity_log['activated'] = { user_name: user.fullname, event_time: Time.current }

      next if @service_master.service_type.nil? || @service_master.service_type_code.nil? ||
              @service_master.service_type_code_name.nil? || @service_master.service_group_id.nil? ||
              @service_master.service_sub_group_id.nil? || @service_master.service_name.nil? ||
              @service_master.department_ids.empty?

      @service_master.service_code = CommonHelper.get_service_master_code(user)
      @service_master.user_id = user.id
      @service_master.organisation_id = user.organisation_id
      @service_master.save

      PricingMasters::CreateService.call(@service_master.id.to_s, true)
    end
  end
end
