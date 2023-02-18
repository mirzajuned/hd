class Orders::Investigations::UpdateService
  def self.call(order_item_advised_id, status)
    order_advised = Order::Advised.find_by(order_item_advised_id: order_item_advised_id.to_s)
    investigation = Investigation::InvestigationDetail.find_by(order_item_advised_id: order_item_advised_id.to_s)
    return unless investigation
    if status == 'Declined'
      investigation.update!(declined_by: order_advised.declined_by_id,
        payment_done: false,
        declined_by_username: order_advised.declined_by,
        declined_at: order_advised.declined_datetime,
        declined_at_facility_id: order_advised.declined_at_facility_id,
        declined_at_facility_name: order_advised.declined_at_facility,
        date_declined_at: order_advised.declined_datetime.to_date
      )
      investigation.declined
    elsif status == "Agreed"
      investigation.update!(
        payment_done: false,
        counselled_by: order_advised.counselled_by_id,
        counselled_by_username: order_advised.counselled_by,
        counselled_at: order_advised.counselled_datetime,
        counselled_at_facility_id: order_advised.counselled_at_facility_id,
        counselled_at_facility_name: order_advised.counselled_at_facility,
      )
      investigation.counselled
    elsif status == "Payment Taken"
      investigation.update!(payment_done: true,
        collected_by: order_advised.payment_taken_by_id,
        collected_by_username: order_advised.payment_taken_by,
        collected_at: order_advised.payment_taken_datetime,
        collected_at_facility_id: order_advised.payment_taken_at_facility_id,
        collected_at_facility_name: order_advised.payment_taken_at_facility
      )
      investigation.payment_taken if investigation.state != 'payment_taken'
    end
  end
end