class Inventory::Transactions::DownloadSaleReturnItemService
  class << self
    def call(params, user_id)
      @user_id = user_id
      @return_params = params
      @data_array = []
      return_lists = Inventory::Transaction::Return.collection.aggregate(return_list_query).to_a[0] || {}
      @return_lists = return_lists[:return_lists] || []
      return_list_data
      [@data_array, @total_array]
    end

    private

    def return_list_data
      @total_array = []
      @grand_sale_value = 0
      @grand_purchase_value = 0
      @return_lists.each do |return_list|
        sale_return = Inventory::Transaction::Return.find_by(id: return_list[:id])
        invoice = Invoice::InventoryInvoice.find_by(id: sale_return.invoice_id)
        patient = Patient.find_by(id: sale_return.patient_id)
        return_items = sale_return.items
        next if return_items.empty?

        return_items.each do |item|
          lot = Inventory::Item::Lot.find_by(id: item.lot_id)
          return_date = sale_return.return_time&.strftime('%d/%m/%Y  %I:%M %p')
          invoice_bill_no = invoice.present? ? invoice.bill_number : 'Return Against Multiple Invoice'
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
          description = item.description&.titleize
          custom_field_tags = item.custom_field_tags&.reject(&:blank?)&.join(', ')
          item_name = custom_field_tags.present? ? "#{description} (#{custom_field_tags})" : description
          item_code = item.variant_code
          category = item.category&.titleize
          batch = item.batch_no
          model_no = item.model_no
          status = sale_return.status
          qty = item.stock
          unit_cost = lot.unit_cost&.round(2)
          total_unit_cost = unit_cost * qty
          list_price = lot.list_price
          total_list_price = list_price * qty
          @grand_purchase_value += total_unit_cost
          @grand_sale_value += total_list_price
          expiry = item.expiry&.strftime('%d/%m/%Y')
          @data_array << [
            return_date, invoice_bill_no, return_bill_number, entered_by, note, recipient, address, pincode, state,
            city, district, commune, patient_id, patient_mrn, mobile, age, gender, item_name, item_code, category,
            batch, model_no, expiry, status, qty, unit_cost, total_unit_cost, list_price, total_list_price
          ]
        end
      end
      @total_array << @grand_purchase_value << @grand_sale_value
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
  end
end
