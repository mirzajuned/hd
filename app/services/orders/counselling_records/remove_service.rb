class Orders::CounsellingRecords::RemoveService
  def self.call(counselling_record, orders_data_attributes)
    orders_data_to_be_removed = counselling_record.orders_data.where.not(id: {:$in => orders_data_attributes.values.reject{|s| s[:status].blank?}.map{|a| a[:id]} })
    orders_data_to_be_removed.each do |odr|
      if odr.recounselled
        removed_params = { id: odr.id.to_s, order_advised_id: odr.order_advised_id.to_s, counselling_record_id: counselling_record.id.to_s }
        remove_recounsel_data(removed_params)
      end
    end    
  end

  private

  def self.remove_recounsel_data(params)
    order_advised = Order::Advised.find(params[:order_advised_id])
    counselling_record = Order::CounsellingRecord.find(params[:counselling_record_id])
    order_data = counselling_record.orders_data.find(params[:id])
    order_data.destroy
    prev_trail = order_advised.order_trails.where(action: { :$in => ["Agreed", "Declined", "Scheduled", "Advised"] }).order(created_at: :desc).second
    if order_advised.type == "procedures"
      order = CaseSheet.find_by(id: order_advised.case_sheet_id).procedures.find_by(order_advised_id: order_advised.id)
    else
      order = CaseSheet.find_by(id: order_advised.case_sheet_id).send(order_advised.type).find_by(order_item_advised_id: order_advised.order_item_advised_id.to_s)
    end
    if prev_trail.try(:metadata).present?
      metadata = {
        counsellor_comment: prev_trail.metadata[:counsellor_comment],
        patient_comment: prev_trail.metadata[:patient_comment]
      }
    else
      metadata = {}
    end
    if prev_trail.action == "Agreed"
      metadata = metadata.merge(agreed: true, agreed_date: prev_trail.date)
      update_attributes = {is_advised: false, counselled_datetime: prev_trail.date, status: prev_trail.action, has_agreed: true, has_declined: false, agreed_datetime: counselling_record.counselled_on}
      if order_advised.type == 'procedures'
        update_attributes[:procedurestage] = prev_trail.action
      else
        update_attributes[:investigationstage] = prev_trail.action
      end
    elsif prev_trail.action == "Declined"
      metadata = metadata.merge(declined: true, declined_date: prev_trail.date)
      update_attributes = { is_advised: false, counselled_datetime: prev_trail.date, status: prev_trail.action, has_declined: true, has_agreed: false, declined_datetime: counselling_record.counselled_on }
      if order_advised.type == 'procedures'
        update_attributes[:procedurestage] = prev_trail.action
      else
        update_attributes[:investigationstage] = prev_trail.action
      end
    elsif prev_trail.action == ""
      update_attributes = { is_advised: true, counselled_datetime: prev_trail.date, status: "Advised", has_declined: false, has_agreed: false, declined_datetime: counselling_record.counselled_on }
      if order_advised.type == 'procedures'
        update_attributes[:procedurestage] = "Advised"
      else
        update_attributes[:investigationstage] = "Advised"
      end
    end
    order_advised.update(update_attributes)
    order.update(update_attributes)
    Orders::Investigations::UpdateService.call(order_advised.order_item_advised_id.to_s, order_advised.status)
    Order::Trail.create(order_advised_id: order_advised.id, appointment_id: order_advised.appointment_id, case_sheet_id: order_advised.case_sheet_id, action: prev_trail.action, metadata: metadata, date: prev_trail.date)
  end
end