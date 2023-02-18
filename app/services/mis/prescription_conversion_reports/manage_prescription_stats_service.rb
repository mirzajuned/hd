module Mis::PrescriptionConversionReports
  class ManagePrescriptionStatsService
    class << self
      # def call(filtered_prescriptions, advised_date, mis_logger=nil)
      def call(filtered_prescriptions, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_conversion_logger.log")
        group_by_organisations = filtered_prescriptions.group_by { |al| al[:organisation_id] }
        group_by_organisations.each do |organisation_id, group_by_organisation|
          @organisation_id = organisation_id
          group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
          group_by_facilities.each do |facility_id, group_by_facility|
            @facility_id = facility_id
            @filter_fields_hash = { organisation_id: @organisation_id, facility_id: @facility_id }
            facility = Facility.find_by(id: @facility_id)
            @facility_name = facility.try(:name)
            @facility_timezone = facility.try(:time_zone)

            # prescriptions = group_by_facility.group_by { |al| al[:advised_on_date] }
            
            # prescriptions = group_by_facility.select do |prescription|
            #   prescription[:advised_on_date].present? && 
            #   prescription[:advised_on_date].to_date == advised_date
            # end
            
            if group_by_facility&.count > 0
              date_wise_prescriptions = group_by_facility.group_by { |i| i[:advised_on_date].to_date }
              stats_by_date(date_wise_prescriptions)
            end
          end
        end
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManagePrescriptionStatsService :: #{e.inspect}")
      end
      # end call method

      def stats_by_date(prescriptions)
        prescriptions.each do |advised_date, date_wise_prescriptions|
          # @filter_fields_hash[:advised_date] = advised_date
          # advised statistics by department
          department_wise_prescriptions = date_wise_prescriptions.group_by do |date_wise_prescription|
            date_wise_prescription[:department_id]
          end
          dept_wise_stats(department_wise_prescriptions, advised_date)
          # EOF advised statistics by department
        end
      end
      # end stats_by_date method

      def dept_wise_stats(department_wise_prescriptions, advised_date)
        department_wise_prescriptions.each do |department_id, d_prescriptions|
          if department_id.present?
            store_wise_prescriptions = d_prescriptions.group_by do |d_prescription|
              d_prescription[:store_id]
            end
            store_wise_stats(store_wise_prescriptions, advised_date, department_id)
          end
          # end if department_id.present? loop
        end
        # end dept_wise_invoices method
      end
      # end dept_wise_stats

      def store_wise_stats(store_prescriptions, advised_date, department_id)
        store_prescriptions.each do |store_id, s_prescriptions|
          if store_id.present?
            department = Department.find_by(id: department_id)
            department_name = department.try(:display_name)
            department_order = department.try(:order)

            store = Inventory::Store.find_by(id: store_id)
            store_name = store.try(:name)
            store_abbreviation_name = store.try(:abbreviation_name)
            store_present = store.try(:is_active)

            generate_data(s_prescriptions, advised_date, department_id, store_id)

            # filter_fields
            filter_fields_hash = {
              organisation_id: @organisation_id, facility_id: @facility_id, department_id: department_id,
              store_id: store_id, advised_on_date: advised_date
            }
            # EOF filter_fields

            # search_fields_hash
            search_fields_hash = {
              facility_name: @facility_name, department_name: department_name, store_name: store_name
            }
            # EOF search_fields_hash

            conersion_stats = Inventory::StoreConversionStatistic.find_or_create_by(
              advised_on: advised_date, facility_id: @facility_id, store_id: store_id, 
              department_id: department_id
            )

            conersion_stats.organisation_id = @organisation_id
            conersion_stats.facility_name = @facility_name
            conersion_stats.facility_timezone = @facility_timezone
            conersion_stats.department_name = department_name
            conersion_stats.department_order = department_order
            conersion_stats.store_name = store_name
            conersion_stats.store_abbreviation_name = store_abbreviation_name
            conersion_stats.store_present = store_present

            conersion_stats.total_advised = @total_advised
            conersion_stats.total_converted = @total_converted
            conersion_stats.conversion_in_days = @conversion_in_days
            conersion_stats.conversion_in_percentage = @conversion_in_percentage
            conersion_stats.filter_fields = filter_fields_hash
            conersion_stats.search_fields = search_fields_hash
            conersion_stats.save!
          end
          # end if store_id.present? loop
        end
        # end store_prescriptions each loop
      end
      # end store_wise_stats method

      def generate_data(s_prescriptions, advised_date, department_id, store_id)
        @advised_on = advised_date

        total_advised_prescriptions = s_prescriptions.select do |prescriptions| 
          prescriptions['department_id'] == department_id &&
          prescriptions['store_id'] == store_id &&
          prescriptions['advised_on_date'].to_date == advised_date
        end
        @total_advised = total_advised_prescriptions.count

        total_converted_prescriptions = s_prescriptions.select do |prescriptions| 
          prescriptions['department_id'] == department_id &&
          prescriptions['store_id'] == store_id &&
          prescriptions['advised_on_date'].to_date == advised_date &&
          prescriptions['is_converted'] == true
        end

        @total_converted = @conversion_in_days = @conversion_in_percentage = nil
        if total_converted_prescriptions.present?
          @total_converted = total_converted_prescriptions.count
          @conversion_in_days = total_converted_prescriptions.map{|arr| arr[:conversion_time_days]&.to_i}.sum
          @conversion_in_percentage = @conversion_in_days.to_f / @total_converted.to_f
        end
      end
      # end generate_data method
    end
  end
end
