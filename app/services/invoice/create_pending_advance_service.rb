class Invoice::CreatePendingAdvanceService
  class << self
    def call(order, type)
      adv_params = order.pending_advance_payments_attributes
                    .merge(order_id: order.id.to_s, patient_id: order.patient_id.to_s, invoice_type: 'Adjusted',
                      department_id: order.department_id, department_name: order.department_name,
                      bkp_advance_display_id: CommonHelper.get_advance_identifier(order.user) )

      if adv_params[:amount].to_f > 0
        @advance_payment = AdvancePayment.new(adv_params)
        if @advance_payment.save
          advance_display_id = SequenceManagers::GenerateSequenceService.call(
            'advance_payment', @advance_payment.id.to_s, { organisation_id: @advance_payment.organisation_id.to_s, facility_id:  @advance_payment.facility_id.to_s, department_id: @advance_payment.department_id, region_id: @advance_payment.facility.try(:region_master_id).to_s}
          )
          @advance_payment.update(advance_display_id: advance_display_id)
          adv_params.merge!(advance_display_id: advance_display_id)
          if @advance_payment.store_id.present? && @advance_payment.order_id.present?
            Inventory::Transactions::CreateAdvancePaymentService.call(order.id.to_s, @advance_payment.id, 
                                                                    adv_params[:user_full_name], @advance_payment.amount,
                                                                    'advance_against_order', type)
          end
          InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
          InvoiceJobs::ManageCollectionDataJob.perform_later(@advance_payment.id.to_s, 'Advance')
          Patients::Summary::TimelineWorker.call(event_name: "#{@advance_payment.type.upcase}_ADVANCE", sub_event_name: 'CREATED', advance_payment_id: @advance_payment.id, user_id: order.user_id, user_name: order.user.fullname, encounter_type: @advance_payment.type, is_draft: false)
      end
    end
    end
  end
end
