class Orders::Advised::UpdateService
  def self.call(counselling_record_id, case_sheet_id, current_facility)
    counselling_record = Order::CounsellingRecord.find(counselling_record_id)
    case_sheet = CaseSheet.find_by(id: case_sheet_id)
    counselling_record.orders_data.each do |od|
      begin
      order_advised = Order::Advised.find_by(id: od.order_advised_id)
      if order_advised.type == 'procedures'
        order = case_sheet.procedures.find_by(order_advised_id: order_advised.id.to_s)
        order_advised.procedurestage = od.status.blank? ? "Advised" : od.status
        order.procedurestage = od.status.blank? ? "Advised" : od.status
      else
        order = case_sheet.send(order_advised.type).find_by(order_advised_id: order_advised.id.to_s)
        order = case_sheet.send(order_advised.type).find_by(order_item_advised_id: order_advised.order_item_advised_id.to_s) if order.blank?
        order = case_sheet.send(order_advised.type).find_by(order_display_id: order_advised.display_id.to_s) if order.blank?

        order_advised.investigationstage = od.status.blank? ? "Advised" : od.status
        order.investigationstage = od.status.blank? ? "Advised" : (od.status == "Agreed" ? "Counselled" : od.status)
      end
      order.order_status = od.status.blank? ? "open" : "processing"

      if od.status == "Agreed"
        order_advised.assign_attributes(status: od.status, payment_taken: false, is_advised: false, has_agreed: true, has_declined: false, agreed_at_facility: current_facility.name, agreed_at_facility_id: current_facility.id.to_s, agreed_by: counselling_record.counselled_by, agreed_by_id: counselling_record.counselled_by_id, agreed_datetime: counselling_record.counselled_on)
        order.assign_attributes(counsellor_options_disabled: false, payment_taken: false, status: od.status, has_agreed: true, has_declined: false, agreed_at_facility: current_facility.name,agreed_at_facility_id: current_facility.id.to_s, agreed_by: counselling_record.counselled_by, agreed_by_id: counselling_record.counselled_by_id,agreed_datetime: counselling_record.counselled_on)
      elsif od.status == "Declined"
        order_advised.assign_attributes(status: od.status, is_advised: false, payment_taken: false, has_declined: true, has_agreed: false, declined_at_facility: current_facility.name, declined_at_facility_id: current_facility.id.to_s, declined_by: counselling_record.counselled_by, declined_by_id: counselling_record.counselled_by_id, declined_datetime: counselling_record.counselled_on)
        order.assign_attributes(counsellor_options_disabled: false, status: od.status, payment_taken: false, has_agreed: false, has_declined: true, declined_at_facility: current_facility.name, declined_at_facility_id: current_facility.id.to_s, declined_by: counselling_record.counselled_by, declined_by_id: counselling_record.counselled_by_id, declined_datetime: counselling_record.counselled_on)
      elsif od.status == "Payment Taken"
        order_advised.assign_attributes(status: od.status, payment_taken: true, payment_taken_by: counselling_record.counselled_by, payment_taken_by_id: counselling_record.counselled_by_id, payment_taken_datetime: counselling_record.counselled_on, payment_taken_from: 'add_investigation_details', payment_taken_at_facility: current_facility.name, payment_taken_at_facility_id: current_facility.id.to_s)
        order.assign_attributes(counsellor_options_disabled: false, payment_taken: true, status: od.status, has_agreed: true, has_declined: false, is_advised: false, investigationstage: 'Payment Taken', status: od.status, payment_taken: true, payment_taken_by: counselling_record.counselled_by, payment_taken_by_id: counselling_record.counselled_by_id, payment_taken_datetime: counselling_record.counselled_on, payment_taken_from: 'add_investigation_details', payment_taken_at_facility: current_facility.name, payment_taken_at_facility_id: current_facility.id.to_s, agreed_at_facility: current_facility.name,agreed_at_facility_id: current_facility.id.to_s, agreed_by: counselling_record.counselled_by, agreed_by_id: counselling_record.counselled_by_id,agreed_datetime: counselling_record.counselled_on)
      elsif od.status == ""
        order_advised.assign_attributes(is_advised: true, status: "Advised", has_declined: false, has_agreed: false, payment_taken: false)
        order.assign_attributes(is_advised: true, status: "Advised", has_agreed: false, has_declined: false, payment_taken: false)
        od.destroy
      end

      if od.status.blank?
        update_attributes = {is_counselled: false, counselling: false, counselled_at_facility: "", counselled_at_facility_id: nil, counselled_by: "", counselled_by_id: nil, counselled_datetime: nil}
      else
        update_attributes = {is_counselled: true, counselling: true, counselled_at_facility: current_facility.name, counselled_at_facility_id: current_facility.id.to_s, counselled_by: counselling_record.counselled_by, counselled_by_id: counselling_record.counselled_by_id, counselled_datetime: counselling_record.counselled_on}
      end
      order.assign_attributes(update_attributes)
      order.save
      order_advised.assign_attributes(update_attributes)
      order_advised.save
      if order_advised.type != 'procedures'
        Orders::Investigations::UpdateService.call(order_advised.order_item_advised_id.to_s, order_advised.status)
      end
      Orders::Trails::CreateService.call(od.status.blank? ? 'Advised' : od.status, order_advised, od.counsellor_comment, od.patient_comment)
      rescue
      end
    end
  end
end