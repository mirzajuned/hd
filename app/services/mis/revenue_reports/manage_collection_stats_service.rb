module Mis::RevenueReports
  class ManageCollectionStatsService
    class << self
      # def call(collection_invoices, organisation_id, facility_id, _mis_logger = nil)
      def call(collection_invoices, organisation_ids, _mis_logger = nil)
        mis_logger ||= Logger.new("#{Rails.root}/log/mis_collection_logger.log")
        group_by_organisations = collection_invoices.group_by { |al| al[:organisation_id] }
        group_by_organisations.each do |organisation_id, group_by_organisation|
          @organisation_id = organisation_id
          group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
          group_by_facilities.each do |facility_id, group_by_facility|
            @facility_id = facility_id
            @facility_name = Facility.find_by(id: @facility_id).try(:name)
            final_dates = group_by_facility.pluck(:receipt_date).map(&:to_date).uniq.sort
            final_dates.each do |bill_receipt_date|
              date_wise_collection = group_by_facility.select do |invoice|
                invoice[:receipt_date].to_date == bill_receipt_date
              end
              user_wise_invoices(date_wise_collection, bill_receipt_date)
            end
          end
        end
      end

      def user_wise_invoices(invoices, bill_receipt_date)
        userwise_invoices = invoices.group_by { |user_wise_invoice| user_wise_invoice[:user_id] }
        userwise_invoices.each do |user_id, user_invoices|
          department_wise_invoices(user_id, user_invoices, bill_receipt_date) if user_id.present?
        end
      end
      # EOF user_wise_invoices

      def department_wise_invoices(user_id, user_invoices, bill_receipt_date)
        department_wise_invoices = user_invoices.group_by do |date_wise_invoice|
          date_wise_invoice[:receipt_display_fields]['department_id']
        end
        collection_stats_data(department_wise_invoices, user_id, bill_receipt_date)
      end
      # EOF department_wise_invoices

      def collection_stats_data(department_wise_invoices, user_id, bill_receipt_date)
        department_wise_invoices.each do |department_id, d_invoices|
          next unless department_id.present?

          department = Department.find_by(id: department_id)
          department_name = department.try(:display_name)
          department_order = department.try(:order)

          user = User.find_by(id: user_id)
          user_fullname = user.try(:fullname)

          @stats_data = Finance::StatisticCollectionTransactionData.find_or_create_by(
            organisation_id: @organisation_id, facility_id: @facility_id, user_id: user_id,
            department_id: department_id, receipt_date: bill_receipt_date
          )

          advance_receipts = d_invoices.select do |receipt|
            receipt[:is_advance] == true ||
              (receipt[:is_refund] == true && receipt[:receipt_display_fields]['bill_no'] == '-' &&
                receipt[:receipt_display_fields]['receipt_no'].present?)
          end
          advance_receipts_data(advance_receipts)

          all_bills = d_invoices.select do |bill|
            bill[:is_bill] == true ||
              (bill[:is_refund] == true && bill[:receipt_display_fields]['bill_no'] != '-')
          end

          cash_bills = all_bills.select { |bill| bill[:receipt_display_fields]['bill_type'] == 'cash' }
          credit_bills = all_bills - cash_bills
          cash_bills_data(cash_bills)
          credit_bills_data(credit_bills)
          bills_data
          advance_bill_refund_mop
          net_collection = (
            (@advance_receipts_amount + @bills_amount) - (@refund_advance_amount + @refund_bills_amount)
          )

          filter_fields = {
            organisation_id: @organisation_id, facility_id: @facility_id, department_id: department_id,
            user_id: user_id, receipt_date: bill_receipt_date
          }
          search_fields = { department_name: department_name, user_name: user_fullname }

          @stats_data.facility_name = @facility_name
          @stats_data.user_name = user_fullname
          @stats_data.department_name = department_name
          @stats_data.department_order = department_order
          # @stats_data.advance_receipts_count = @advance_receipts_count
          @stats_data.advance_receipts_amount = @advance_receipts_amount
          # @stats_data.advance_info = @advance_info
          # @stats_data.refund_advance_count = @refund_advance_count
          @stats_data.refund_advance_amount = @refund_advance_amount
          @stats_data.refund_advance_info = @refund_advance_info

          @stats_data.cash_bills_count = @cash_bills_count
          @stats_data.cash_bills_amount = @cash_bills_amount
          @stats_data.cash_bills_info = @cash_bills_info
          @stats_data.cash_refund_bills_count = @cash_refund_bills_count
          @stats_data.cash_refund_bills_amount = @cash_refund_bills_amount
          @stats_data.cash_refund_bills_info = @cash_refund_bills_info

          @stats_data.credit_bills_count = @credit_bills_count
          @stats_data.credit_bills_amount = @credit_bills_amount
          @stats_data.credit_bills_info = @credit_bills_info
          @stats_data.credit_refund_bills_count = @credit_refund_bills_count
          @stats_data.credit_refund_bills_amount = @credit_refund_bills_amount
          @stats_data.credit_refund_bills_info = @credit_refund_bills_info

          # @stats_data.bills_count = @bills_count
          @stats_data.bills_amount = @bills_amount
          @stats_data.bills_info = @bills_info
          # @stats_data.refund_bills_count = @refund_bills_count
          @stats_data.refund_bills_amount = @refund_bills_amount
          @stats_data.refund_bills_info = @refund_bills_info

          @stats_data.advance_bills_refund_info = @advance_bills_refund_info

          @stats_data.net_collection = net_collection
          @stats_data.filter_fields = filter_fields
          @stats_data.search_fields = search_fields
          @stats_data.save!
        end
      end
      # EOF collection_stats_data

      def advance_receipts_data(advance_receipts)
        # advance
        normal_advance_receipts = advance_receipts.select { |advance| advance[:is_advance] == true }
        @stats_data.advance_receipts_count = normal_advance_receipts.count
        @advance_receipts_amount = normal_advance_receipts.map do |inv|
          inv[:receipt_display_fields]['receipt_amount']
        end.reject(&:nil?).reduce(0, :+) || 0.00
        @stats_data.advance_info = mop_breakup(normal_advance_receipts, 'advance_receipts')
        # EOF advance
        # refund
        refund_advances = advance_receipts - normal_advance_receipts
        @stats_data.refund_advance_count = refund_advances.count
        @refund_advance_amount = refund_advances.map do |inv|
          inv[:receipt_display_fields]['receipt_amount'].to_f
        end.reject(&:nil?).reduce(0, :+) || 0.00

        @refund_advance_info = mop_breakup(refund_advances, 'refund_advance_receipts')
        # EOF refund
      end
      # EOF advance_receipts_data

      def cash_bills_data(all_cash_bills)
        # bills
        normal_bills = all_cash_bills.select { |bills| bills[:is_bill] == true }
        @cash_bills_count = normal_bills.count
        @cash_bills_amount = normal_bills.map do |bills|
          bills[:receipt_display_fields]['receipt_amount']
        end.reject(&:nil?).reduce(0, :+) || 0.00
        @cash_bills_info = mop_breakup(normal_bills, 'cash_bills')
        # EOF bills
        # refund
        cash_refund_bills = all_cash_bills - normal_bills
        @cash_refund_bills_count = cash_refund_bills.count
        @cash_refund_bills_amount = cash_refund_bills.map do |bills|
          bills[:receipt_display_fields]['receipt_amount'].to_f
        end.reject(&:nil?).reduce(0, :+) || 0.00
        @cash_refund_bills_info = mop_breakup(cash_refund_bills, 'cash_refund_bills')
        # EOF refund
      end
      # EOF cash_bills_data

      def credit_bills_data(all_credit_bills)
        # bills
        normal_bills = all_credit_bills.select { |bills| bills[:is_bill] == true }
        @credit_bills_count = normal_bills.count
        @credit_bills_amount = normal_bills.map do |bills|
          bills[:receipt_display_fields]['receipt_amount']
        end.reject(&:nil?).reduce(0, :+) || 0.00
        @credit_bills_info = mop_breakup(normal_bills, 'credit_bills')
        # EOF bills
        # refund
        credit_refund_bills = all_credit_bills - normal_bills
        @credit_refund_bills_count = credit_refund_bills.count
        @credit_refund_bills_amount = credit_refund_bills.map do |bills|
          bills[:receipt_display_fields]['receipt_amount'].to_f
        end.reject(&:nil?).reduce(0, :+) || 0.00
        @credit_refund_bills_info = mop_breakup(credit_refund_bills, 'credit_refund_bills')
        # EOF refund
      end
      # EOF credit_bills_data

      def bills_data
        @stats_data.bills_count = @cash_bills_count + @credit_bills_count
        @bills_amount = @cash_bills_amount + @credit_bills_amount
        cash_credit_info = @cash_bills_info + @credit_bills_info
        @bills_info = cash_credit_info.group_by { |h| h[:mop] }.values.map do |a|
          a.reduce do |acc, h|
            acc.merge(h) { |k, v1, v2| k == :mop ? v1 : v1 + v2 }
          end
        end
        hash_to_mop_breakup(@bills_info, 'bills')
        @stats_data.refund_bills_count = @cash_refund_bills_count + @credit_refund_bills_count
        @refund_bills_amount = @cash_refund_bills_amount + @credit_refund_bills_amount
        refund_info = @cash_refund_bills_info + @credit_refund_bills_info
        @refund_bills_info = refund_info.group_by { |h| h[:mop] }.values.map do |a|
          a.reduce do |acc, h|
            acc.merge(h) { |k, v1, v2| k == :mop ? v1 : v1 + v2 }
          end
        end
        hash_to_mop_breakup(@refund_bills_info, 'refund_bills')
      end
      # EOF bills_data

      def mop_breakup(refund_bills_receipts, field_name = '')
        mop_refund_ary = []
        refund_bills_receipts.group_by do |bills|
          bills[:receipt_display_fields]['mode_of_payment']
        end.each do |mop, mop_receipts|
          if mop.present?
            mode_of_payment = mop.parameterize(separator: '_')
            mop_amount = mop_receipts.map do |bills|
              bills[:receipt_display_fields]['receipt_amount'].to_f
            end.reject(&:nil?).reduce(0, :+) || 0.00
            mop_count = mop_receipts.count || 0.00
            mop_refund_ary << { mop: mode_of_payment, amount: mop_amount, count: mop_count }
            if field_name.present?
              @stats_data.send("#{field_name}_#{mode_of_payment}_count=", mop_count)
              @stats_data.send("#{field_name}_#{mode_of_payment}=", mop_amount)
            end
          end
        end
        mop_refund_ary
      end
      # EOF mop_breakup

      def advance_bill_refund_mop
        all_refund_info = @refund_advance_info + @refund_bills_info
        @advance_bills_refund_info = all_refund_info.group_by { |h| h[:mop] }.values.map do |a|
          a.reduce do |acc, h|
            acc.merge(h) { |k, v1, v2| k == :mop ? v1 : v1 + v2 }
          end
        end
        hash_to_mop_breakup(@advance_bills_refund_info, 'refund_advance_bills')
      end
      # EOF advance_bill_refund_mop

      def hash_to_mop_breakup(mop_array, field_name = '')
        return unless field_name.present?

        mop_array.each do |mop_hash|
          mode_of_payment = mop_hash[:mop].parameterize(separator: '_')
          @stats_data.send("#{field_name}_#{mode_of_payment}_count=".to_sym, mop_hash[:count])
          @stats_data.send("#{field_name}_#{mode_of_payment}=".to_sym, mop_hash[:amount])
        end
      end
      # EOF hash_to_mop_breakup
    end
  end
end
