# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Mis::RevenueReports
  class BillsModifiedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        invoices = Finance::ReportData.collection.aggregate(invoice_query).to_a[0] || {}
        @invoices = invoices[:data] || []

        total_records = if @request == 'xls'
            invoices[:total] || 0
          elsif invoices[:metadata].present?
            invoices[:metadata][0][:total]
          else
            0
          end
         
        invoice_data
        
        [@data_array, total_records]
      end
      # EOF call

      private

      def invoice_data
        @invoices.try(:each) do |invoice|
          # Table Data
          @data_array << generate_table_data(invoice)
        end
      end
      # EOF invoice_data

      def invoice_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF invoice_query

      def generate_table_data(invoice)
        invoice_patient = invoice[:patient_display_fields]
        invoice_payer = invoice[:payer_display_fields]
        invoice_user = invoice[:user_display_fields]
        invoice_data = invoice[:receipt_display_fields]
        receipt_logs = invoice[:receipt_logs]
        current_time(invoice_data['facility_timezone'])
        bill_date = convert_date(invoice_data['bill_date_time'])
        bill_no = invoice_data['bill_no']

        bill_status = pending_after_cancel = refund_amount = refund_count = bill_status = '-'
        refund_history_json = refund_display_id = reason = ''
        still_pending = (invoice_data['payment_pending'].present?) ? invoice_data['payment_pending'] : '-'

        is_cancelled = invoice_data['is_cancelled'].present?
        is_refunded = (is_cancelled == true) ? false : (invoice_data['is_refunded'].present?)
        
        if is_refunded == true || is_cancelled == true
          refund_amount = invoice_data['refund_amount']
          refund_count = invoice[:refunds_count]
          still_pending = invoice_data['still_pending']
          pending_after_cancel = invoice_data['cancelled_pending'].round(2)
          refund_histories = invoice['refund_history']
          refund_histories.each do |history|
            if @request == 'json'
              refund_history_json += "<li>#{history['refund_display_id']}: #{history['reason']}</li>"
            else
              refund_display_id += "#{history['refund_display_id']}, "
              reason += "#{history['reason']}, "
            end
          end
          refund_display_id = if refund_display_id.present?
                              refund_display_id.chomp(', ')
                            else
                              '--'
                            end
          if is_refunded == true && is_cancelled == false
            bill_status = 'Refunded'
          elsif is_cancelled == true
            bill_status = 'Cancelled'
          end
        end

        reason = if reason.present?
                  reason.chomp(', ')
                else
                  '--'
                end

        refund_history_json = unless refund_history_json.present?
                                '--'
                              end

        modified_username = '-'
        modified_date = '-'
        if invoice[:has_logs].present?
          last_modified = receipt_logs.last
          modified_date = convert_date(last_modified['created_at'])
          log_params = "type=#{invoice_data['type']}&invoice_id=#{invoice[:invoice_id]}"
          modified_username = last_modified['username'].titleize
          modified_url = "<br><a href='/invoice/invoices/invoice_log?#{log_params}' data-remote='true' data-toggle='modal' data-target='#invoice-modal'><span class='badge badge-info'>View Log</span></a>"
        end

        user_name = invoice_user['name'].titleize
        user_designation = if invoice_user['designation'].present?
                              invoice_user['designation']
                           else
                            '-'
                           end

        customer_comment = invoice_data['customer_comments'].present? ? invoice_data['customer_comments'].humanize : '-'
        internal_comment = invoice_data['internal_comments'].present? ? invoice_data['internal_comments'].humanize : '-'
        
        patient_name = invoice_patient['patient_name'].titleize
        area = invoice_patient['area_manager_name'].present? ? invoice_patient['area_manager_name'] : '-'
        commune = (invoice_patient['commune'].present?) ? invoice_patient['commune'] : ''
        city = (invoice_patient['city']. present?) ? invoice_patient['city'] : ''
        district = (invoice_patient['district'].present?) ? invoice_patient['district'] : ''
        state = (invoice_patient['state'].present?) ? invoice_patient['state'] : ''
        pincode = if invoice_patient['pincode'].present? && invoice_patient['pincode'] != 0
                    invoice_patient['pincode'].to_s 
                  else
                    ''
                  end
        location = display_location(city, state, commune, district, pincode)
        patient_age = if invoice_patient['age'].present?
                        invoice_patient['age']
                      else
                        '-'
                      end
        patient_gender = if invoice_patient['gender'].present?
                          invoice_patient['gender']
                        else
                          '-'
                        end
        patient_identifier_id = if invoice_patient['patient_identifier_id'].present?
                                  invoice_patient['patient_identifier_id']
                                else
                                  '-'
                                end
        patient_mrn = if invoice_patient['patient_mrn'].present?
                        invoice_patient['patient_mrn']
                      else
                        '-'
                      end

        i_type = invoice_data['bill_type'].titleize

        payer_details = if invoice_payer.present?
                          invoice_payer['payer_name'].titleize 
                        else
                          '-'
                        end

        amount_adjusted = if invoice_data['amount_adjusted'].present?
                  invoice_data['amount_adjusted']
                else
                  '-'
                end
        payment_received = tax_deducted = payer_difference = spillage = total_settled = 0
        if invoice['payment_received_breakups'].present?
          payment_received = invoice['payment_received_breakups'].pluck(:amount_received).reject{|i| i.nil?}.inject(0, :+)
          tax_deducted = invoice['payment_received_breakups'].pluck(:tax_deducted).reject{|i| i.nil?}.inject(0, :+)
          payer_difference = invoice['payment_received_breakups'].pluck(:payer_difference).reject{|i| i.nil?}.inject(0, :+)
          spillage = invoice['payment_received_breakups'].pluck(:other_revenue_spilage).reject{|i| i.nil?}.inject(0, :+)
          total_settled = invoice['payment_received_breakups'].pluck(:amount).reject{|i| i.nil?}.inject(0, :+)
        end

        item_offer = invoice_data['offer_on_services'] || 0.00
        additional_offer = invoice_data['offer_on_bill'] || 0.00
        total_offer = invoice_data['total_offer'] || 0.00
        item_discount = invoice_data['services_discount'] || 0.00
        additional_discount = invoice_data['additional_discount'] || 0.00
        total_discount = invoice_data['total_discount'] || 0.00
        if @request == 'json'
          item_offer = "<font class='discount'>#{item_offer}</font>" if item_offer > 0
          additional_offer = "<font class='discount'>#{additional_offer}</font>" if additional_offer > 0
          total_offer = "<font class='discount'>#{total_offer}</font>" if total_offer > 0

          item_discount = "<font class='discount'>#{item_discount}</font>" if item_discount > 0
          additional_discount = "<font class='discount'>#{additional_discount}</font>" if additional_discount > 0
          total_discount = "<font class='discount'>#{total_discount}</font>" if total_discount > 0
          if invoice_data['type'].in?(['ipd', 'opd'])
            bill_no = "<a href='/invoice/#{invoice_data['type']}/#{invoice[:invoice_id]}?reports=true' "\
            "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{invoice_data['bill_no']}</a>"
          else
            bill_no = "<a href='/invoice/inventory_invoices/show_modal?id=#{invoice[:invoice_id]}&reports=true' "\
            "data-remote='true' data-toggle='modal' data-target='#invoice-modal'>#{invoice_data['bill_no']}</a>"
          end
          bill_details = "<b>#{bill_no}</b><br>#{bill_date}"
          i_type = "<span class='badge #{invoice_data['bill_type']}'>#{i_type}</span>"
          patient_details = "<b>#{patient_name}</b><br>#{patient_age}<br>#{patient_gender}<br>#{patient_identifier_id}<br>#{patient_mrn}"
          user_details = "<b><font class='text-green'>#{user_name}</font></b><br>#{user_designation}<br>#{bill_date}"
          invoice_modified = "<font class='discount'><b>#{modified_username}</b></font><br>#{modified_date}"
          invoice_modified += modified_url if modified_url.present?
          customer_comment = "<font class='purple'>#{customer_comment}</font>"
          internal_comment = "<font class='text-primary'>#{internal_comment}</font>"
          t_data = [invoice_modified, user_details, customer_comment, internal_comment, 
                    invoice_data['department_name'], bill_details, patient_details, area, 
                    location, i_type, payer_details, invoice_data['total'], item_offer, 
                    additional_offer, total_offer, item_discount, additional_discount, 
                    total_discount, invoice_data['tax'], invoice_data['gross_amount'], 
                    still_pending.round(2), pending_after_cancel, amount_adjusted, 
                    invoice_data['advance_payment'], payment_received, tax_deducted, spillage,
                    payer_difference, total_settled, invoice_data['no_of_servies'], 
                    invoice_data['no_of_receipts'], bill_status, refund_history_json]
        else
          t_data = [modified_username, modified_date, user_name, user_designation, customer_comment,
                    internal_comment, invoice_data['department_name'], bill_no, bill_date, 
                    patient_name, patient_age, patient_gender, patient_identifier_id, patient_mrn,
                    area, city, state, district, commune, pincode, i_type, 
                    payer_details, invoice_data['total'], item_offer, additional_offer, 
                    total_offer, item_discount, additional_discount, 
                    total_discount, invoice_data['tax'], invoice_data['gross_amount'], 
                    still_pending.round(2), pending_after_cancel, amount_adjusted, 
                    invoice_data['advance_payment'], payment_received, tax_deducted, spillage, 
                    payer_difference, total_settled, invoice_data['no_of_servies'], 
                    invoice_data['no_of_receipts'], bill_status, reason]
        end

        table_date = t_data.flatten

        table_date
      end
      # EOF generate_table_data

      def current_time(facility_id_timezone, is_id=false)
        if is_id.present?
          facility_timezone = Facility.find_by(id: facility_id_timezone).try(:time_zone)
        else
          facility_timezone = facility_id_timezone
        end
        Time.zone = facility_timezone
      end
      # EOF current_time

      def convert_date(dateTime)
        Time.zone.parse(dateTime.to_s).to_s(:hg_history_date_time)
      end
      # EOF convert_date

      def display_location(city, state, commune, district, pincode)
        location = ''
        location += city.titleize if city.present?
        location += "<br>" + state.titleize if state.present?
        location += "<br>" + commune.titleize if commune.present?
        location += "<br>" + district.titleize if district.present?
        location += "<br>" + pincode if pincode.present?
        location.present? ? location.sub('<br>','') : '-'
      end
      # EOF display_location
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
