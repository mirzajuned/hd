class Inventory::Transactions::DownloadInvoiceService
  class << self
    def call(params, department_id, facility, gst_inc)
      @invoice_params = params
      @department_id = department_id
      @fitter_id = params[:fitter_id]
      @state = params[:state_name]
      @gst_inc = gst_inc
      @tax_types = facility.country_id == 'IN_108' ? ['SGST', 'CGST'] : ['VAT', 'Others']
      @time_zone = facility.time_zone
      @data_array = []
      # invoice_lists = Invoice::InventoryInvoice.collection.aggregate(invoice_list_query).to_a[0] || {}
      match_options = { store_id: BSON::ObjectId(@invoice_params[:store_id]) }
      if @fitter_id.present? && @fitter_id != 'all'
        match_options = match_options.merge(fitter_id: BSON::ObjectId(@fitter_id))
      end
      match_options = match_options.merge(state: @state) if @state.present? && @state != 'all'
      match_options[:order_date] = { "$gte": @invoice_params[:start_date].beginning_of_day,
                                     "$lte": @invoice_params[:end_date].end_of_day }
      @invoice_lists = Invoice::InventoryInvoice.where(match_options)
      # @invoice_lists = invoice_lists[:invoice_lists] || []
      @total_gross = @total_discount = @total_offer = @total_taxable_amount = @total_tax_collected = @total_net_amount = 0.to_f
      @total_sgst = @total_cgst = 0.to_f
      invoice_list_data
      [@data_array, send("summary_#{@gst_inc}")]
    end

    private

    def invoice_list_data
      @invoice_lists.each do |invoice_list|
        bill_number = invoice_list[:bill_number]
        recipient = invoice_list[:recipient]&.titleize
        recipient_mobile = invoice_list[:recipient_mobile]
        mode_of_payment = invoice_list[:mode_of_payment]
        order_date_time = "#{invoice_list[:order_date]&.strftime('%d/%m/%Y')} #{invoice_list[:order_time]&.localtime&.strftime("%I:%M%p")}"
        total = invoice_list[:total].to_f
        @total_gross += total
        discount = invoice_list[:total_discount].to_f
        @total_discount += discount
        offer = invoice_list[:total_offer].to_f
        @total_offer += offer
        net_amount = invoice_list[:net_amount].to_f
        @total_net_amount += net_amount
        advance_payment = invoice_list[:advance_payment]
        amount_remaining = invoice_list[:amount_remaining]
        state = invoice_list[:state]&.titleize
        delivery_date = invoice_list[:delivery_date]&.localtime&.strftime('%d/%m/%Y') ||
                        invoice_list[:estimated_delivery_date]&.localtime&.strftime('%d/%m/%Y')
        fitting_required = invoice_list[:fitting_required] ? 'True' : 'False'
        fitter_name = invoice_list[:fitter_name]
        comments = invoice_list[:comments]
        status = if invoice_list[:is_canceled] == true
                   'CANCELLED'
                 elsif invoice_list[:payment_completed] == true
                   'BILLED'
                 else
                   'PENDING'
                 end

        taxable_amount = invoice_list[:non_taxable_amount].to_f
        @total_taxable_amount += taxable_amount
        tax_breakup = invoice_list[:tax_breakup]
        tax_collected = tax_breakup.sum { |i| i[:amount].to_f }
        @total_tax_collected += tax_collected
        # taxable_amount = non_taxable_amount.to_f #+ tax_collected.to_f
        patient_identifier = invoice_list[:patient_identifier]
        patient_mrn = invoice_list[:patient_mrn]
        if @gst_inc == '0'
          @data_array << if @department_id == '50121007'
                           [order_date_time, bill_number, recipient, recipient_mobile, patient_identifier, patient_mrn,
                            total, discount, offer, taxable_amount, tax_collected, net_amount, comments, status, state, delivery_date,
                            fitting_required, fitter_name]
                         else
                           [order_date_time, bill_number, recipient, recipient_mobile, patient_identifier, patient_mrn,
                            total, discount, offer, taxable_amount, tax_collected, net_amount, comments, status]
                         end
        else
          tax_group = tax_breakup.group_by { |tax| tax[:tax_rate] }
          tax_group.each do |tax_rate, details|
            sgst = details.sum { |i| i[:tax_type] == @tax_types[0] ? i[:amount].to_f : 0 }
            @total_sgst += sgst
            cgst = details.sum { |i| i[:tax_type] == @tax_types[1] ? i[:amount].to_f : 0 }
            new_taxable_amount = details[0][:taxable_amount].to_f.round(2)
            @total_cgst += cgst
            gst = sgst + cgst
            sgst = '' if sgst == 0
            cgst = '' if cgst == 0
            @data_array << if @department_id == '50121007'
                             [order_date_time, tax_group.count, bill_number, recipient, recipient_mobile, patient_identifier, patient_mrn,
                              total, discount, offer, net_amount, new_taxable_amount, tax_rate, sgst, tax_rate, cgst, gst, comments, status, state, delivery_date,
                              fitting_required, fitter_name]
                           else
                             [order_date_time, tax_group.count, bill_number, recipient, recipient_mobile, patient_identifier, patient_mrn,
                              total, discount, offer, net_amount, new_taxable_amount, tax_rate, sgst, tax_rate, cgst, gst, comments, status]
                           end
          end
        end
      end
    end

    def invoice_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]
      aggregation_query
    end

    def match_options
      match_options = { store_id: BSON::ObjectId(@invoice_params[:store_id]) }
      if @fitter_id.present? && @fitter_id != 'all'
        match_options = match_options.merge(fitter_id: BSON::ObjectId(@fitter_id))
      end
      match_options = match_options.merge(state: @state) if @state.present? && @state != 'all'
      match_options[:order_date] = { "$gte": @invoice_params[:start_date].beginning_of_day,
                                     "$lte": @invoice_params[:end_date].end_of_day }
      match_options
    end

    def summary_0
      ['', '', '', '', '', 'Total', @total_gross, @total_discount, @total_offer,
       @total_taxable_amount, @total_tax_collected, @total_net_amount]
    end

    def summary_1
      ['', '', '', '', '', '', 'Total', @total_gross, @total_discount, @total_offer, 
        @total_net_amount, @total_taxable_amount, '', @total_sgst, '', @total_cgst, 
        @total_sgst + @total_cgst]
    end

    def group_options
      if @department_id == '50121007'
        {
          _id: 'null',
          invoice_lists: {
            "$push": {
              bill_number: '$bill_number', recipient: '$recipient', 
              recipient_mobile: '$recipient_mobile', mode_of_payment: '$mode_of_payment', 
              checkout_date: '$checkout_date', total: '$total',
              total_discount: '$total_discount', total_offer: '$total_offer', 
              net_amount: '$net_amount', fitter_name: '$fitter_name', state: '$state',
              advance_payment: '$advance_payment', amount_remaining: '$amount_remaining', 
              is_canceled: '$is_canceled', delivery_date: '$delivery_date', 
              fitting_required: '$fitting_required',
              estimated_delivery_date: '$estimated_delivery_date', 
              payment_completed: '$payment_completed', patient_identifier: '$patient_identifier', 
              non_taxable_amount: '$non_taxable_amount', tax_breakup: '$tax_breakup', 
              patient_mrn: '$patient_mrn', order_time: '$order_date_time',
              order_date: '$order_date', comments: '$comments'
            }
          }
        }
      else
        {
          _id: 'null',
          invoice_lists: {
            "$push": {
              bill_number: '$bill_number', recipient: '$recipient', tax: '$tax',
              recipient_mobile: '$recipient_mobile', mode_of_payment: '$mode_of_payment',
              checkout_date: '$checkout_date', total: '$total', 
              total_discount: '$total_discount', total_offer: '$total_offer',
              net_amount: '$net_amount', is_canceled: '$is_canceled', 
              payment_completed: '$payment_completed',
              patient_identifier: '$patient_identifier', non_taxable_amount: '$non_taxable_amount',
              tax_breakup: '$tax_breakup', patient_mrn: '$patient_mrn', 
              order_time: '$order_date_time',
              order_date: '$order_date', comments: '$comments'
            }
          }
        }
      end
    end
  end
end
