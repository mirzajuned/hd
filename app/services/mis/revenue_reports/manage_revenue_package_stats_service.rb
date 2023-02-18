# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/BlockLength
module Mis::RevenueReports
  class ManageRevenuePackageStatsService
    class << self
      # rubocop:disable Layout/LineLength
      def call(filtered_invoices, organisation_ids, s_type, mis_logger=nil)
        @has_specialties = @has_sub_specialties = false
        @mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_service_package_stats_logger.log")
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
            @has_specialties = PricingMaster.where(
              facility_id: @facility_id, :specialty_id.nin => [nil, '']
            ).pluck(:specialty_id).uniq.count > 1
            @has_sub_specialties = PricingMaster.where(
              facility_id: @facility_id, :sub_specialty_id.nin => [nil, '']
            ).pluck(:sub_specialty_id).uniq.count > 0
            @s_type = s_type
            @services = group_by_facility.select do |service|
              service[:bill_entry_type] == @s_type
            end
            d_services = @services.group_by { |i| i[:service_entry_date].to_date }
            d_services.each do |service_entry_date, date_wise_services|
              @receipt_date = service_entry_date
              @filter_fields_hash[:service_entry_date] = @receipt_date

              specialty_wise_services = date_wise_services.group_by { |inv| inv[:specialty_id] }
              specialty_wise_stats(specialty_wise_services)
            end
          end
        end
      end
      # rubocop:enable Layout/LineLength

      def specialty_wise_stats(specialty_wise_services)
        specialty_wise_services.each do |specialty_id, s_services|
          return unless specialty_id.present?
          department_wise_services = s_services.group_by { |inv| inv[:department_id] }
          department_wise_stats(department_wise_services, specialty_id)
        end
      end

      def department_wise_stats(dept_wise_services, specialty_id)
        dept_wise_services.each do |department_id, d_services|
          user_wise_services = d_services.group_by { |inv| inv[:added_by_id] }
          user_wise_stats(user_wise_services, specialty_id, department_id)
        end
      end

      def user_wise_stats(user_wise_services, specialty_id, department_id)
        specialty_name = Specialty.find_by(id: specialty_id).try(:name)
        user_wise_services.each do |user_id, user_services|
          filtered_package_services = user_services.select do |services|
            services[:specialty_id] == specialty_id &&
            services[:department_id] == department_id &&
            services[:added_by_id] == user_id
          end
          package_wise_services = filtered_package_services.group_by{|ser| ser[:bill_entry_type_id]}
          send "#{@s_type}_wise_stats".to_sym, package_wise_services, specialty_id, specialty_name, department_id, user_id
        end
      end

      def surgery_package_wise_stats(package_wise_services, specialty_id, specialty_name, department_id, user_id)
        department = Department.find_by(id: department_id.to_s)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        
        package_wise_services.each do |surgery_package_id, p_services|
          next unless surgery_package_id.present?
          user_name = User.find_by(id: user_id).fullname
          package = SurgeryPackage.find_by(id: surgery_package_id)
          next unless package.present?
          surgery_package_name = begin
                                   package.display_name
                                 rescue StandardError
                                   package.name
                                 end
          package_definition = PackageDefinition.find_by(package_group_id: package.try(:package_group_id))
          sub_specialty_id = package_definition.try(:sub_specialty_id)
          sub_specialty_name = SubSpecialty.find_by(id: sub_specialty_id).try(:name)
          s_services = p_services.select do |services|
            services['bill_entry_type_id'] == surgery_package_id &&
            services['service_entry_datetime'] >= @receipt_date.beginning_of_day &&
            services['service_entry_datetime'] <= @receipt_date.end_of_day
          end

          total_no_of_bills = s_services.count
          total_revenue = s_services.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00
          free_bills = s_services.select{|service| service['discount_type'] == 'free' || service['discount_type'] == 'free_discounted'}
          free_services_revenue = free_bills.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00
          paid_bills = s_services.select{|service| service['discount_type'] == 'paid'}
          paid_services_revenue = paid_bills.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00
          discounted_bills = s_services.select{|service| service['discount_type'] == 'discounted' || service['discount_type'] == 'paid_discounted'}
          discounted_services_revenue = discounted_bills.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00
          search_fields_hash = { surgery_package_name: surgery_package_name }
          filter_fields_hash = @filter_fields_hash.merge(surgery_package_id: surgery_package_id)
          f_mis_revenue_stat = Finance::StatisticPackage.find_or_create_by(
            receipt_date: @receipt_date, facility_id: @facility_id, user_id: user_id, 
            surgery_package_id: surgery_package_id, sub_specialty_id: sub_specialty_id,
            specialty_id: specialty_id, department_id: department_id
          )
          f_mis_revenue_stat.organisation_id = @organisation_id
          f_mis_revenue_stat.surgery_package_name = surgery_package_name
          f_mis_revenue_stat.facility_name = @facility_name
          f_mis_revenue_stat.specialty_name = specialty_name
          f_mis_revenue_stat.has_specialties = @has_specialties
          f_mis_revenue_stat.sub_specialty_name = sub_specialty_name
          f_mis_revenue_stat.has_sub_specialties = @has_sub_specialties
          f_mis_revenue_stat.department_name = department_name
          f_mis_revenue_stat.department_order = department_order
          f_mis_revenue_stat.user_name = user_name
          f_mis_revenue_stat.total_no_of_bills = total_no_of_bills
          f_mis_revenue_stat.total_revenue = total_revenue

          f_mis_revenue_stat.no_of_free_bills = free_bills.count
          f_mis_revenue_stat.free_bills_revenue = free_services_revenue
          f_mis_revenue_stat.no_of_paid_bills = paid_bills.count
          f_mis_revenue_stat.paid_bills_revenue = paid_services_revenue
          f_mis_revenue_stat.no_of_discounted_bills = discounted_bills.count
          f_mis_revenue_stat.discounted_bills_revenue = discounted_services_revenue
          
          f_mis_revenue_stat.filter_fields = filter_fields_hash
          f_mis_revenue_stat.search_fields = search_fields_hash
          f_mis_revenue_stat.save!
          
        end
      end
      # EOF package_wise_stats

      def service_wise_stats(service_wise_services, specialty_id, specialty_name, department_id, user_id)
        department = Department.find_by(id: department_id.to_s)
        department_name = department.try(:display_name)
        department_order = department.try(:order)
        
        service_wise_services.each do |pricing_master_id, p_services|
          next unless pricing_master_id.present?

          user_name = User.find_by(id: user_id).fullname
          
          service_id = pricing_master_id
          service = PricingMaster.find_by(id: service_id)

          next unless service.present?
          service_name = service.try(:service_name)
          service_master = service.try(:service_master)
          sub_specialty_id = service_master.try(:sub_specialty_id) || nil
          sub_specialty_name = SubSpecialty.find_by(id: sub_specialty_id).try(:name) || nil

          s_services = p_services.select do |services|
            services['bill_entry_type_id'] == pricing_master_id &&
            services['service_entry_datetime'] >= @receipt_date.beginning_of_day &&
            services['service_entry_datetime'] <= @receipt_date.end_of_day
          end

          total_no_of_bills = s_services.count
          total_revenue = s_services.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00

          free_bills = s_services.select{|service| service['discount_type'] == 'free' || service['discount_type'] == 'free_discounted'}
          free_services_revenue = free_bills.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00
          paid_bills = s_services.select{|service| service['discount_type'] == 'paid'}
          paid_services_revenue = paid_bills.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00
          discounted_bills = s_services.select{|service| service['discount_type'] == 'discounted' || service['discount_type'] == 'paid_discounted'}
          discounted_services_revenue = discounted_bills.map { |srv| srv['price'].to_f }.reduce(0, :+) || 0.00

          search_fields_hash = { service_name: service_name }

          filter_fields_hash = @filter_fields_hash.merge(service_id: service_id)

          f_mis_revenue_stat = Finance::StatisticService.find_or_create_by(
            receipt_date: @receipt_date, facility_id: @facility_id, user_id: user_id, 
            service_id: service_id, specialty_id: specialty_id,
            sub_specialty_id: sub_specialty_id, department_id: department_id
          )

          f_mis_revenue_stat.organisation_id = @organisation_id
          f_mis_revenue_stat.service_name = service_name
          f_mis_revenue_stat.facility_name = @facility_name
          f_mis_revenue_stat.specialty_name = specialty_name
          f_mis_revenue_stat.has_specialties = @has_specialties
          f_mis_revenue_stat.sub_specialty_name = sub_specialty_name
          f_mis_revenue_stat.has_sub_specialties = @has_sub_specialties
          f_mis_revenue_stat.department_name = department_name
          f_mis_revenue_stat.department_order = department_order
          f_mis_revenue_stat.user_name = user_name
          f_mis_revenue_stat.total_no_of_bills = total_no_of_bills
          f_mis_revenue_stat.total_revenue = total_revenue

          f_mis_revenue_stat.no_of_free_bills = free_bills.count
          f_mis_revenue_stat.free_bills_revenue = free_services_revenue
          f_mis_revenue_stat.no_of_paid_bills = paid_bills.count
          f_mis_revenue_stat.paid_bills_revenue = paid_services_revenue
          f_mis_revenue_stat.no_of_discounted_bills = discounted_bills.count
          f_mis_revenue_stat.discounted_bills_revenue = discounted_services_revenue

          f_mis_revenue_stat.filter_fields = filter_fields_hash
          f_mis_revenue_stat.search_fields = search_fields_hash
          f_mis_revenue_stat.save!
          
        end
      end
      # EOF service_wise_stats
    end
  end
end

# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
