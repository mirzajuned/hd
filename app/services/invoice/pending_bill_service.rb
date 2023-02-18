#db.invoices.createIndex({ "facility_id": 1, "payment_completed": 1, "is_deleted": 1, "_type": 1, is_draft: 1});
class Invoice::PendingBillService
  class << self
    def call(params, facility, organisation, current_user)
      @facility = facility
      @organisation = organisation
      @params = params
      @is_draft = params[:is_draft] == 'true'
      @invoice_type = @params[:type].split('::')[1].downcase
      @patient_ids = patients if @params[:search_text].present?
      @number_format = CommonHelper.get_number_format(facility, organisation)
      @num_form = Common::Finance::NumberFormatService
      @current_user = current_user
      @collection = Invoice.collection.aggregate(query).to_a || []
      [data, summary]
    end

    private

    def summary
      data = Invoice.collection.aggregate(summary_query).to_a.try(:first) || { count: 0 }
      data[:total_amount_pending] = @num_form.call(@number_format, data[:total_amount_pending])
      data[:total_amount_settled] = @num_form.call(@number_format, data[:total_amount_settled])
      data[:total_bill_amount] = @num_form.call(@number_format, data[:total_bill_amount])
      data
    end

    def patients
      if @params[:search_type] == 'Name'
        field = :patient_name_search
        match_options = :word_middle
        limit = 25 
      elsif @params[:search_type] == 'Mobile No.'
        field = :mobile_number
        limit = 10
      elsif @params[:search_type] == 'MR No'
        field = :mr_no_search
        match_options = :word_middle
        limit = 10
      else
        field = :patient_identifier_id
        @params[:search_text] = @params[:search_text].delete(' ')
        limit = 10
      end
      search_options = { fields: [field], operator: 'or', limit: limit, misspellings: { below: 5 },
                         order: { _score: :desc }, where: { reg_hosp_ids: @organisation['_id'] } }
      search_options[:match]  = match_options if match_options.present?
      ids = PatientSearch.search(@params[:search_text], search_options).pluck(:patient_id)
      if @params[:type] == "Invoice::InventoryInvoice"
        ids.map { |id| id.to_s }
      else
        ids
      end
    end

    def data
      data_array = []
      @collection.each do |invoice|
        patient = invoice[:patient][0]
        patient_other_ids = invoice[:patient_other_identifier][0]
        patient_ids = invoice[:patient_identifier][0]

        patient_mrn = if patient_other_ids.present? && patient_ids.present?
                        patient_other_ids[:mr_no].present? ? "<span style='white-space: normal;'> #{patient_ids[:patient_org_id]}/ #{patient_other_ids[:mr_no]} </span>" : patient_ids[:patient_org_id]
                      else
                        ''
                end
        view_url, settle_url = if @invoice_type == "inventoryinvoice"
                     ["/invoice/inventory_invoices/print_preview?from=sale&id=#{invoice[:_id]}",
                     "/invoice/inventory_invoices/settle_invoice?"]
                   else
                    ["/invoice/#{@invoice_type}/#{invoice[:_id]}", "/invoice/invoices/settle_invoice?"]
                   end

        bill = "#{invoice[:bill_number]} <br>
          <a data-remote='true' data-toggle='modal' data-target='#invoice-modal'
          href='#{view_url}'>View Bill</a>"
        payers = if invoice[:payer_master_id].present?
                   payer_master = PayerMaster.find_by(id: invoice[:payer_master_id])
                   "<ul style='padding-inline-start: 15px;white-space: normal;'><li>#{payer_master.display_name&.camelize}<span class='small'> (#{payer_master.contact_group_name&.camelize})</span></li>
          <li>#{patient[:fullname]&.camelize}<span class='small'> (Self)</span></li></ul>"
                 else
                   "#{patient[:fullname]&.camelize}<span class='small'> (Self)</span>"
        end
        bill_amount = @num_form.call(@number_format, invoice[:net_amount])

        flexi_col = if @is_draft == true
            user = invoice[:user][0]
            "#{user[:salutation]} #{user[:fullname]}"
          else  
            settled_amount = "#{@num_form.call(@number_format, invoice[:payment_received])}<br>"
            if invoice[:payment_received].to_f > 0
              settled_amount += "<a data-remote='true' data-toggle='modal' data-target='#invoice-detail-modal'
                href='/invoice/invoices/payment_received_details?id=#{invoice[:_id]}'>Details</a>"
            end
            settled_amount
          end
        
        payment_pending = @num_form.call(@number_format, invoice[:payment_pending])
        settle_button = unless Authorization::PolicyHelper.verification(@current_user.id, "HGP-102-114-101")
                          "<a class='btn disabled' style='pointer-events: all' title='Not Authorized'>Settle</a>"
                        else
                          if @is_draft == true
                            "<a href='#'' onclick=\"alert('This is a draft bill. You can settle pending amount only once the draft bill is converted to Final Bill.'); return false;\">Settle</a>"
                          elsif invoice.try(:is_canceled)
                            '<strong>Canceled</strong>'
                          else
                            "<a data-remote='true' data-toggle='modal' data-target='#invoice-detail-modal'
                              href='#{settle_url}id=#{invoice[:_id]}&amp;revert_path=settle_invoices'>Settle</a>"
                          end
                        end
        billed_on = invoice[:created_at]&.localtime.try(:strftime, '%d-%m-%Y <br> %I:%M %p')
        data_array << [
          billed_on, patient_detail(patient), patient_mrn,
          bill, payers, bill_amount, flexi_col, "#{payment_pending} <br> #{settle_button}"

        ]
      end
      data_array
    end

    def filters
      options = { payment_completed: false, department_id: { '$ne': "50121007" },
                  is_deleted: false, _type: @params[:type],
                  is_draft: @is_draft, is_canceled: false }
      options['$or'] = [ {facility_id: @facility.id.to_s},
                           {facility_id: @facility.id} ]        
      if @params[:contact_group_id].present?
        options['$or'] = [ {contact_group_id: BSON::ObjectId(@params[:contact_group_id])},
                           {contact_group_id: @params[:contact_group_id]} ]
      end
      if @params[:payer].present?
        options['$or'] = [ {payer_master_id: BSON::ObjectId(@params[:payer])},
                           {payer_master_id: @params[:payer]} ]
      end
      options[:created_at] = since_last(@params[:since_last]) if @params[:since_last].present?
      options[:patient_id] = {'$in': @patient_ids || [] } if @params[:search_text].present?
      options
    end

    def patient_id
      @params[:type] == "Invoice::InventoryInvoice" ? 'bsonpatient_id' : 'patient_id'
    end

    def query
      query_array = [
        { '$match': filters },
        { "$addFields": { "spatient_id": { "$toString": '$patient_id' } } },
        { "$addFields": { "bsonpatient_id": { "$toObjectId": '$patient_id' } } },
        {
          '$lookup':
            {
              from: 'patients',
              localField: patient_id,
              foreignField: '_id',
              as: 'patient'
            }
        },
        {
          '$lookup':
            {
              from: 'patient_other_identifiers',
              localField: 'spatient_id',
              foreignField: 'patient_id',
              as: 'patient_other_identifier'
            }
        },
        {
          '$lookup':
            {
              from: 'patient_identifiers',
              localField: patient_id,
              foreignField: 'patient_id',
              as: 'patient_identifier'
            }
        },
        { '$sort': { "#{sort_option}": sort_order } },
        { "$skip": @params[:iDisplayStart].to_i },
        { "$limit": @params[:iDisplayLength].to_i }
      ]
      query_array << users_lookup if @is_draft == true
      query_array
    end

    def users_lookup
      {
        '$lookup': {
          from: 'users',
          localField: 'user_id',
          foreignField: '_id',
          as: 'user'
        }
      }
    end

    def summary_query
      [
        { '$match': filters },
        { '$group': {
           _id: 'null',
           total_amount_pending: { '$sum': "$payment_pending"},
           total_amount_settled: { '$sum': "$payment_received" },
           total_bill_amount: { '$sum': "$net_amount" },
           count: {'$sum': 1}
          }
        }
      ]
    end

    def patient_detail(patient)
      details = "<span style='white-space: normal;'>" + patient[:fullname]&.camelize
      details += if patient[:age].present? && patient[:gender].present?
                   " (#{patient[:age].to_s}/ #{patient[:gender].try(:first)})"
                 elsif patient[:age].present?
                   " (#{patient[:age].to_s})"
                 elsif patient[:gender].present?
                   " (#{patient[:gender].try(:first)})"
                 else
                   ''
        end
      details += "<br>#{patient[:mobilenumber]}<br>#{patient[:patient_identifier_id]}</span>"
      details.html_safe
    end

    def sort_option
      @params[:iSortCol_0].to_i == 7 ? 'payment_pending' : 'created_at'
    end

    def sort_order
      @params[:sSortDir_0] == 'desc' ? -1 : 1
    end

    def since_last(section)
      today = Date.current
      date = case section.to_i
             when 1
               { "$lte": today.end_of_day, "$gte": (today - 15.days).beginning_of_day }
             when 2
               { "$lte": (today - 15.days).end_of_day, "$gte": (today - 30.days).beginning_of_day }
             when 3
               { "$lte": (today - 30.days).end_of_day, "$gte": (today - 45.days).beginning_of_day }
             when 4
               { "$lte": (today - 45.days).end_of_day, "$gte": (today - 60.days).beginning_of_day }
             when 5
               { '$lte': (today - 60.days).beginning_of_day }
      end
      date
    end
  end
end
