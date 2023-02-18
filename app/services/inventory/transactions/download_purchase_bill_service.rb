class Inventory::Transactions::DownloadPurchaseBillService
  class << self
    def call(params, department_id, user_id, facility, gst_inc=0)
      @user_id = user_id
      @purchase_params = params
      @department_id = department_id
      @facility = facility
      @gst_inc = gst_inc
      @data_array = []
      purchase_lists = Inventory::Transaction::Purchase.collection.aggregate(purchase_list_query).to_a[0] || {}
      @purchase_lists = purchase_lists[:purchase_lists] || []
      purchase_list_data

      [@data_array, @total_array, headings]
    end

    private

    def purchase_list_data
      @total_array = []
      @total_tax =  @total_sgst = @total_cgst = @total_taxable_amount = 0.0
      @purchase_lists.each do |purchase_list|
        purchase = Inventory::Transaction::Purchase.find_by(id: purchase_list[:id])
        vendor = Inventory::Vendor.find_by(id: purchase.vendor_id)
        transaction_date = "#{purchase.transaction_date&.strftime('%d/%m/%Y')} #{purchase.transaction_time&.strftime("%I:%M%p")}"
        purchase_bill_no = purchase.purchase_display_id
        bill_number = purchase.bill_number
        challan_number = purchase.challan_number
        entered_by = purchase.entered_by
        taxable_amount = purchase.purchase_taxable_amount || 0.0
        tax_breakup = purchase.tax_breakup
        tax_collected = tax_breakup.sum { |i| i[:amount].to_f }
        vendor_name = vendor.name
        vendor_mobile = vendor.mobile_number
        dl_number = vendor.dl_number
        vendor_gst = vendor.gst_number
        debit_amount = purchase.debit_amount
        extra_amount = purchase.extra_amount_paid
        amount_paid = purchase.amount_paid
        amount_remaining = purchase.amount_remaining
        total_cost = purchase.total_cost
        discount = purchase.discount
        net_amount = purchase.net_amount
        comments = purchase.comments
        note = purchase.note
        @total_taxable_amount += taxable_amount
        if @gst_inc == '0'
          @total_tax += tax_collected || 0
          @data_array << [
            transaction_date, purchase_bill_no, bill_number, challan_number, entered_by, comments, note, vendor_name, vendor_mobile, dl_number, vendor_gst,
            amount_remaining, total_cost, discount,  taxable_amount, tax_collected, net_amount, debit_amount,
            extra_amount, amount_paid
          ]
        else
          tax_types = @facility.country_id == 'IN_108' ? ['SGST', 'CGST'] : ['VAT', 'Others']
          tax_group = tax_breakup.group_by { |tax| tax[:tax_rate] }
          tax_group.each do |tax_rate, details|
            sgst = details.sum { |i| i[:tax_type] == tax_types[0] ? i[:amount].to_f : 0 }
            @total_sgst += sgst
            cgst = details.sum { |i| i[:tax_type] == tax_types[1] ? i[:amount].to_f : 0 }
            @total_cgst += cgst
            net_gst = cgst + sgst
            new_taxable_amount = details[0][:taxable_amount].to_f.round(2)
            @total_tax += net_gst || 0
            sgst = '' if sgst == 0
            cgst = '' if cgst == 0
            @data_array << [
              transaction_date, tax_group.count, purchase_bill_no, bill_number, challan_number, entered_by, comments, note, vendor_name, vendor_mobile, dl_number, vendor_gst,
              total_cost, discount,  new_taxable_amount, tax_rate, sgst, tax_rate, cgst, 
              net_gst, net_amount, debit_amount, extra_amount, amount_paid, amount_remaining
            ]
          end
        end
      end
      @total_array = if @gst_inc == '1'
          [@total_taxable_amount, @total_sgst, @total_cgst, @total_tax]
      end
    end

    def purchase_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]

      aggregation_query
    end

    def match_options
      options = { store_id: BSON::ObjectId(@purchase_params[:store_id]) }
      options = options.merge(user_id: BSON::ObjectId(@user_id)) if @user_id != 'all_user'
      options[:created_at] = { "$gte": @purchase_params[:start_date].utc, "$lte": @purchase_params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        purchase_lists: { "$push": { id: '$_id' } }
      }
    end

    def headings
      if @gst_inc == '0'
        ['TRANSACTION DATE', 'TRANSACTION ID', 'BILL NUMBER', 'CHALLAN NUMBER', 'TXN. USER', 'COMMENTS', 'NOTE', 'VENDOR', 'VENDOR CONTACT', 'VENDOR DL NUMBER',
        'VENDOR GST','AMOUNT PENDING', 'GROSS BILL AMOUNT', 'DISCOUNT', 'TAXABLE AMOUNT', 'TAX AMOUNT',
        'NET AMOUNT', 'DEBIT SETTLED', 'AMOUNT SETTLED', 'TOTAL AMOUNT PAID']
      else
        tax_colums = if @facility.country_id == 'IN_108' 
          ['SGST RATE', 'SGST AMOUNT', 'CGST RATE', 'CGST AMOUNT']
        else
          ['VAT RATE', 'VAT AMOUNT', 'OTHER RATE', 'OTHER AMOUNT']
        end
        ['TRANSACTION DATE', 'TAX BREKUPS', 'TRANSACTION ID', 'BILL NUMBER', 'CHALLAN NUMBER', 'TXN. USER', 'COMMENTS', 'NOTE', 'VENDOR', 'VENDOR CONTACT',
        'VENDOR DL NUMBER', 'VENDOR GST', 'GROSS BILL AMOUNT', 'DISCOUNT', 'TAXABLE VALUE', tax_colums[0], tax_colums[1],
        tax_colums[2], tax_colums[3], 'TOTAL TAX AMOUNT', 'BILL NET AMOUNT', 'DEBIT SETTLED', 'AMOUNT SETTLED',
        'TOTAL AMOUNT PAID', 'AMOUNT PENDING']
      end
    end

  end
end
