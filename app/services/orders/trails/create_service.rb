class Orders::Trails::CreateService
  class << self
    def call(action, order_advised, counsellor_comment=nil, patient_comment=nil, importing=false)
      metadata = prepare_metadata(action, order_advised)
      metadata[:patient_comment] = patient_comment if patient_comment.present?
      metadata[:counsellor_comment] = counsellor_comment if counsellor_comment.present?
      prev_trail = Order::Trail.where(order_advised_id: order_advised.id.to_s).last
      if prev_trail.blank? || (prev_trail.present? && prev_trail.action != action)
        Order::Trail.create(order_advised_id: order_advised.id, appointment_id: order_advised.appointment_id, case_sheet_id: order_advised.case_sheet_id, action: action, metadata: metadata, date: importing ? order_advised.counselled_datetime : Time.current)
      end
    end
  
    def prepare_metadata(action, order_advised)
      case action
      when 'Advised'
        advised_data(order_advised)
      when 'Agreed'
        agreed_data(order_advised)
      when 'Declined'
        declined_data(order_advised)
      when 'Scheduled'
        scheduled_data(order_advised)
      when 'Payment Taken'
        payment_taken_data(order_advised)
      end
    end
  
    def advised_data(order_advised)
      { 
        advised_by: order_advised.advised_by,
        advised_by_id: order_advised.advised_by_id,
        advised_at_facility: order_advised.advised_at_facility,
        advised_at_facility_id: order_advised.advised_at_facility_id,
        advised_datetime: order_advised.advised_datetime
      }
    end

    def payment_taken_data(order_advised)
      { 
        payment_taken_by: order_advised.payment_taken_by,
        payment_taken_by_id: order_advised.payment_taken_by_id,
        payment_taken_at_facility: order_advised.payment_taken_at_facility,
        payment_taken_at_facility_id: order_advised.payment_taken_at_facility_id,
        payment_taken_datetime: order_advised.payment_taken_datetime
      }
    end
  
    def agreed_data(order_advised)
      { 
        agreed_by: order_advised.agreed_by,
        agreed_by_id: order_advised.agreed_by_id,
        agreed_at_facility: order_advised.agreed_at_facility,
        agreed_at_facility_id: order_advised.agreed_at_facility_id,
        agreed_datetime: order_advised.agreed_datetime
      }
    end
  
    def declined_data(order_advised)
      { 
        declined_by: order_advised.declined_by,
        declined_by_id: order_advised.declined_by_id,
        declined_at_facility: order_advised.declined_at_facility,
        declined_at_facility_id: order_advised.declined_at_facility_id,
        declined_datetime: order_advised.declined_datetime
      }
    end

    def scheduled_data(order_advised)
      {
        scheduled_by: order_advised.entered_by,
        scheduled_by_id: order_advised.entered_by_id,
        scheduled_time: order_advised.entered_datetime
      }
    end
  end
end