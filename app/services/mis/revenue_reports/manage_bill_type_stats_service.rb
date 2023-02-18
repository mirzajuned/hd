module Mis::RevenueReports
  class ManageBillTypeStatsService
    class << self
      def call(invoices, receipt_date, organisation_id, facility_id, facility_name, facility_timezone)
        # mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        @organisation_id = organisation_id
        @facility_id = facility_id
        @facility_name = facility_name
        @facility_timezone = facility_timezone

        filtered_invoices = invoices.select do |item|
          item[:receipt_date] == receipt_date
        end
        date_wise_invoices = filtered_invoices.group_by { |i| i[:receipt_date] }
        department_wise_data(date_wise_invoices)
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManageRevenueService :: #{e.inspect}")
      end
      # end call method

      def department_wise_data(date_wise_invoices)
        date_wise_invoices.each do |receipt_date, date_wise_invoices|
          @receipt_date = receipt_date
          department_wise_invoices = date_wise_invoices.group_by do |date_wise_item|
            date_wise_item[:department_id]
          end
          department_wise_invoices.each do |department_id, d_invoices|
            @department_id = department_id
            bill_type_wise_data(d_invoices)
          end
        end
      end
      # EOF department_wise_invoices

      def bill_type_wise_data(d_invoices)
        bill_type_wise_invoices = d_invoices.group_by do |bill_type_wise_item|
          bill_type_wise_item[:bill_type]
        end
        bill_type_wise_invoices.each do |bill_type, bill_type_wise_item|
          @bill_type = bill_type
          bill_type_stats_generate(bill_type_wise_item)
        end
      end
      # end bill_type_wise_data

      def bill_type_stats_generate(bill_type_wise_item)
        department = Department.find_by(id: @department_id.to_s)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        
        gender_group = bill_type_wise_item.group_by { |al| al['patient_display_fields']['gender']  }
        male_size = gender_group['Male'].to_a.size
        female_size = gender_group['Female'].to_a.size
        transgender_size = gender_group['Transgender'].to_a.size
        gender_undefined_size = gender_group[nil].to_a.size
        gender_undefined_size += gender_group[''].to_a.size
        gender_stats_fields = { male: male_size, female: female_size, transgender: transgender_size, undefined: gender_undefined_size }

        age_group = bill_type_wise_item.group_by{ |al| al['patient_display_fields']['patient_current_age'] }
        till_fifteen = above_fifteen_till_fiftyfive = above_fiftyfive = undefined = 0
        male_till_fifteen = female_till_fifteen = transgender_till_fifteen = unspecified_till_fifteen = 0
        male_above_fifteen_till_fiftyfive = female_above_fifteen_till_fiftyfive = transgender_above_fifteen_till_fiftyfive = 0
        unspecified_above_fifteen_till_fiftyfive = male_above_fiftyfive = female_above_fiftyfive = 0
        transgender_above_fiftyfive = unspecified_above_fiftyfive = above_fiftyfive = 0
        male_undefined = female_undefined = transgender_undefined = unspecified_undefined = 0

        age_group.each do |key, val|
          age_val = key.to_i
          males = val.select{|patients| patients['patient_display_fields']['gender'].present? && patients['patient_display_fields']['gender'] == 'Male'}
          females = val.select{|patients| patients['patient_display_fields']['gender'].present? && patients['patient_display_fields']['gender'] == 'Female'}
          transgenders = val.select{|patients| patients['patient_display_fields']['gender'].present? && patients['patient_display_fields']['gender'] == 'Transgender'}
          unspecified_gender = val.select{|patients| patients['patient_display_fields']['gender'].nil? || patients['patient_display_fields']['gender'] == ''}

          case age_val
            when 0..15
              till_fifteen += 1
              male_till_fifteen += (males.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              female_till_fifteen += (females.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              transgender_till_fifteen += (transgenders.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              unspecified_till_fifteen += (unspecified_gender.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
            when 16..54
              above_fifteen_till_fiftyfive += 1
              male_above_fifteen_till_fiftyfive += (males.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              female_above_fifteen_till_fiftyfive += (females.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              transgender_above_fifteen_till_fiftyfive += (transgenders.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              unspecified_above_fifteen_till_fiftyfive += (unspecified_gender.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
            when 55..150
              above_fiftyfive += 1
              male_above_fiftyfive += (males.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              female_above_fiftyfive += (females.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              transgender_above_fiftyfive += (transgenders.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
              unspecified_above_fiftyfive += (unspecified_gender.select{|pat| pat['patient_display_fields']['patient_current_age'].to_i == age_val}.count)
            else
              undefined += 1
              male_undefined += (males.select{|pat| pat['patient_display_fields']['patient_current_age'].nil? || pat['patient_display_fields']['patient_current_age'].to_i == 1000}.count)
              female_undefined += (females.select{|pat| pat['patient_display_fields']['patient_current_age'].nil? || pat['patient_display_fields']['patient_current_age'].to_i == 1000}.count)
              transgender_undefined += (transgenders.select{|pat| pat['patient_display_fields']['patient_current_age'].nil? || pat['patient_display_fields']['patient_current_age'].to_i == 1000}.count)
              unspecified_undefined += (unspecified_gender.select{|pat| pat['patient_display_fields']['patient_current_age'].nil? || pat['patient_display_fields']['patient_current_age'].to_i == 1000}.count)
          end
        end
        
        age_stats_fields = { till_fifteen: till_fifteen, above_fifteen_till_fiftyfive: above_fifteen_till_fiftyfive,
                             above_fiftyfive: above_fiftyfive, undefined: undefined }
        gender_wise_age = {
            male_till_fifteen: male_till_fifteen, female_till_fifteen: female_till_fifteen, transgender_till_fifteen: transgender_till_fifteen,
            unspecified_till_fifteen: unspecified_till_fifteen, male_above_fifteen_till_fiftyfive: male_above_fifteen_till_fiftyfive,
            female_above_fifteen_till_fiftyfive: female_above_fifteen_till_fiftyfive, 
            transgender_above_fifteen_till_fiftyfive: transgender_above_fifteen_till_fiftyfive, 
            unspecified_above_fifteen_till_fiftyfive: unspecified_above_fifteen_till_fiftyfive,
            male_above_fiftyfive: male_above_fiftyfive, female_above_fiftyfive: female_above_fiftyfive,
            unspecified_above_fiftyfive: unspecified_above_fiftyfive, male_undefined: male_undefined,
            female_undefined: female_undefined, transgender_undefined: transgender_undefined,
            unspecified_undefined: unspecified_undefined
          }

        bill_type_stats = Finance::BillTypeStats.find_or_create_by(
          receipt_date: @receipt_date, organisation_id: @organisation_id, facility_id: @facility_id, 
          department_id: @department_id, bill_type: @bill_type, service_type: @service_type, 
          service_type_code: @service_type_code, service_group_id: @service_group_id, 
          service_sub_group_id: @service_sub_group_id
        )
        bill_type_stats.facility_name = @facility_name
        bill_type_stats.facility_timezone = @facility_timezone
        bill_type_stats.department_name = department_name
        bill_type_stats.department_order = department_order
        bill_type_stats.patient_age_fields = age_stats_fields
        bill_type_stats.patient_gender_fields = gender_stats_fields
        bill_type_stats.gender_wise_age = gender_wise_age
        bill_type_stats.save
      end
      # end bill_type_stats_generate
    end
  end
end
