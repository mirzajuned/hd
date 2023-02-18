class Inventory::Transactions::DownloadSaleReturnBillService
  class << self
    def call(params, department_id, user_id, facility, gst_inc)
      @user_id = user_id
      @return_params = params
      @department_id = department_id
      @gst_inc = gst_inc
      @data_array = []
      @tax_types = facility.country_id == 'IN_108' ? ['SGST', 'CGST'] : ['VAT', 'Others']
      return_lists = Inventory::Transaction::Return.collection.aggregate(return_list_query).to_a[0] || {}
      @return_lists = return_lists[:return_lists] || []
      return_list_data
      [@data_array, send("summary_#{@gst_inc}"), send("heading_#{@gst_inc}")]
    end

    private

    def return_list_data
      @gross_total_cost = 0
      @gross_return_charges = 0
      @gross_return_amount = 0
      @total_taxable = @total_tax_1 = @total_tax_2 = @total_tax = 0
      @return_lists.each do |return_list|
        sale_return = Inventory::Transaction::Return.find_by(id: return_list[:id])
        invoice = Invoice::InventoryInvoice.find_by(id: sale_return.invoice_id)
        patient = Patient.find_by(id: sale_return.patient_id)
        transaction_date = sale_return.return_time&.strftime('%d/%m/%Y  %I:%M %p')
        return_type = invoice.present? ? 'AGAINST BILL' : 'DIRECT'
        return_bill_number = sale_return.return_bill_number
        entered_by = sale_return.entered_by
        note = sale_return.note
        recipient = sale_return.recipient
        address_1 = patient.address_1
        address_2 = patient.address_2
        address = "#{address_1}, #{address_2}" if address_1.present? || address_2.present?
        pincode = patient.pincode
        state = patient.state
        city = patient.city
        district = patient.district
        commune = patient.commune
        patient_id = patient.patient_identifier_id
        patient_mrn = patient.patient_mrn
        mobile = patient.mobilenumber
        age = patient.age
        gender = patient.gender
        status = sale_return.status
        total_cost = sale_return.total_cost&.round(2)
        return_charges = sale_return.return_charges&.round(2)
        return_amount = sale_return.return_amount&.round(2)
        @gross_total_cost += total_cost || 0
        @gross_return_charges += return_charges || 0
        @gross_return_amount += return_amount || 0
        taxable_amount = sale_return.taxable_amount&.round(2)
        @total_taxable += taxable_amount
        tax_breakup = sale_return.tax_breakup
        tax_collected = tax_breakup.sum { |i| i[:amount].to_f }&.round(2) || 0
        @total_tax += tax_collected
        if @gst_inc == '0'
          @data_array << [ 
            transaction_date, invoice.try(:bill_number), return_type, return_bill_number, entered_by, note, recipient, address, pincode, state,
            city, district, commune, patient_id, patient_mrn, mobile, age, gender, status, total_cost, taxable_amount,
            tax_collected, return_charges, return_amount
          ]
        else
          tax_group = tax_breakup.group_by { |tax| tax[:tax_rate] }
          breakup_count = tax_group.count
          tax_group.each do |tax_rate, details|
            tax_1 = details.sum { |i| i[:tax_type] == @tax_types[0] ? i[:amount].to_f : 0 }&.round(2)
            tax_2 = details.sum { |i| i[:tax_type] == @tax_types[1] ? i[:amount].to_f : 0 }&.round(2)
            new_taxable_amount = details[0][:taxable_amount].to_f.round(2)
            @total_tax_1 += tax_1
            @total_tax_2 += tax_2
            @data_array << [
              transaction_date, breakup_count, invoice.try(:bill_number), return_type, return_bill_number, entered_by, note, recipient, address, pincode, state,
              city, district, commune, patient_id, patient_mrn, mobile, age, gender, status, total_cost, new_taxable_amount,
              tax_rate, tax_1, tax_rate, tax_2,  tax_collected, return_charges, return_amount
            ]
          end
        end
      end
    end

    def return_list_query
      aggregation_query = [
        { "$match": match_options },
        { "$sort": { created_at: -1 } },
        { "$group": group_options }
      ]
      aggregation_query
    end

    def match_options
      options = { store_id: BSON::ObjectId(@return_params[:store_id]) }
      options = options.merge(user_id: BSON::ObjectId(@user_id)) if @user_id != 'all_user'
      options[:created_at] = { "$gte": @return_params[:start_date].utc, "$lte": @return_params[:end_date].utc }
      options
    end

    def group_options
      {
        _id: 'null',
        return_lists: { "$push": { id: '$_id' } }
      }
    end

    def heading_1
      [
      'RETURNED ON', 'TAX BREKUPS', 'AGAINST BILL NO.', 'SALES RETURN TYPE', 'RECEIPT ID', 'TXN. USER', 'RETURN NOTE', 'PATIENT NAME',
      'ADDRESS', 'PINCODE', 'STATE', 'CITY', 'DISTRICT', 'COMMUNE', 'PATIENT ID', 'MR. No.', 'PATIENT MOBILE',
      'AGE', 'GENDER', 'STATUS', 'GROSS RETURN AMOUNT',  'TAXABLE VALUE', 'SGST RATE %', 'SGST AMOUNT',
      'CGST RATE %', 'CGST AMOUNT', 'TOTAL TAX AMOUNT', 'RETURN CHARGES', 'NET RETURN AMOUNT'
      ]
    end

    def heading_0
      [
      'RETURNED ON', 'AGAINST BILL NO.', 'SALES RETURN TYPE', 'RECEIPT ID', 'TXN. USER', 'RETURN NOTE', 'PATIENT NAME',
      'ADDRESS', 'PINCODE', 'STATE', 'CITY', 'DISTRICT', 'COMMUNE', 'PATIENT ID', 'MR. No.', 'PATIENT MOBILE',
      'AGE', 'GENDER', 'STATUS', 'GROSS RETURN AMOUNT',  'TAXABLE AMOUNT', 'TAX COLLECTED', 'RETURN CHARGES',
      'NET RETURN AMOUNT'
      ]
    end

    def summary_1
      [ 
        '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Total',
        @gross_total_cost.round(2), @total_taxable.round(2), '', @total_tax_1.round(2), '', @total_tax_2.round(2),
        @total_tax.round(2), @gross_return_charges.round(2), @gross_return_amount.round(2)
      ]
    end

    def summary_0
      [ 
        '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Total',
        @gross_total_cost.round(2), @total_taxable.round(2), @total_tax.round(2),
        @gross_return_charges.round(2), @gross_return_amount.round(2)
      ]
    end
  end
end
