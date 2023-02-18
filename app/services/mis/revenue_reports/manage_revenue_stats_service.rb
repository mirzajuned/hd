module Mis::RevenueReports
  class ManageRevenueStatsService
    class << self
      def call(filtered_invoices, organisation_ids, create_update_date, mis_logger=nil)
        @mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_revenue_stats_logger.log")
        group_by_organisations = filtered_invoices.group_by { |al| al[:organisation_id] }
        group_by_organisations.each do |organisation_id, group_by_organisation|
          @organisation_id = organisation_id
          group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
          group_by_facilities.each do |facility_id, group_by_facility|
            @facility_id = facility_id
            @filter_fields_hash = { organisation_id: @organisation_id, facility_id: @facility_id }
            facility = Facility.find_by(id: @facility_id)
            @facility_name = facility.try(:name)
            @facility_timezone = facility.try(:time_zone)
            invoices = group_by_facility.select do |invoice|
              invoice[:receipt_created_at].to_date == create_update_date &&
              invoice[:receipt_display_fields]['state'].in?([nil, 'delivered', 'None', 'Settled', 'Received'])
            end
            if invoices && invoices.count > 0
              date_wise_invoices = invoices.group_by { |i| i[:receipt_created_at].to_date }
              stats_by_date(date_wise_invoices)
            end
            collection_invoices = group_by_facility
            # normal bills payment
            dates = collection_invoices.map do |invoice|
              invoice[:is_advance] == false &&
              invoice[:payment_received_breakups].present? && invoice[:payment_received_breakups].pluck(:time)
            end.flatten.reject{|date| (date.class != Time)}.map{|dt| dt.to_date} || []
            # normal bills payment
            dates << collection_invoices.select do |invoice| 
              invoice[:is_advance] == true &&
              invoice[:receipt_display_fields]['payment_time'].present?
            end.map{|i| i[:receipt_display_fields]['payment_time'].to_date}.flatten
            .reject{|date| (date.class != Date)} || []
            final_dates = dates.flatten.uniq.sort
            final_dates.each do |bill_date|
              date_wise_collection = collection_invoices.select do |invoice|
                bill_date.to_date.in?([invoice[:receipt_created_at].to_date, invoice[:receipt_updated_at].to_date])
              end
              collection_stats_data(date_wise_collection, bill_date)
            end
          end
        end
      end

      def stats_by_date(invoices)
        invoices.each do |receipt_date, date_wise_invoices|
          @filter_fields_hash[:receipt_date] = receipt_date
          # revenue statistics by department
          department_wise_invoices = date_wise_invoices.group_by do |date_wise_invoice|
            date_wise_invoice[:receipt_display_fields]['department_id']
          end
          dept_wise_stats(department_wise_invoices, receipt_date)
          # EOF revenue statistics by department
          # revenue statistics by payer
          payer_wise_invoices = date_wise_invoices.select do |inv|
            inv[:is_advance] == false &&
            inv[:has_refund] == false
          end.group_by do |date_wise_invoice|
            date_wise_invoice[:payer_display_fields].present? &&
            date_wise_invoice[:payer_display_fields]['payer_id']
          end
          payer_wise_stats(payer_wise_invoices, receipt_date)
          # EOF revenue statistics by payer
        end
      end
      # EOF stats_by_date

      def collection_stats_data(invoices, bill_date)
        @filter_fields_hash[:date] = bill_date
        department_wise_invoices = invoices.group_by do |date_wise_invoice|
          date_wise_invoice[:receipt_display_fields]['department_id']
        end
        department_wise_invoices.each do |department_id, d_invoices|
          if department_id.present?
            department = Department.find_by(id: department_id)
            department_name = department.try(:display_name)
            department_order = department.try(:order)
            collection_data(d_invoices, bill_date, department_id, department_name, department_order)
          end
        end
      end
      # EOF stats_by_date

      def dept_wise_stats(dept_wise_invoices, receipt_date)
        dept_wise_invoices.each do |department_id, d_invoices|
          if department_id.present?
            department = Department.find_by(id: department_id)
            department_name = department.try(:display_name)
            department_order = department.try(:order)
            revenue_data(d_invoices, receipt_date, department_id)
            search_fields_hash = { department_name: department_name }
            filter_fields_hash = @filter_fields_hash.merge(department_id: department_id)
            f_mis_revenue_stat = Finance::StatisticData.find_or_create_by(
              receipt_date: receipt_date, facility_id: @facility_id, department_id: department_id
            )
            f_mis_revenue_stat.has_revenue_data = @total_bill_count > 0 || @total_bill_amount > 0 || @total_bill_discount > 0 || @total_bill_offer > 0 ? true : false
            f_mis_revenue_stat.organisation_id = @organisation_id
            f_mis_revenue_stat.department_name = department_name
            f_mis_revenue_stat.department_order = department_order
            f_mis_revenue_stat.facility_name = @facility_name
            f_mis_revenue_stat.total_bill_count = @total_bill_count
            f_mis_revenue_stat.total_bill_amount = @total_bill_amount
            f_mis_revenue_stat.total_bill_discount = @total_bill_discount
            f_mis_revenue_stat.total_bill_offer = @total_bill_offer

            f_mis_revenue_stat.cash_bill_created_count = @cash_bill_created_count
            f_mis_revenue_stat.cash_bill_count = @cash_bill_count
            f_mis_revenue_stat.cash_bill_created_amount = @cash_bill_created_amount
            f_mis_revenue_stat.cash_bill_settled_amount = @cash_settled_from_advance
            f_mis_revenue_stat.cash_bill_created_discount = @cash_bill_created_discount
            f_mis_revenue_stat.cash_bill_discount = @cash_bill_discount
            f_mis_revenue_stat.cash_bill_created_offer = @cash_bill_created_offer
            f_mis_revenue_stat.cash_bill_offer = @cash_bill_offer
            f_mis_revenue_stat.cash_bill_created_advance_payment = @cash_created_bills_advance_collection
            f_mis_revenue_stat.cash_bill_advance_payment = @advance_payment
            f_mis_revenue_stat.cash_bill_amount = @cash_bill_amount

            f_mis_revenue_stat.credit_bill_created_count = @credit_bill_created_count
            f_mis_revenue_stat.credit_bill_count = @credit_bill_count
            f_mis_revenue_stat.credit_bill_created_amount = @credit_bill_created_amount
            f_mis_revenue_stat.credit_bill_settled_amount = @credit_settled_from_advance
            f_mis_revenue_stat.credit_bill_created_discount = @credit_bill_created_discount
            f_mis_revenue_stat.credit_bill_discount = @credit_bill_discount
            f_mis_revenue_stat.credit_bill_created_offer = @credit_bill_created_offer
            f_mis_revenue_stat.credit_bill_offer = @credit_bill_offer
            f_mis_revenue_stat.credit_bill_amount = @credit_bill_amount
            f_mis_revenue_stat.credit_pending_created_amount = @create_pending_amount
            f_mis_revenue_stat.credit_pending_amount = @total_pending_amount

            f_mis_revenue_stat.refund_bill_count = @revenue_refund_bill_count
            f_mis_revenue_stat.refund_bill_charges = @revenue_refund_bill_charges
            f_mis_revenue_stat.refund_bill_amount = @revenue_refund_bill_amount

            f_mis_revenue_stat.cash_refund_bill_count = @revenue_cash_refund_bill_count
            f_mis_revenue_stat.cash_refund_bill_charges = @revenue_cash_refund_bill_charges
            f_mis_revenue_stat.cash_refund_bill_amount = @revenue_cash_refund_bill_amount

            f_mis_revenue_stat.credit_refund_bill_count = @revenue_credit_refund_bill_count
            f_mis_revenue_stat.credit_refund_bill_charges = @revenue_credit_refund_bill_charges
            f_mis_revenue_stat.credit_refund_bill_amount = @revenue_credit_refund_bill_amount
            # EOF revenue fields

            f_mis_revenue_stat.filter_fields = filter_fields_hash
            f_mis_revenue_stat.search_fields = search_fields_hash
            f_mis_revenue_stat.save!
          else
            @mis_logger.info(" ====== Invoices with nil department ids: #{d_invoices.pluck(:_id)}")
          end
        end
      end
      # EOF dept_wise_stats

      def revenue_data(d_invoices, receipt_date, department_id)
        cash_invoice_info(d_invoices, receipt_date, department_id)
        credit_invoice_info(d_invoices, receipt_date, department_id)
        revenue_return_invoice_info(d_invoices, receipt_date, department_id)

        @total_bill_count = @cash_bill_count + @credit_bill_count
        @total_bill_amount = @cash_bill_amount + @credit_bill_amount
        @total_bill_discount = @cash_bill_discount + @credit_bill_discount
        @total_bill_offer = @cash_bill_offer + @credit_bill_offer

        @advance_payment = @cash_created_bills_advance_collection
      end
      # EOF revenue_data

      def cash_invoice_info(d_invoices, receipt_date, department_id)
        cash_invoices = d_invoices.select do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
            inv[:receipt_display_fields]['bill_type'] == 'cash' &&
            inv[:receipt_display_fields]['department_id'] == department_id &&
            inv[:receipt_created_at].to_date == receipt_date
        end
        cash_created_bills_info(cash_invoices, receipt_date)

        @cash_settled_from_advance = @cash_advance_collection_created

        @cash_bill_count = @cash_bill_created_count
        @cash_bill_amount = @cash_bill_created_amount + @cash_settled_from_advance
        @cash_bill_discount = @cash_bill_created_discount
        @cash_bill_offer = @cash_bill_created_offer
      end
      # EOF cash_invoice_info

      def cash_created_bills_info(cash_invoices, _receipt_date)
        @cash_bill_created_count = cash_invoices.count || 0
        @cash_bill_created_discount = cash_invoices.map { |inv| inv[:receipt_display_fields]['total_discount'].to_f }.reduce(0, :+) || 0.00
        @cash_bill_created_offer = cash_invoices.map { |inv| inv[:receipt_display_fields]['total_offer'].to_f }.reduce(0, :+) || 0.00
        @cash_created_bills_without_advance = cash_invoices.select do |inv|
          inv[:receipt_display_fields]['advance_payment'].to_f == 0.00
        end
        @cash_collection_created_without_advance = @cash_created_bills_without_advance
                                                   .map { |inv| inv[:receipt_display_fields]['amount_received'].to_f }
                                                   .reduce(0, :+) || 0.00
        @cash_created_bills_with_advance = cash_invoices - @cash_created_bills_without_advance
        @cash_collection_created_with_advance = @cash_created_bills_with_advance.map do |inv|
          inv[:receipt_display_fields]['amount_received'].to_f
        end.reduce(0, :+) || 0.00
        @cash_bill_created_amount = @cash_collection_created_without_advance + @cash_collection_created_with_advance

        @cash_advance_collection_created = @cash_created_bills_with_advance.map do |inv|
          inv[:receipt_display_fields]['advance_payment'].to_f
        end.reduce(0, :+) || 0.00

        @cash_created_bills_optical_advance = @cash_created_bills_with_advance.select do |inv|
          inv[:receipt_display_fields]['department_id'] == '50121007'
        end
        @cash_created_bills_advance_collection = @cash_created_bills_optical_advance.map do |inv|
          inv[:receipt_display_fields]['advance_payment'].to_f
        end.reduce(0, :+) || 0.00
      end
      # EOF cash_created_bills_info

      def credit_invoice_info(d_invoices, receipt_date, department_id)
        credit_invoices = d_invoices.select do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
          inv[:receipt_display_fields]['bill_type'] == 'credit' &&
            inv[:receipt_display_fields]['department_id'] == department_id
        end
        credit_created_invoices_info(credit_invoices, receipt_date)
        @credit_bill_count = @credit_bill_created_count
        @credit_settled_from_advance = @credit_advance_collection_created
        @credit_bill_amount = @credit_bill_created_amount + @credit_settled_from_advance
        @credit_bill_discount = @credit_bill_created_discount
        @credit_bill_offer = @credit_bill_created_offer
        @total_pending_amount = @create_pending_amount
      end
      # EOF credit_invoice_info

      def credit_created_invoices_info(credit_invoices, receipt_date)
        @credit_created_invoices = credit_invoices.select do |inv|
          inv[:receipt_created_at].to_date == receipt_date
        end
        @credit_bill_created_count = @credit_created_invoices.count || 0
        @credit_bill_created_discount = @credit_created_invoices.map do |inv|
          inv[:receipt_display_fields]['total_discount'].to_f
        end.reduce(0, :+) || 0.00
        @credit_bill_created_offer = @credit_created_invoices.map do |inv|
          inv[:receipt_display_fields]['total_offer'].to_f
        end.reduce(0, :+) || 0.00
        @credit_created_invoices_without_advance = @credit_created_invoices.select do |inv|
          inv[:receipt_display_fields]['advance_payment'].to_f == 0.00
        end
        @credit_collection_created_without_advance = @credit_created_invoices_without_advance
                                                     .map { |inv| inv[:receipt_display_fields]['amount_received'].to_f }
                                                     .reduce(0, :+) || 0.00
        @credit_created_bills_with_advance = @credit_created_invoices - @credit_created_invoices_without_advance
        @credit_collection_created_with_advance = @credit_created_bills_with_advance
                                                  .map { |inv| inv[:receipt_display_fields]['amount_received'].to_f }
                                                  .reduce(0, :+) || 0.00
        @credit_bill_created_amount = @credit_collection_created_without_advance +
                                      @credit_collection_created_with_advance
        @create_pending_invoices = @credit_created_invoices.select do |inv|
          inv[:receipt_display_fields]['still_pending'].to_f > 0
        end
        @create_pending_amount = @create_pending_invoices
                                 .map { |inv| inv[:receipt_display_fields]['still_pending'].to_f }
                                 .reduce(0, :+) || 0.00
        @credit_advance_collection_created = @credit_created_bills_with_advance .map do |inv|
          inv[:receipt_display_fields]['advance_payment'].to_f
        end.reduce(0, :+) || 0.00
      end
      # EOF credit_created_invoices_info

      def return_invoice_info(d_invoices, receipt_date, department_id)
        all_return_invoices = d_invoices.select do |inv|
          inv[:receipt_display_fields]['department_id'] == department_id &&
          inv[:refunds_count].present? &&
          inv[:refunds_count] > 0 &&
          inv[:has_refund_history].present? &&
          inv[:receipt_created_at].to_date == receipt_date
        end
        return_invoices = all_return_invoices.select do |inv|
          inv[:refunds_count].present? &&
          inv[:refunds_count] > 0 &&
          inv[:receipt_display_fields]['department_id'] == department_id &&
          inv[:receipt_display_fields]['bill_no'].present?
        end
        refund_invoices_detail_info(return_invoices, receipt_date, department_id)
        # EOF return against bills
        # return against patient
        patient_returns = all_return_invoices - return_invoices
        @patient_return_count = patient_returns.count || 0
        @patient_return_amount = patient_returns.map do |inv|
          (inv[:refund_invoice_fields]['return_amount'].to_f rescue 0)
        end.reduce(0, :+) || 0.00
        # EOF return against patient
        @cash_refund_bill_count += @patient_return_count
        @cash_refund_bill_amount += @patient_return_amount
        @refund_bill_count = @cash_refund_bill_count + @credit_refund_bill_count + @advance_refund_bill_count
        @refund_bill_amount = @cash_refund_bill_amount + @credit_refund_bill_amount + @refund_advance_amount
        @refund_bill_charges = @cash_refund_bill_charges + @credit_refund_bill_charges + @refund_advance_charges
      end
      # EOF return_invoice_info

      def revenue_return_invoice_info(d_invoices, receipt_date, department_id)
        revenue_return_invoices = d_invoices.select do |inv|
          inv[:refunds_count].present? &&
          inv[:refunds_count] > 0 &&
          inv[:receipt_display_fields]['department_id'] == department_id &&
          inv[:has_refund_history].present? &&
          inv[:receipt_created_at].to_date == receipt_date
        end
        # return against bills
        refund_invoices_detail_info(revenue_return_invoices, receipt_date, department_id, 'revenue')
        # EOF return against bills
        # revenue refund data
        @revenue_refund_bill_count = @revenue_cash_refund_bill_count + @revenue_credit_refund_bill_count
        @revenue_refund_bill_amount = @revenue_cash_refund_bill_amount + @revenue_credit_refund_bill_amount
        @revenue_refund_bill_charges = @revenue_cash_refund_bill_charges + @revenue_credit_refund_bill_charges
      end
      # EOF revenue_return_invoice_info

      def refund_invoices_detail_info(return_invoices, receipt_date, department_id, calling_from='')
        ['cash', 'credit'].each do |invoice_type|
          create_update_refunds = return_invoices.select do |inv|
            inv[:receipt_display_fields]['bill_type'] == invoice_type &&
            inv[:receipt_display_fields]['department_id'] == department_id
          end
          instance_variable_set("@#{invoice_type}_refund_invoices", create_update_refunds)
        end
        if @cash_refund_invoices
          cash_refund_bills = @cash_refund_invoices.select do |inv| 
            inv[:is_advance] == false
          end
          if calling_from == 'revenue'
            # refund_amount
            cash_refund_count = cash_refund_bills.map do |inv|
              inv[:refunds_count].to_i
            end.reduce(0, :+) || 0.00
            cash_return_bills = cash_refund_bills.map do |inv|
              inv[:receipt_display_fields]['refund_amount'].to_f
            end.reduce(0, :+) || 0.00

            cash_return_charges = cash_refund_bills.map do |inv|
              inv[:refund_history].select do |r_history|
                r_history['refund_date'].present?
              end.sum { |amt| amt['return_charges'].to_f }
            end.reduce(0, :+) || 0.00
            @revenue_cash_refund_bill_count = cash_refund_count || 0
            @revenue_cash_refund_bill_amount = cash_return_bills || 0.0
            @revenue_cash_refund_bill_charges = cash_return_charges || 0.0
            # EOF cash bill refund
          else
            # advance refund
            advance_cash_refunds = @cash_refund_invoices.select{|inv| inv[:is_advance] == true}
            @advance_refund_bill_count = advance_cash_refunds.count || 0
            advance_refund_bills = advance_cash_refunds.map do |inv|
              inv[:refund_history].select do |r_history|
                r_history['refund_date'].present?
              end.sum { |amt| amt['amount'].to_f }
            end.reduce(0, :+) || 0.00

            @refund_advance_amount = advance_refund_bills#.reduce(0, :+) || 0.00
            advance_refund_charges = advance_cash_refunds.map do |inv|
              inv[:refund_history].select do |r_history|
                r_history['refund_date'].present?
              end.sum { |amt| amt['return_charges'].to_f }
            end.reduce(0, :+) || 0.00

            @refund_advance_charges = advance_refund_charges
            # EOF advance refund

            cash_return_bills = cash_refund_bills.map do |inv|
              inv[:receipt_display_fields]['refund_amount'].to_f
            end.reduce(0, :+) || 0.00

            cash_return_charges = cash_refund_bills.map do |inv|
              inv[:refund_history].select do |r_history|
                r_history['refund_date'].present?
              end.sum { |amt| amt['return_charges'].to_f }
            end.reduce(0, :+) || 0.00

            @cash_refund_bill_count = cash_refund_bills.count || 0
            @cash_refund_bill_amount = cash_return_bills || 0.0
            @cash_refund_bill_charges = cash_return_charges || 0.0
          end
        end

        if @credit_refund_invoices && calling_from == 'revenue'
          credit_return_bills = @credit_refund_invoices.map do |inv|
            inv[:receipt_display_fields]['refund_amount'].to_f
          end.reduce(0, :+) || 0.00
          credit_return_charges = @credit_refund_invoices.map do |inv|
            inv[:refund_history].select do |r_history|
              r_history['refund_date'].present? &&
              r_history['refund_date'].to_date == receipt_date
            end.sum { |amt| amt['return_charges'].to_f }
          end.reduce(0, :+) || 0.00
          @revenue_credit_refund_bill_amount = credit_return_bills || 0.0
          @revenue_credit_refund_bill_charges = credit_return_charges || 0.0
          @revenue_credit_refund_bill_count = @credit_refund_invoices.count || 0
        elsif @credit_refund_invoices
          credit_return_bills = @credit_refund_invoices.map do |inv|
            inv[:receipt_display_fields]['refund_amount'].to_f
          end.reduce(0, :+) || 0.00
          credit_return_charges = @credit_refund_invoices.map do |inv|
            inv[:refund_history].select do |r_history|
              r_history['refund_date'].present? &&
              r_history['refund_date'].to_date == receipt_date
            end.sum { |amt| amt['return_charges'].to_f }
          end.reduce(0, :+) || 0.00
          @credit_refund_bill_amount = credit_return_bills || 0.0
          @credit_refund_bill_charges = credit_return_charges || 0.0
          @credit_refund_bill_count = @credit_refund_invoices.count || 0
        end
      end
      # EOF refund_invoices_detail_info

      def cancelled_invoice_info(d_invoices, receipt_date, department_id)
        cancelled_invoices = d_invoices.select do |inv|
          inv[:is_cancelled].present? &&
            inv[:cancelled_invoice_fields]['cancel_date'].present? &&
            inv[:cancelled_invoice_fields]['cancel_date'].to_date == receipt_date &&
            inv[:receipt_display_fields]['department_id'] == department_id
        end
        @cancelled_bill_count = cancelled_invoices.count || 0
        @cancelled_bill_amount = cancelled_invoices.map do |inv|
          inv[:cancelled_invoice_fields]['refund_amount'].to_f
        end.reject(&:nil?).reduce(0, :+) || 0.00
      end
      # EOF cancelled_invoice_info

      def collection_data(d_invoices, receipt_date, department_id, department_name, department_order)
        cashsale_collections = d_invoices.map do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
            inv[:receipt_display_fields]['department_id'] == department_id &&
            inv[:payment_received_breakups].present? &&
            inv[:payment_received_breakups].select do |payment_received|
                payment_received['is_settled'] == false &&
                payment_received['time'].present? &&
                payment_received['time'].to_date == receipt_date
            end.sum { |amt| amt['amount'] }
        end
        @cashsale_amount = cashsale_collections.reject { |cashsale| cashsale == false }.reduce(0, :+) || 0.0
        @advance_amount = advance_payment_info(receipt_date, department_id, d_invoices)
        settle_collections = d_invoices.map do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
            inv[:receipt_display_fields]['department_id'] == department_id &&
            inv[:payment_received_breakups].present? &&
            inv[:payment_received_breakups].select do |payment_received|
                payment_received['is_settled'] == true &&
                payment_received['time'].present? &&
                payment_received['time'].to_date == receipt_date
            end.sum { |amt| amt['amount'] }
        end
        @creditsale_settle = settle_collections.reject { |settle| settle == false }.reduce(0, :+) || 0.0
        @collection_total = @cashsale_amount + @advance_amount + @creditsale_settle
        credit_sales = d_invoices.select do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
            inv[:receipt_display_fields]['bill_type'] == 'credit'
        end
        receivable_self = credit_sales.map do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
            inv[:payment_pending_breakups]&.select do |payment_pending|
              payment_pending['is_canceled'] == false &&
              payment_pending['received_from'].to_s == inv[:patient_display_fields]['patient_id'] &&
                payment_pending['time'].present? &&
                payment_pending['time'].to_date == receipt_date
            end&.sum { |amt| amt['amount'].to_f } || 0
        end
        @receivable_self_amount = receivable_self.reduce(0, :+) || 0.0
        receivable_thirdparty = credit_sales.map do |inv|
          inv[:is_advance] == false &&
          inv[:has_refund] == false &&
            inv[:payment_pending_breakups]&.select do |payment_pending|
              payment_pending['is_canceled'] == false &&
              payment_pending['received_from'].to_s != inv[:patient_display_fields]['patient_id'] &&
              payment_pending['time'].present? &&
                payment_pending['time'].to_date == receipt_date
            end&.sum { |amt| amt['amount'].to_f } || 0
        end
        @receivable_other_amount = receivable_thirdparty.reduce(0, :+) || 0.0
        @receivable_total = @receivable_self_amount + @receivable_other_amount
        return_invoice_info(d_invoices, receipt_date, department_id)
        search_fields_hash = { department_name: department_name }
        filter_fields_hash = @filter_fields_hash.merge(department_id: department_id)
        f_mis_revenue_stat = Finance::StatisticData.find_or_create_by(
          receipt_date: receipt_date, facility_id: @facility_id, department_id: department_id
        )
        f_mis_revenue_stat.organisation_id = @organisation_id
        f_mis_revenue_stat.department_name = department_name
        f_mis_revenue_stat.department_order = department_order
        f_mis_revenue_stat.facility_name = @facility_name
        f_mis_revenue_stat.has_collection_data = @collection_total > 0 || @receivable_total > 0 || @refund_bill_amount > 0 ? true : false
        f_mis_revenue_stat.cashsale_amount = @cashsale_amount
        f_mis_revenue_stat.advance_amount = @advance_amount
        f_mis_revenue_stat.creditsale_settle = @creditsale_settle
        f_mis_revenue_stat.collection_total = @collection_total
        f_mis_revenue_stat.receivable_self_amount = @receivable_self_amount
        f_mis_revenue_stat.receivable_other_amount = @receivable_other_amount
        f_mis_revenue_stat.receivable_total = @receivable_total
        f_mis_revenue_stat.refund_cashsale_amount = @cash_refund_bill_amount
        f_mis_revenue_stat.refund_creditsale_amount = @credit_refund_bill_amount
        f_mis_revenue_stat.refund_advance_amount = @refund_advance_amount
        f_mis_revenue_stat.refund_total = @refund_bill_amount
        f_mis_revenue_stat.refund_cashsale_charges = @cash_refund_bill_charges
        f_mis_revenue_stat.refund_creditsale_charges = @credit_refund_bill_charges
        f_mis_revenue_stat.refund_advance_charges = @refund_advance_charges
        f_mis_revenue_stat.refund_charges = @refund_bill_charges
        # EOF collection fields

        f_mis_revenue_stat.filter_fields = filter_fields_hash
        f_mis_revenue_stat.search_fields = search_fields_hash
        f_mis_revenue_stat.save!
      end
      # collection_data

      def advance_payment_info(receipt_date, department_id, d_invoices)
        advance_payment_received = d_invoices.select do |invoice|
          invoice[:is_advance] == true &&
          invoice[:has_refund] == false &&
            invoice[:receipt_display_fields]['bill_date'].to_date == receipt_date &&
            invoice[:receipt_display_fields]['department_id'] == department_id
        end&.sum { |amt| amt[:receipt_display_fields]['amount'].to_f } || 0
        advance_payment_received
      end
      # EOF advance_payment_info

      def payer_wise_stats(payer_wise_invoices, receipt_date)
        payer_wise_invoices.each do |payer_id, p_invoices|
          next unless payer_id.present?

          payer = PayerMaster.find_by(id: payer_id)
          payer_name = begin
                         payer.display_name
                       rescue StandardError
                         payer.first_name
                       end

          total_no_of_bills = p_invoices.count || 0
          total_payment_received = p_invoices.map { |inv| inv.payment_received_breakups.where(received_from: payer_id).pluck(:amount) }.flatten.reduce(0, :+) || 0.00
          total_pending_amount = p_invoices.map { |inv| inv.payment_pending_breakups.where(received_from: payer_id).pluck(:amount) }.flatten.reduce(0, :+) || 0.00
          
          payer_stats_fields_hash = {
            'total_no_of_bills': total_no_of_bills,
            'total_payment_received': total_payment_received,
            'total_pending_amount': total_pending_amount
          }

          search_fields_hash = { payer_name: payer_name }

          filter_fields_hash = @filter_fields_hash.merge(payer_id: payer_id)

          f_mis_revenue_stat_payer = Finance::StatisticPayer.find_or_create_by(
            receipt_date: receipt_date, payer_id: payer_id, facility_id: @facility_id
          )
          f_mis_revenue_stat_payer.organisation_id = @organisation_id
          f_mis_revenue_stat_payer.payer_name = payer_name
          f_mis_revenue_stat_payer.facility_name = @facility_name
          f_mis_revenue_stat_payer.payer_stats_fields = payer_stats_fields_hash
          f_mis_revenue_stat_payer.filter_fields = filter_fields_hash
          f_mis_revenue_stat_payer.search_fields = search_fields_hash
          f_mis_revenue_stat_payer.save!
        end
      end
      # EOF payer_wise_stats
    end
  end
end
