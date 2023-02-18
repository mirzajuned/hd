class Orders::Advised::CreateService
  def self.call(order_attributes, case_sheet_id, appointment_id, current_user_id, current_facility_id)
    current_user = User.find_by(id: current_user_id)
    current_facility = Facility.find_by(id: current_facility_id)
    case_sheet = CaseSheet.find_by(id: case_sheet_id)
    order_attributes.each do |key, value|
      order_advised = Order::Advised.new(value.permit!.except(:ipd_procedure_ids, :counsellor_procedure_ids, :counsellor_investigation_ids, :ipd_investigation_ids))

      if value[:type] == "procedures"
        order_display_id = CommonHelper.get_procedure_order_identifier(current_user.organisation_id)
      else
        order_display_id = CommonHelper.get_investigation_order_identifier(current_user.organisation_id)
        order_advised[:active] = true
      end

      order_advised.assign_attributes(display_id: order_display_id, organisation_id: current_facility.try(:organisation_id),
                                      facility_id: current_facility.try(:id), patient_id: case_sheet.try(:patient_id),
                                      case_sheet_id: case_sheet_id, appointment_id: appointment_id, type: value[:type])
      # unless value[:type] == "procedures"
      #   order_advised[:active] = true
      # end
      order_advised.save
      Orders::Trails::CreateService.call('Advised', order_advised)
      if value[:type] == 'procedures'
        order = case_sheet.send(value[:type]).create(order_advised.attributes.except("_id"))
        order.update(order_advised_id: order_advised.id.to_s)
      else
        Orders::Investigations::CreateService.call(order_advised.order_item_advised_id.to_s, current_user, current_facility)
      end
    end
  end

  # def self.create_orders_from_case_sheet(case_sheet_id, current_user_id)
  #   @current_user = User.find_by(id: current_user_id)
  #   @case_sheet = CaseSheet.find_by(id: case_sheet_id)
  #   @active_order = @case_sheet.organisation.organisations_setting.active_advise_order_rule
  #   @case_sheet.procedures.each do |procedure|
  #     create_orders_from_procedure(procedure, @case_sheet.id.to_s)
  #   end
  #   update_active_order(@active_order, @case_sheet.id.to_s)
  #   @case_sheet.ophthal_investigations.each do |investigation|
  #     create_orders_from_ophthal_investigation(investigation, @case_sheet.id.to_s)
  #   end
  #   @case_sheet.radiology_investigations.each do |investigation|
  #     create_orders_from_radiology_investigation(investigation, @case_sheet.id.to_s)
  #   end
  #   @case_sheet.laboratory_investigations.each do |investigation|
  #     create_orders_from_laboratory_investigation(investigation, @case_sheet.id.to_s)
  #   end
  #
  #   cancel_removed_orders
  # end
  def self.create_orders_from_case_sheet(case_sheet_id, current_user_id, current_facility_id)
    @current_user = User.find_by(id: current_user_id)
    @current_facility = Facility.find_by(id: current_facility_id)
    @case_sheet = CaseSheet.find_by(id: case_sheet_id)
    @active_order = @case_sheet.organisation.organisations_setting.active_advise_order_rule
    @case_sheet.procedures.each do |procedure|
      if procedure.procedurestage == "Advised" || procedure.procedurestage == "Agreed" || procedure.procedurestage == "Counselled" || procedure.procedurestage == "Payment Taken"
        create_orders_from_procedure(procedure, @case_sheet, @current_facility)
      end
    end
    update_active_order(@active_order, @case_sheet.id.to_s)
    @case_sheet.ophthal_investigations.each do |investigation|
      if investigation.investigationstage == "Advised" || investigation.investigationstage == "Agreed" || investigation.investigationstage == "Counselled" || investigation.investigationstage == "Payment Taken"
        create_orders_from_ophthal_investigation(investigation, @case_sheet, @current_facility)
      end
    end
    @case_sheet.radiology_investigations.each do |investigation|
      if investigation.investigationstage == "Advised" || investigation.investigationstage == "Agreed" || investigation.investigationstage == "Counselled" || investigation.investigationstage == "Payment Taken"
        create_orders_from_radiology_investigation(investigation, @case_sheet, @current_facility)
      end
    end
    @case_sheet.laboratory_investigations.each do |investigation|
      if investigation.investigationstage == "Advised" || investigation.investigationstage == "Agreed" || investigation.investigationstage == "Counselled" || investigation.investigationstage == "Payment Taken"
        create_orders_from_laboratory_investigation(investigation, @case_sheet, @current_facility)
      end
    end

    # cancel_removed_orders
  end
  #
  def self.cancel_removed_orders
    Order::Advised.where(type: "procedures", case_sheet_id: @case_sheet.id.to_s).where.not(id: { :$in => @case_sheet.procedures.map(&:order_advised_id)}).update_all(status: "Cancelled")
    Order::Advised.where(type: "ophthal_investigations", case_sheet_id: @case_sheet.id.to_s).where.not(order_item_advised_id: { :$in => @case_sheet.ophthal_investigations.map(&:order_item_advised_id).map(&:to_s)}).update_all(status: "Cancelled")
    Order::Advised.where(type: "radiology_investigations", case_sheet_id: @case_sheet.id.to_s).where.not(order_item_advised_id: { :$in => @case_sheet.radiology_investigations.map(&:order_item_advised_id).map(&:to_s)}).update_all(status: "Cancelled")
    Order::Advised.where(type: "laboratory_investigations", case_sheet_id: @case_sheet.id.to_s).where.not(order_item_advised_id: { :$in => @case_sheet.laboratory_investigations.map(&:order_item_advised_id).map(&:to_s)}).update_all(status: "Cancelled")
  end

  def self.create_orders_from_procedure(procedure, case_sheet, current_facility)
    procedure_attributes = procedure.attributes.except(:_id, "_id")
    order_advised = Order::Advised.find_by(order_item_advised_id: procedure.order_item_advised_id.to_s, procedureside: procedure.procedureside)
    if order_advised
      order_advised.assign_attributes(procedure_attributes)
    else
      order_advised = Order::Advised.new(procedure_attributes)
      # order_advised.assign_attributes(display_id: CommonHelper.get_order_identifier, case_sheet_id: case_sheet_id, status: procedure.procedurestage)

      order_advised.assign_attributes(display_id: CommonHelper.get_procedure_order_identifier(current_facility.try(:organisation_id)),
                                             organisation_id: current_facility.try(:organisation_id), facility_id: current_facility.try(:id),
                                             patient_id: case_sheet.try(:patient_id), case_sheet_id: case_sheet.id,
                                             status: procedure.procedurestage, active: true)

    end
    order_advised.quantity = 1
    order_advised.type = 'procedures'
    order_advised.save
    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    elsif order_advised.status == "Counselled"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Counselled', order_advised)
    elsif order_advised.status == "Payment Taken"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Payment Taken', order_advised)
    elsif order_advised.status == "Agreed"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Agreed', order_advised)
    end
    procedure.update(order_advised_id: order_advised.id.to_s, order_display_id: order_advised.display_id)
  end

  def self.update_active_order(active_order, case_sheet_id)
    Order::Advised.where(type: "procedures", case_sheet_id: case_sheet_id, status: { :$in => ['Performed', 'Advised', 'Declined', 'Agreed', 'Scheduled']}).group_by{|p| [p.procedure_id, p.procedureside]}.each do |p|
      if active_order == 'FIFO'
        procedures_to_update = p.last.sort_by(&:created_at)
      else
        procedures_to_update = p.last.sort_by(&:created_at).reverse
      end
      procedures_to_update.each{|a| a.update(active: false)}
      unless Order::Advised.find_by(case_sheet_id: case_sheet_id, status: "Performed", procedure_id: procedures_to_update.first.procedure_id, procedureside: procedures_to_update.first.procedureside)
        procedures_to_update.first.update(active: true)
      end
    end
  end
  #
  def self.create_orders_from_ophthal_investigation(investigation, case_sheet, current_facility)
    investigation_attributes = investigation.attributes.except(:_id, "_id")
    if investigation.investigationstage == "Counselled" && investigation.status == "Agreed"
      investigation_attributes.merge(
        {
          agreed_by: investigation.counselled_by,
          agreed_by_id: investigation.counselled_by_id,
          agreed_datetime: investigation.counselled_datetime,
          agreed_at_facility: investigation.counselled_at_facility,
          agreed_at_facility_id: investigation.counselled_at_facility_id,
          has_agreed: true
        }
      )
    end
    order_advised = Order::Advised.find_by(order_item_advised_id: investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.assign_attributes(investigation_attributes)
    else
      order_advised = Order::Advised.new(investigation_attributes)
      order_advised.assign_attributes(display_id: CommonHelper.get_investigation_order_identifier(current_facility.organisation_id),
                                      organisation_id: current_facility.try(:organisation_id), facility_id: current_facility.try(:id),
                                      patient_id: case_sheet.try(:patient_id), case_sheet_id: case_sheet.try(:id),
                                      type: 'ophthal_investigations',
                                      status: investigation.investigationstage
      )

    end
    if investigation.investigationside == "40638003"
      order_advised.quantity = 2
    else
      order_advised.quantity = 1
    end
    order_advised.active = true
    order_advised.save

    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    elsif order_advised.status == "Counselled"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Counselled', order_advised)
    elsif order_advised.status == "Payment Taken"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Payment Taken', order_advised)
    elsif order_advised.status == "Agreed"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Agreed', order_advised)
    end
    investigation.update(order_advised_id: order_advised.id.to_s, order_display_id: order_advised.display_id)
  end

  def self.create_orders_from_radiology_investigation(investigation, case_sheet, current_facility)
    investigation_attributes = investigation.attributes.except(:_id, "_id")
    if investigation.investigationstage == "Counselled" && investigation.status == "Agreed"
      investigation_attributes.merge(
        {
          agreed_by: investigation.counselled_by,
          agreed_by_id: investigation.counselled_by_id,
          agreed_datetime: investigation.counselled_datetime,
          agreed_at_facility: investigation.counselled_at_facility,
          agreed_at_facility_id: investigation.counselled_at_facility_id,
          has_agreed: true
        }
      )
    end
    order_advised = Order::Advised.find_by(order_item_advised_id: investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.assign_attributes(investigation_attributes)
    else
      order_advised = Order::Advised.new(investigation_attributes)
      order_advised.assign_attributes(display_id: CommonHelper.get_investigation_order_identifier(current_facility.organisation_id),
                                      organisation_id: current_facility.try(:organisation_id), facility_id: current_facility.try(:id),
                                      patient_id: case_sheet.try(:patient_id), case_sheet_id: case_sheet.try(:id),
                                      type: 'radiology_investigations',
                                      status: investigation.investigationstage
      )
    end
    order_advised.quantity = 1
    order_advised.active = true
    order_advised.save
    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    elsif order_advised.status == "Counselled"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Counselled', order_advised)
    elsif order_advised.status == "Payment Taken"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Payment Taken', order_advised)
    elsif order_advised.status == "Agreed"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Agreed', order_advised)
    end
    investigation.update(order_advised_id: order_advised.id.to_s, order_display_id: order_advised.display_id)
  end

  def self.create_orders_from_laboratory_investigation(investigation, case_sheet, current_facility)
    investigation_attributes = investigation.attributes.except(:_id, "_id")
    if investigation.investigationstage == "Counselled" && investigation.status == "Agreed"
      investigation_attributes.merge(
        {
          agreed_by: investigation.counselled_by,
          agreed_by_id: investigation.counselled_by_id,
          agreed_datetime: investigation.counselled_datetime,
          agreed_at_facility: investigation.counselled_at_facility,
          agreed_at_facility_id: investigation.counselled_at_facility_id,
          has_agreed: true
        }
      )
    end
    order_advised = Order::Advised.find_by(order_item_advised_id: investigation.order_item_advised_id.to_s)
    if order_advised
      order_advised.assign_attributes(investigation_attributes)
    else
      order_advised = Order::Advised.new(investigation_attributes)
      order_advised.assign_attributes(display_id: CommonHelper.get_investigation_order_identifier(current_facility.organisation_id),
                                      organisation_id: current_facility.try(:organisation_id), facility_id: current_facility.try(:id),
                                      patient_id: case_sheet.try(:patient_id), case_sheet_id: case_sheet.try(:id),
                                      type: 'laboratory_investigations',
                                      status: investigation.investigationstage
      )
    end
    order_advised.quantity = 1
    order_advised.active = true
    order_advised.save
    if order_advised.status == "Advised"
      Orders::Trails::CreateService.call('Advised', order_advised)
    elsif order_advised.status == "Counselled"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Counselled', order_advised)
    elsif order_advised.status == "Payment Taken"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Payment Taken', order_advised)
    elsif order_advised.status == "Agreed"
      Orders::Trails::CreateService.call('Advised', order_advised)
      Orders::Trails::CreateService.call('Agreed', order_advised)
    end
    investigation.update(order_advised_id: order_advised.id.to_s, order_display_id: order_advised.display_id)
  end
end