module Mis::RevenueReports
  class ManageItemWiseBillTypeStatsService
    class << self
      def call(items, item_entry_date, organisation_id, facility_id, facility_name, facility_timezone)
        # mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        @organisation_id = organisation_id
        @facility_id = facility_id
        @facility_name = facility_name
        @facility_timezone = facility_timezone

        filtered_items = items.select do |item|
          item[:item_entry_date] == item_entry_date
        end
        date_wise_items = filtered_items.group_by { |i| i[:item_entry_date] }
        department_wise_data(date_wise_items)
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManageRevenueService :: #{e.inspect}")
      end
      # end call method

      def department_wise_data(date_wise_items)
        date_wise_items.each do |item_entry_date, date_wise_items|
          @item_entry_date = item_entry_date
          department_wise_items = date_wise_items.group_by do |date_wise_item|
            date_wise_item[:department_id]
          end
          department_wise_items.each do |department_id, d_items|
            @department_id = department_id
            bill_type_wise_data(d_items)
          end
        end
      end
      # EOF department_wise_items

      def bill_type_wise_data(d_items)
        bill_type_wise_items = d_items.group_by do |bill_type_wise_item|
          bill_type_wise_item[:bill_type]
        end
        bill_type_wise_items.each do |bill_type, bill_type_wise_item|
          @bill_type = bill_type
          service_type_wise_data(bill_type_wise_item)
        end
      end
      # end bill_type_wise_data

      def service_type_wise_data(d_items)
        service_wise_items = d_items.group_by do |service_type_wise_item|
          service_type_wise_item[:service_type]
        end
        service_wise_items.each do |service_type, service_wise_item|
          @service_type = service_type
          service_type_code_wise_data(service_wise_item)
        end
      end
      # end service_type_wise_data

      def service_type_code_wise_data(service_wise_items)
        service_type_code_wise_items = service_wise_items.group_by do |service_wise_item|
          service_wise_item[:service_type_code]
        end
        service_type_code_wise_items.each do |service_type_code, service_type_code_wise_item|
          @service_type_code = service_type_code
          service_group_id_by_data(service_type_code_wise_item)
        end
      end
      # end service_type_wise_data

      def service_group_id_by_data(service_type_code_wise_items)
        service_group_wise_items = service_type_code_wise_items.group_by do |service_type_code_wise_item|
          service_type_code_wise_item[:service_group_id]
        end
        service_group_wise_items.each do |service_group_id, service_group_items|
          @service_group_id = service_group_id
          service_sub_group_by_data(service_group_items)
        end
      end
      # end service_group_id_by_data

      def service_sub_group_by_data(service_group_items)
        service_group_wise_items = service_group_items.group_by do |service_group_item|
          service_group_item[:service_sub_group_id]
        end
        service_group_wise_items.each do |service_sub_group_id, service_sub_group_items|
          @service_sub_group_id = service_sub_group_id
          item_wise_bill_type_stats_generate(service_sub_group_items)
        end
      end
      # end service_sub_group_by_data

      def item_wise_bill_type_stats_generate(service_sub_group_items)
        service_type_code_names = service_sub_group_items.pluck(:service_type_code_name).uniq
        department = Department.find_by(id: @department_id.to_s)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        service_group_name = ServiceGroup.find_by(id: @service_group_id).try(:name)
        service_sub_group_name = ServiceSubGroup.find_by(id: @service_sub_group_id).try(:name)

        gender_group = service_sub_group_items.group_by { |al| al['patient_display_fields']['gender']  }
        male_size = gender_group['Male'].to_a.size
        female_size = gender_group['Female'].to_a.size
        transgender_size = gender_group['Transgender'].to_a.size
        gender_undefined_size = gender_group[nil].to_a.size
        gender_undefined_size += gender_group[''].to_a.size
        gender_stats_fields = { male: male_size, female: female_size, transgender: transgender_size, undefined: gender_undefined_size }
        
        age_group = service_sub_group_items.group_by{ |al| al['patient_display_fields']['patient_current_age'] }
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

        item_bill_type_stats = Finance::ItemWiseBillTypeStats.find_or_create_by(
          item_entry_date: @item_entry_date, organisation_id: @organisation_id, facility_id: @facility_id, 
          department_id: @department_id, bill_type: @bill_type, service_type: @service_type, 
          service_type_code: @service_type_code, service_group_id: @service_group_id, 
          service_sub_group_id: @service_sub_group_id
        )
        item_bill_type_stats.facility_name = @facility_name
        item_bill_type_stats.facility_timezone = @facility_timezone
        item_bill_type_stats.department_name = department_name
        item_bill_type_stats.department_order = department_order
        item_bill_type_stats.service_type_code_name = service_type_code_names.last
        item_bill_type_stats.service_group_name = service_group_name
        item_bill_type_stats.service_sub_group_name = service_sub_group_name
        item_bill_type_stats.patient_age_fields = age_stats_fields
        item_bill_type_stats.patient_gender_fields = gender_stats_fields
        item_bill_type_stats.gender_wise_age = gender_wise_age
        item_bill_type_stats.save
      end
      # end item_wise_bill_type_stats_generate
    end
  end
end
